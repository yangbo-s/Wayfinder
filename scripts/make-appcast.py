#!/usr/bin/env python3
"""Create a signed Sparkle feed from the final, already code-signed App ZIP."""
import argparse
from datetime import datetime, timezone
from email.utils import format_datetime
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile
from urllib.parse import quote
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parent.parent
NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", NS)


def run(*args):
    return subprocess.check_output([str(arg) for arg in args], text=True).strip()


def make_appcast(archive, tag, output, previous, account):
    if not re.fullmatch(r"v\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?", tag):
        raise ValueError("Expected a release tag such as v0.1.0-beta.7")
    with zipfile.ZipFile(archive) as package:
        info = plistlib.loads(package.read("Wayfinder.app/Contents/Info.plist"))
        with tempfile.TemporaryDirectory() as temporary:
            binary = Path(temporary) / "Wayfinder"
            binary.write_bytes(package.read("Wayfinder.app/Contents/MacOS/Wayfinder"))
            architectures = set(run("/usr/bin/lipo", "-archs", binary).split())
    if architectures not in ({"arm64"}, {"arm64", "x86_64"}):
        raise ValueError("Feed supports arm64 or universal builds only")
    build = info["CFBundleVersion"]
    if not str(build).isdigit() or int(build) < 1:
        raise ValueError("CFBundleVersion must be a positive integer")
    if info.get("CFBundleIdentifier") != "local.wayfinder.mac":
        raise ValueError("Refusing to publish a development or unrelated app")
    if not tag[1:].split("-")[0] == info["CFBundleShortVersionString"]:
        raise ValueError("Tag and App version differ")
    if not info.get("SURequireSignedFeed") or not info.get("SUVerifyUpdateBeforeExtraction"):
        raise ValueError("App must require feed and pre-extraction signature verification")
    tools = ROOT / ".build/artifacts/sparkle/Sparkle/bin"
    public_key = run(tools / "generate_keys", "--account", account, "-p")
    if info.get("SUPublicEDKey") != public_key:
        raise ValueError("Keychain signing key does not match the App public key")
    run(tools / "sign_update", "--account", account, "--verify", previous)
    tree = ET.parse(previous)
    channel = tree.getroot().find("channel")
    if channel is None:
        raise ValueError("Invalid RSS feed: missing channel")
    for item in channel.findall("item"):
        old = item.findtext(f"{{{NS}}}version")
        if old is None or not old.isdigit() or int(old) >= int(build):
            raise ValueError("New build must be higher than all previously published builds")
    signature = run(tools / "sign_update", "--account", account, "-p", archive)
    run(tools / "sign_update", "--account", account, "--verify", archive, signature)
    item = ET.Element("item")
    ET.SubElement(item, "title").text = "Wayfinder " + tag
    ET.SubElement(item, "pubDate").text = format_datetime(datetime.now(timezone.utc), usegmt=True)
    ET.SubElement(item, f"{{{NS}}}version").text = str(build)
    ET.SubElement(item, f"{{{NS}}}shortVersionString").text = tag.removeprefix("v")
    ET.SubElement(item, f"{{{NS}}}minimumSystemVersion").text = info["LSMinimumSystemVersion"]
    if architectures == {"arm64"}:
        ET.SubElement(item, f"{{{NS}}}hardwareRequirements").text = "arm64"
    ET.SubElement(item, "description").text = "更新内容请查看 GitHub Release：" + tag
    ET.SubElement(item, "link").text = "https://github.com/yangbo-s/Wayfinder/releases/tag/" + tag
    ET.SubElement(item, "enclosure", {
        "url": f"https://github.com/yangbo-s/Wayfinder/releases/download/{tag}/{quote(archive.name, safe='')}",
        "length": str(archive.stat().st_size), "type": "application/octet-stream",
        f"{{{NS}}}edSignature": signature,
    })
    channel.insert(0, item)
    ET.indent(tree, space="  ")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=output.parent) as temporary:
        staged = Path(temporary) / "appcast.xml"
        tree.write(staged, encoding="utf-8", xml_declaration=True)
        run(tools / "sign_update", "--account", account, staged)
        run(tools / "sign_update", "--account", account, "--verify", staged)
        os.replace(staged, output)
    print(f"Signed build {build}: {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("tag")
    parser.add_argument("--output", type=Path, default=ROOT / "dist/appcast.xml")
    parser.add_argument("--previous", type=Path, default=ROOT / "updates/appcast.xml")
    parser.add_argument("--account", default=os.environ.get("SPARKLE_ACCOUNT", "local.wayfinder.mac"))
    args = parser.parse_args()
    make_appcast(args.archive.resolve(), args.tag, args.output.resolve(), args.previous, args.account)
