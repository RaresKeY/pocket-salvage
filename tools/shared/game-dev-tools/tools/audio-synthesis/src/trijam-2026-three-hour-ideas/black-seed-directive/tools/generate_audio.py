#!/usr/bin/env python3
"""Generate the game's deterministic code-synthesized ambient loops."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

from audio_profile import ROOT, profile, output_path, destination, select_output
CONFIG = profile('black-seed-audio')
RATE = int(CONFIG.get('rate', 22050))
DURATION = float(CONFIG.get('duration', 12))
TAU = math.tau
OUTPUT = output_path('black-seed-audio')


def tone(frequency: float, time: float, phase: float = 0.0) -> float:
    return math.sin(TAU * frequency * time + phase)


def periodic_pulse(time: float, beats: float, width: float = 0.12) -> float:
    phase = (time * beats / DURATION) % 1.0
    distance = min(phase, 1.0 - phase)
    return math.exp(-distance / width)


def act_1(time: float, _noise: float) -> float:
    drift = 0.58 + 0.42 * math.sin(TAU * time / DURATION)
    return 0.34 * tone(55.0, time) + 0.17 * tone(82.5, time, drift) + 0.06 * tone(220.0, time) * periodic_pulse(time, 3, 0.045)


def combat(time: float, noise: float) -> float:
    beat = periodic_pulse(time, 24, 0.055)
    warning = periodic_pulse(time + 0.25, 6, 0.035)
    return 0.24 * tone(48.0, time) + 0.18 * tone(96.0, time) * beat + 0.10 * noise * beat + 0.08 * tone(384.0, time) * warning


def act_2(time: float, noise: float) -> float:
    radio = 0.5 + 0.5 * math.sin(TAU * 8.0 * time / DURATION)
    beacon = periodic_pulse(time, 5, 0.03)
    return 0.25 * tone(65.0, time) + 0.14 * tone(97.5, time) * radio + 0.055 * noise * radio + 0.09 * tone(520.0, time) * beacon


def act_3(time: float, _noise: float) -> float:
    opening = 0.62 + 0.38 * math.sin(TAU * time / DURATION - math.pi / 2.0)
    control = periodic_pulse(time, 4, 0.07)
    return 0.23 * tone(73.5, time) + 0.15 * tone(110.0, time) * opening + 0.10 * tone(147.0, time) + 0.07 * tone(294.0, time) * control


def write_loop(name: str, generator, seed: int) -> None:
    rng = random.Random(seed)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    path = destination(OUTPUT / f"{name}.wav", "black-seed-audio")
    frames = bytearray()
    smoothing = 0.0
    for index in range(int(RATE * DURATION)):
        time = index / RATE
        smoothing = smoothing * 0.94 + rng.uniform(-1.0, 1.0) * 0.06
        sample = generator(time, smoothing)
        sample = math.tanh(sample * 1.35) * 0.55
        frames.extend(struct.pack("<h", int(max(-1.0, min(1.0, sample)) * 32767)))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(frames)


def main() -> None:
    global OUTPUT
    OUTPUT = select_output('black-seed-audio', OUTPUT)
    generators = {'act_1': act_1, 'combat': combat, 'act_2': act_2, 'act_3': act_3}
    for job in CONFIG.get('loops', []):
        name, generator, seed = str(job['name']), generators[str(job['kernel'])], int(job['seed'])
        write_loop(name, generator, seed)
        print(f"generated {name}.wav")


if __name__ == "__main__":
    main()
