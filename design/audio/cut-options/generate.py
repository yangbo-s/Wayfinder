#!/usr/bin/env python3
"""Original procedural UI sounds. Standard library only; no sampled recordings.

Run in place to regenerate all WAVs, the audition sequence, and metrics.
Licensed under the repository's MIT license, like the generated audio.
"""
from pathlib import Path
import json
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parent
RATE = 48000


def noise(duration, seed, low, high):
    rng = random.Random(seed)
    bottom = top = 0.0
    a = 1 - math.exp(-2 * math.pi * low / RATE)
    b = 1 - math.exp(-2 * math.pi * high / RATE)
    result = []
    for _ in range(round(duration * RATE)):
        top += b * (rng.uniform(-1, 1) - top)
        bottom += a * (top - bottom)
        result.append(top - bottom)
    return result


def pulse(t, start, attack, decay):
    t -= start
    return 0 if t < 0 else (1 - math.exp(-t / attack)) * math.exp(-t / decay)


def finish(samples, target_rms):
    # Remove DC, fade both ends, and leave at least 3 dB of peak headroom.
    mean = sum(samples) / len(samples)
    samples = [(s - mean) * min(i / 96, (len(samples) - 1 - i) / 240, 1)
               for i, s in enumerate(samples)]
    rms = math.sqrt(sum(s * s for s in samples) / len(samples))
    scale = min(target_rms / rms, 0.70 / max(abs(s) for s in samples))
    return [s * scale for s in samples]


def metallic_snip():
    texture = noise(0.155, 7101, 1350, 9500)
    output = []
    for i, n in enumerate(texture):
        t = i / RATE
        blade = pulse(t, 0.003, 0.0015, 0.017)
        closure = pulse(t, 0.023, 0.0007, 0.009)
        metal = sum(math.sin(2 * math.pi * f * t) for f in (3170, 5290, 7630)) / 3
        output.append(n * (blade + 0.9 * closure) + 0.055 * metal * blade)
    return finish(output, 0.075)


def paper_cut():
    texture = noise(0.215, 7102, 700, 7200)
    output = []
    for i, n in enumerate(texture):
        t = i / RATE
        fibers = 0.70 + 0.17 * math.sin(2 * math.pi * 173 * t) + 0.13 * math.sin(2 * math.pi * 283 * t)
        scrape = pulse(t, 0.004, 0.009, 0.033)
        end = pulse(t, 0.044, 0.001, 0.012)
        output.append(n * fibers * (scrape + 0.45 * end))
    return finish(output, 0.080)


def soft_swipe():
    texture = noise(0.170, 7103, 950, 3800)
    output = []
    for i, n in enumerate(texture):
        t = i / RATE
        sweep = pulse(t, 0.003, 0.010, 0.025)
        output.append(n * sweep)
    return finish(output, 0.065)


def double_tick():
    texture = noise(0.125, 7104, 1200, 7500)
    output = []
    for i, n in enumerate(texture):
        t = i / RATE
        first = 0.60 * pulse(t, 0.003, 0.0006, 0.004)
        second = pulse(t, 0.031, 0.0006, 0.006)
        output.append(n * (first + second))
    return finish(output, 0.070)


def original_snip():
    # Preserve the very first 105 ms preview exactly, including its quieter mix.
    rng = random.Random(2701)
    previous = low = 0.0
    samples = []
    for i in range(int(RATE * 0.105)):
        t = i / RATE
        low += 0.53 * (rng.uniform(-1, 1) - low)
        high = low - previous
        previous += 0.065 * (low - previous)
        envelope = min(t / 0.0015, 1) * math.exp(-t / 0.021) * min((0.105 - t) / 0.008, 1)
        snap = math.sin(2 * math.pi * (1800 * t - 4500 * t * t)) * math.exp(-t / 0.0028)
        samples.append(0.43 * envelope * high + 0.08 * snap)
    return samples


def write(name, samples):
    pcm = [round(s * 32767) for s in samples]
    assert pcm[0] == pcm[-1] == 0
    assert 0 < max(abs(s) for s in pcm) < 32767
    with wave.open(str(ROOT / name), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))
    return {
        "file": name,
        "duration_seconds": len(samples) / RATE,
        "peak_dbfs": round(20 * math.log10(max(abs(s) for s in samples)), 2),
        "rms_dbfs": round(20 * math.log10(math.sqrt(sum(s * s for s in samples) / len(samples))), 2),
    }


if __name__ == "__main__":
    options = [
        ("E-original-snip.wav", original_snip()),
        ("A-metallic-snip.wav", metallic_snip()),
        ("B-paper-cut.wav", paper_cut()),
        ("C-soft-swipe.wav", soft_swipe()),
        ("D-double-tick.wav", double_tick()),
    ]
    metrics = [write(name, samples) for name, samples in options]
    # Original, A, B, C, D, then repeat. One second between sounds.
    audition = [0.0] * round(RATE * 0.3)
    for _, samples in options * 2:
        audition += samples + [0.0] * RATE
    write("compare-five.wav", audition)
    (ROOT / "metrics.json").write_text(json.dumps(metrics, indent=2) + "\n")
    print(json.dumps(metrics, indent=2))
