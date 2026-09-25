"""Synthesise the salvage round's retro sound effects into assets/audio/ as 16-bit mono WAVs.

Deterministic (fixed seed), standard library only. Rerun after changing a recipe:
    python3 tools/audio/make_sfx.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio"


def tone(freq, t, shape="square"):
    phase = (freq * t) % 1.0
    if shape == "square":
        return 1.0 if phase < 0.5 else -1.0
    if shape == "triangle":
        return 4.0 * abs(phase - 0.5) - 1.0
    if shape == "saw":
        return 2.0 * phase - 1.0
    return math.sin(2 * math.pi * phase)


def render(seconds, sample):
    """sample(t, progress, noise) -> float in [-1, 1]."""
    rng = random.Random(7)
    count = int(RATE * seconds)
    return [sample(i / RATE, i / count, rng.uniform(-1, 1)) for i in range(count)]


def envelope(progress, attack=0.02, decay_power=1.5):
    if progress < attack:
        return progress / attack
    return (1.0 - (progress - attack) / (1.0 - attack)) ** decay_power


def sweep(start, end, progress):
    return start * (end / start) ** progress


RECIPES = {
    "ui_click": (0.09, lambda t, p, n: 0.3 * envelope(p, 0.03, 2.5) * (tone(740, t, "sine") * 0.8 + n * 0.12)),
    "magnet_on": (0.35, lambda t, p, n: 0.35 * envelope(p, 0.05, 1.0) * (tone(sweep(90, 260, p), t, "saw") * 0.7 + tone(sweep(180, 520, p), t) * 0.3)),
    "magnet_off": (0.25, lambda t, p, n: 0.3 * envelope(p, 0.01, 2.0) * tone(sweep(240, 70, p), t, "saw")),
    "pickup": (0.18, lambda t, p, n: 0.5 * envelope(p, 0.005, 3.0) * (tone(sweep(160, 90, p), t, "square") * 0.6 + n * 0.4)),
    "land": (0.22, lambda t, p, n: 0.55 * envelope(p, 0.002, 4.0) * (n * 0.7 + tone(sweep(90, 40, p), t, "sine") * 0.6)),
    "correct": (0.45, lambda t, p, n: 0.3 * envelope(p, 0.01, 1.2) * tone([660, 880, 1320][min(2, int(p * 3.2))], t, "square")),
    "wrong": (0.4, lambda t, p, n: 0.3 * envelope(p, 0.01, 0.8) * tone(110 if p < 0.5 else 92, t, "saw")),
    "eject": (0.35, lambda t, p, n: 0.3 * envelope(p, 0.01, 1.2) * tone(sweep(180, 720, p), t, "triangle")),
    "tick": (0.07, lambda t, p, n: 0.3 * envelope(p, 0.005, 2.0) * tone(1500, t, "square")),
    "finish": (0.9, lambda t, p, n: 0.28 * envelope(p, 0.01, 1.0) * tone([523, 659, 784, 1047][min(3, int(p * 4.5))], t, "square")),
    "claw_shut": (0.16, lambda t, p, n: 0.45 * envelope(p, 0.003, 3.0) * (tone(sweep(900, 500, p), t, "square") * 0.5 + n * 0.5)),
    "claw_open": (0.18, lambda t, p, n: 0.3 * envelope(p, 0.01, 2.0) * (tone(sweep(400, 700, p), t, "triangle") * 0.6 + n * 0.3)),
    "clank": (0.4, lambda t, p, n: 0.4 * envelope(p, 0.002, 2.5) * (n * 0.35 + tone(610, t, "square") * 0.3 + tone(1340, t, "sine") * 0.35)),
    "start": (0.3, lambda t, p, n: 0.28 * envelope(p, 0.01, 1.0) * tone(440 if p < 0.45 else 880, t, "square")),
}


## Integer-Hz oscillators repeat each second; smooth the boundary for the noise layer too.
LOOPS = {
    "trolley_loop": lambda t, p, n: 0.32 * (tone(55, t, "saw") * 0.5 + tone(110, t, "square") * 0.2 + n * 0.25 * (0.5 + 0.5 * tone(12, t, "sine"))),
    "winch_loop": lambda t, p, n: 0.22 * (tone(220, t, "saw") * 0.45 + tone(330, t, "triangle") * 0.35 + tone(6, t, "sine") * tone(440, t, "sine") * 0.2),
}


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(frames)


def loop_samples(sample):
    samples = render(1.0, sample)
    overlap = int(RATE * 0.02)
    # Preserve a one-second loop; endpoints meet at a common midpoint.
    midpoint = (samples[0] + samples[-1]) * 0.5
    first, last = samples[0], samples[-1]
    # Taper boundary correction without fading the motor to silence.
    for i in range(overlap):
        weight = (1.0 - i / overlap) ** 2
        samples[i] += (midpoint - first) * weight
        samples[-1 - i] += (midpoint - last) * weight
    return samples


if __name__ == "__main__":
    for name, (seconds, sample) in RECIPES.items():
        write(name, render(seconds, sample))
    for name, sample in LOOPS.items():
        write(name, loop_samples(sample))
    print(f"wrote {len(RECIPES) + len(LOOPS)} sounds to {OUT}")
