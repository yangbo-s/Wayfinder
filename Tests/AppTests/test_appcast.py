"""Release tests: run explicitly on the signing Mac after creating the final ZIP.

python3 Tests/AppTests/test_appcast.py <Wayfinder.zip>
The private key remains in Keychain; generated artifacts stay in temporary storage.
"""
import importlib.util
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[2]
ARCHIVE = Path(sys.argv.pop(1)).resolve()
spec = importlib.util.spec_from_file_location("appcast", ROOT / "scripts/make-appcast.py")
appcast = importlib.util.module_from_spec(spec)
spec.loader.exec_module(appcast)
SIGN = ROOT / ".build/artifacts/sparkle/Sparkle/bin/sign_update"
ACCOUNT = "local.wayfinder.mac"


class AppcastTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixture = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.fixture.cleanup)
        cls.base_feed = Path(cls.fixture.name) / "base.xml"
        cls.base_feed.write_text('<rss version="2.0"><channel><title>Wayfinder tests</title></channel></rss>')
        subprocess.run([str(SIGN), "--account", ACCOUNT, str(cls.base_feed)], check=True, capture_output=True)

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.output = self.directory / "appcast.xml"

    def make(self, archive=ARCHIVE, previous=None, tag="v0.1.0-beta.7"):
        appcast.make_appcast(archive, tag, self.output, previous or self.base_feed, ACCOUNT)

    def modified_archive(self, **changes):
        path = self.directory / "modified.zip"
        with zipfile.ZipFile(ARCHIVE) as original, zipfile.ZipFile(path, "w") as out:
            for name in ("Wayfinder.app/Contents/Info.plist", "Wayfinder.app/Contents/MacOS/Wayfinder"):
                data = original.read(name)
                if name.endswith("Info.plist"):
                    info = plistlib.loads(data)
                    info.update(changes)
                    data = plistlib.dumps(info)
                out.writestr(name, data)
        return path

    def verify(self, path, signature=None):
        return subprocess.run([str(SIGN), "--account", ACCOUNT, "--verify", str(path)] +
                              ([signature] if signature else []), capture_output=True).returncode

    def test_signed_archive_feed_and_tampering(self):
        self.make()
        self.assertEqual(self.verify(self.output), 0)
        item = ET.parse(self.output).find("channel/item")
        self.assertEqual(item.findtext(f"{{{appcast.NS}}}hardwareRequirements"), "arm64")
        signature = item.find("enclosure").get(f"{{{appcast.NS}}}edSignature")
        self.assertEqual(self.verify(ARCHIVE, signature), 0)
        changed = self.directory / "tampered.zip"
        changed.write_bytes(ARCHIVE.read_bytes() + b"tampered")
        self.assertNotEqual(self.verify(changed, signature), 0)
        self.output.write_bytes(self.output.read_bytes().replace(b"Wayfinder", b"Wayfindex", 1))
        self.assertNotEqual(self.verify(self.output), 0)

    def test_rejects_development_bundle(self):
        with self.assertRaisesRegex(ValueError, "development"):
            self.make(self.modified_archive(CFBundleIdentifier="local.wayfinder.preview.sparkle"))

    def test_rejects_wrong_key(self):
        with self.assertRaisesRegex(ValueError, "public key"):
            self.make(self.modified_archive(SUPublicEDKey="wrong-key"))

    def test_rejects_tag_version_mismatch(self):
        with self.assertRaisesRegex(ValueError, "version differ"):
            self.make(tag="v9.0.0")

    def test_rejects_unsigned_configuration(self):
        with self.assertRaisesRegex(ValueError, "verification"):
            self.make(self.modified_archive(SURequireSignedFeed=False))

    def test_rejects_duplicate_version_without_overwriting_output(self):
        self.make()
        original = self.output.read_bytes()
        with self.assertRaisesRegex(ValueError, "higher"):
            self.make(previous=self.output)
        self.assertEqual(self.output.read_bytes(), original)

    def test_rejects_tampered_previous_feed(self):
        bad = self.directory / "bad.xml"
        bad.write_bytes(self.base_feed.read_bytes().replace(b"Wayfinder", b"Wayfindex", 1))
        with self.assertRaises(subprocess.CalledProcessError):
            self.make(previous=bad)
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
