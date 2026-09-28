#!/usr/bin/env python3
"""Build deterministic original PCM assets for Ordinary Impossible."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


from audio_profile import ROOT, profile, output_path, destination, select_output
CONFIG = profile('ordinary-audio')
RATE = int(CONFIG.get('rate', 22050))
OUT = output_path('ordinary-audio')
TAU = math.tau


def midi(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def triangle(phase: float) -> float:
    return 2.0 * abs(2.0 * ((phase / TAU) % 1.0) - 1.0) - 1.0


def envelope(local: float, duration: float, attack: float = 0.025, release: float = 0.22) -> float:
    return min(1.0, local / attack, max(0.0, (duration - local) / release))


def write_wave(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(0.001, max(abs(value) for value in samples))
    gain = min(0.94 / peak, 1.0)
    payload = bytearray()
    for value in samples:
        payload.extend(struct.pack("<h", int(max(-1.0, min(1.0, value * gain)) * 32767.0)))
    with wave.open(str(destination(OUT / name, "ordinary-audio")), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(payload)


def score(stage: int, duration: float = 30.0) -> list[float]:
    randomizer = random.Random(int(CONFIG.get("score_seed", 4100)) + stage)
    count = int(duration * RATE)
    result = [0.0] * count
    tempos = CONFIG['tempos']
    beat = 60.0 / tempos[stage]
    roots = CONFIG['roots']
    patterns = CONFIG['patterns'][stage]
    note_length = beat * (0.92 if stage != 1 else 0.46)
    step = beat if stage != 1 else beat * 0.5
    for note_index in range(int(duration / step) + 1):
        start = note_index * step
        degree = patterns[note_index % len(patterns)]
        octave = 12 if note_index % 8 in (3, 6) else 0
        frequency = midi(roots[stage] + degree + octave)
        start_sample = int(start * RATE)
        end_sample = min(count, int((start + note_length) * RATE))
        for sample_index in range(start_sample, end_sample):
            local = sample_index / RATE - start
            env = envelope(local, note_length, 0.018, note_length * 0.42)
            phase = TAU * frequency * local
            if stage == 0:
                voice = math.sin(phase) + 0.31 * math.sin(phase * 2.01) + 0.12 * math.sin(phase * 3.99)
            elif stage == 1:
                voice = 0.72 * triangle(phase) + 0.38 * math.sin(phase * 0.5)
            else:
                voice = math.sin(phase) + 0.33 * math.sin(TAU * (frequency * 1.008) * local)
            result[sample_index] += voice * env * (0.105 if stage != 1 else 0.08)
    # Low circular bass roots and intentionally sparse tactile percussion.
    for beat_index in range(int(duration / beat) + 1):
        start = beat_index * beat
        bass_frequency = midi(roots[stage] - 12 + ([0, 0, 5, 7][beat_index % 4]))
        for offset in range(min(int(beat * RATE), count - int(start * RATE))):
            local = offset / RATE
            env = envelope(local, beat, 0.04, beat * 0.7)
            result[int(start * RATE) + offset] += math.sin(TAU * bass_frequency * local) * env * 0.09
        if beat_index % (3 if stage == 0 else 2) == 0:
            hit_length = 0.12 if stage != 2 else 0.19
            for offset in range(min(int(hit_length * RATE), count - int(start * RATE))):
                local = offset / RATE
                noise = randomizer.uniform(-1.0, 1.0)
                tone = math.sin(TAU * (88.0 if stage == 2 else 156.0) * local)
                result[int(start * RATE) + offset] += (noise * 0.035 + tone * 0.05) * math.exp(-local * 18.0)
    # Soft room bed plus a loop breath; no hard musical cadence.
    for sample_index in range(count):
        time = sample_index / RATE
        room = math.sin(TAU * (41.0 + stage * 7.0) * time) * 0.012
        shimmer = math.sin(TAU * (523.25 + stage * 29.0) * time) * (0.004 + 0.003 * math.sin(TAU * time / 7.5))
        loop_fade = min(1.0, time / 0.12, (duration - time) / 0.12)
        result[sample_index] = (result[sample_index] + room + shimmer) * max(0.0, loop_fade)
    return result


def ambience(stage: int, duration: float = 12.0) -> list[float]:
    randomizer = random.Random(int(CONFIG.get("ambience_seed", 8200)) + stage)
    result: list[float] = []
    filtered = 0.0
    for sample_index in range(int(duration * RATE)):
        time = sample_index / RATE
        filtered = filtered * 0.992 + randomizer.uniform(-1.0, 1.0) * 0.008
        base = filtered * (0.16 if stage == 1 else 0.11)
        rope = math.sin(TAU * (0.19 + stage * 0.07) * time) * math.sin(TAU * (72 + stage * 18) * time) * 0.026
        pulse = math.sin(TAU * (1.4 if stage == 1 else 0.63) * time) ** 9 * 0.018
        fade = min(1.0, time / 0.2, (duration - time) / 0.2)
        result.append((base + rope + pulse) * max(0.0, fade))
    return result


def effect(kind: str) -> list[float]:
    recipes = CONFIG.get('effects', {})
    duration, start_frequency, end_frequency = recipes[kind]
    randomizer = random.Random(sum(ord(character) for character in kind))
    result: list[float] = []
    for sample_index in range(int(duration * RATE)):
        time = sample_index / RATE
        ratio = time / duration
        frequency = start_frequency + (end_frequency - start_frequency) * ratio
        env = math.sin(math.pi * ratio) ** 1.3
        tone = math.sin(TAU * frequency * time) * 0.25
        wood = randomizer.uniform(-1.0, 1.0) * math.exp(-time * 18.0) * 0.08
        result.append((tone + wood) * env)
    return result


def main() -> None:
    global OUT
    OUT = select_output('ordinary-audio', OUT)
    for stage in range(len(CONFIG['tempos'])):
        write_wave(f"stage_{stage + 1}_score.wav", score(stage, float(CONFIG.get('score_seconds', 30))))
        write_wave(f"stage_{stage + 1}_ambience.wav", ambience(stage, float(CONFIG.get('ambience_seconds', 12))))
    for name in CONFIG.get('effects', {}):
        write_wave(f"{name}.wav", effect(name))
    print(f"ORDINARY_AUDIO_BUILT={2 * len(CONFIG['tempos']) + len(CONFIG.get('effects', {}))}")


if __name__ == "__main__":
    main()
