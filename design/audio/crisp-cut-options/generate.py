#!/usr/bin/env python3
"""Original, dry UI impacts; no recordings or sustained noise layers.

Synthesized from short contact pulses and heavily damped resonances.
Code and generated audio are covered by the accompanying MIT license.
"""
from pathlib import Path
import json
import math
import struct
import wave

ROOT = Path(__file__).resolve().parent
RATE = 48000


def impact(t, start, modes, contact=0.18):
    age = t - start
    if age < 0:
        return 0.0
    # A short bipolar contact pulse gives the attack definition, without a hiss bed.
    x = (age - 0.00055) / 0.00018
    strike = contact * (1 - x * x) * math.exp(-0.5 * x * x)
    attack = 1 - math.exp(-age / 0.00017)
    resonances = sum(gain * math.sin(2 * math.pi * frequency * age)
                     * math.exp(-age / decay)
                     for frequency, decay, gain in modes)
    return strike + attack * resonances


def render(duration, contacts):
    samples = []
    for i in range(round(duration * RATE)):
        t = i / RATE
        samples.append(sum(gain * impact(t, start, modes, contact)
                           for start, gain, modes, contact in contacts))
    # Remove DC via a one-pole high-pass and fade only the inaudible endpoints.
    previous = filtered = 0.0
    coefficient = math.exp(-2 * math.pi * 90 / RATE)
    for i, value in enumerate(samples):
        filtered = coefficient * (filtered + value - previous)
        previous = value
        samples[i] = filtered * min(i / 24, (len(samples) - 1 - i) / 96, 1)
    # Similar perceived body level, with at least 4.4 dB of peak headroom.
    peak = max(abs(s) for s in samples)
    active = [s for s in samples if abs(s) >= peak * 0.04]
    active_rms = math.sqrt(sum(s * s for s in active) / len(active))
    scale = min(0.20 / active_rms, 0.60 / peak)
    return [s * scale for s in samples]


def write(name, samples):
    pcm = [round(s * 32767) for s in samples]
    assert pcm[0] == pcm[-1] == 0
    assert 0 < max(abs(s) for s in pcm) <= round(32767 * 0.60)
    with wave.open(str(ROOT / name), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))
    energy = [s * s for s in samples]
    total = sum(energy)
    cumulative = 0.0
    for i, value in enumerate(energy):
        cumulative += value
        if cumulative >= total * 0.99:
            energy_end = (i + 1) / RATE
            break
    return {
        "file": name,
        "duration_seconds": len(samples) / RATE,
        "peak_dbfs": round(20 * math.log10(max(abs(s) for s in samples)), 2),
        "energy_99_percent_end_ms": round(energy_end * 1000, 2),
        "noise_layer": False,
    }


def previews(options, comparison_name):
    for label, samples in options:
        preview = [0.0] * round(RATE * 0.25)
        for _ in range(3):
            preview += samples + [0.0] * round(RATE * 0.65)
        write("preview-" + label, preview)
    compare = [0.0] * round(RATE * 0.25)
    for _, samples in options * 2:
        compare += samples + [0.0] * RATE
    write(comparison_name, compare)


if __name__ == "__main__":
    single = [(2050, 0.0023, 0.85), (3470, 0.0017, 0.53), (5810, 0.0009, 0.25)]
    tick = [(2450, 0.0015, 0.78), (4130, 0.0011, 0.48), (6790, 0.0007, 0.19)]
    tock = [(1730, 0.0020, 0.84), (3190, 0.0015, 0.51), (5270, 0.0009, 0.24)]
    latch = [(1190, 0.0027, 0.68), (2370, 0.0018, 0.73), (3920, 0.0011, 0.38)]
    stop = [(1910, 0.0013, 0.65), (3710, 0.0008, 0.38)]
    options = [
        ("F-clean-click.wav", render(0.075, [(0.004, 1.0, single, 0.24)])),
        ("G-tight-double.wav", render(0.105, [
            (0.004, 0.65, tick, 0.22), (0.030, 1.0, tock, 0.22)])),
        ("H-mechanical-snap.wav", render(0.085, [
            (0.004, 1.0, latch, 0.29), (0.011, 0.28, stop, 0.20)])),
    ]
    # Keep F/G/H above byte-identical; the new pairs vary spacing, weight and body.
    bright_tick = [(2870, 0.0013, 0.77), (4670, 0.0009, 0.42), (7130, 0.0006, 0.17)]
    firm_tock = [(1540, 0.0021, 0.87), (2910, 0.0014, 0.54), (5030, 0.0008, 0.23)]
    small_latch = [(1840, 0.0018, 0.65), (3210, 0.0012, 0.60), (5190, 0.0008, 0.29)]
    deep_latch = [(870, 0.0025, 0.53), (1730, 0.0021, 0.75),
                  (3070, 0.0014, 0.50), (4930, 0.0008, 0.27)]
    new_options = [
        ("I-fast-light-heavy.wav", render(0.095, [
            (0.004, 0.40, bright_tick, 0.19), (0.021, 1.0, tock, 0.25)])),
        ("J-spaced-light-heavy.wav", render(0.125, [
            (0.004, 0.48, tick, 0.20), (0.050, 1.0, firm_tock, 0.24)])),
        ("K-tight-mechanical-pair.wav", render(0.110, [
            (0.004, 0.43, small_latch, 0.20),
            (0.031, 1.0, latch, 0.29), (0.038, 0.28, stop, 0.20)])),
        ("L-deep-mechanical-pair.wav", render(0.135, [
            (0.004, 0.45, small_latch, 0.19),
            (0.050, 1.0, deep_latch, 0.31), (0.057, 0.24, stop, 0.18)])),
    ]
    # Keep K's mechanical timbre and weight; bring the two main contacts closer.
    close_options = [
        ("M-close-mechanical-pair.wav", render(0.090, [
            (0.004, 0.43, small_latch, 0.20),
            (0.017, 1.0, latch, 0.29), (0.024, 0.28, stop, 0.20)])),
    ]
    medium_options = [
        ("N-20ms-mechanical-pair.wav", render(0.100, [
            (0.004, 0.43, small_latch, 0.20),
            (0.024, 1.0, latch, 0.29), (0.031, 0.28, stop, 0.20)])),
    ]
    metrics = [write(name, samples) for name, samples in
               options + new_options + close_options + medium_options]
    previews(options, "compare-F-G-H.wav")
    previews(new_options, "compare-I-J-K-L.wav")
    previews(close_options, "compare-M.wav")
    previews(medium_options, "compare-N.wav")
    (ROOT / "metrics.json").write_text(json.dumps(metrics, indent=2) + "\n")
    print(json.dumps(metrics, indent=2))
