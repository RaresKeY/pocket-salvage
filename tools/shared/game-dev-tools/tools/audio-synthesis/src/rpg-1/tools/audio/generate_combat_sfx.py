#!/usr/bin/env python3
"""Generate the deterministic Signal-Gouache combat SFX set."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import struct
import wave
from dataclasses import dataclass
from pathlib import Path


from audio_profile import ROOT, profile, output_path, project_path, require_program
CONFIG = profile('rpg-combat')
SAMPLE_RATE = int(CONFIG.get('rate', 48000))
SAMPLE_WIDTH = 2
CHANNELS = 1
GENERATOR_VERSION = 2


@dataclass(frozen=True)
class Cue:
    cue_id: str
    duration: float
    seed: int
    function: str
    target_peak: float
    materials: tuple[str, ...]


CUES = tuple(Cue(**{**value, 'materials': tuple(value['materials'])}) for value in CONFIG.get('cues', []))


def _noise_buffer(rng: random.Random, sample_count: int) -> list[float]:
    return [rng.uniform(-1.0, 1.0) for _ in range(sample_count)]


def _lowpass(values: list[float], cutoff_hz: float) -> list[float]:
    coefficient = 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / SAMPLE_RATE)
    state = 0.0
    filtered: list[float] = []
    for value in values:
        state += coefficient * (value - state)
        filtered.append(state)
    return filtered


def _highpass(values: list[float], cutoff_hz: float) -> list[float]:
    low = _lowpass(values, cutoff_hz)
    return [value - low_value for value, low_value in zip(values, low)]


def _bandpass(
    values: list[float],
    low_hz: float,
    high_hz: float,
) -> list[float]:
    return _lowpass(_highpass(values, low_hz), high_hz)


def _burst(
    t: float,
    start: float,
    decay_rate: float,
    attack_seconds: float = 0.0015,
) -> float:
    elapsed = t - start
    if elapsed < 0.0:
        return 0.0
    attack = min(1.0, elapsed / max(attack_seconds, 1e-6))
    return attack * math.exp(-decay_rate * elapsed)


def _motion_window(
    t: float,
    start: float,
    end: float,
    attack_seconds: float,
    release_seconds: float,
) -> float:
    if t < start or t >= end:
        return 0.0
    attack = min(1.0, (t - start) / max(attack_seconds, 1e-6))
    release = min(1.0, (end - t) / max(release_seconds, 1e-6))
    return math.sin(math.pi * 0.5 * min(attack, release)) ** 2


def _resonance(
    t: float,
    start: float,
    frequency: float,
    decay_rate: float,
    phase: float = 0.0,
) -> float:
    elapsed = t - start
    if elapsed < 0.0:
        return 0.0
    return math.sin(2.0 * math.pi * frequency * elapsed + phase) * math.exp(
        -decay_rate * elapsed
    )


def _cue_sample(
    cue_id: str,
    t: float,
    low_noise: float,
    mid_noise: float,
    high_noise: float,
) -> float:
    if cue_id == "target_mark":
        first = _burst(t, 0.004, 72.0)
        second = _burst(t, 0.067, 86.0)
        contact = high_noise * (0.42 * first + 0.30 * second)
        body = mid_noise * (0.20 * first + 0.14 * second)
        muted_metal = (
            0.10 * _resonance(t, 0.004, 612.0, 54.0)
            + 0.06 * _resonance(t, 0.004, 947.0, 72.0)
            + 0.07 * _resonance(t, 0.067, 574.0, 68.0)
        )
        return contact + body + muted_metal
    if cue_id == "card_play":
        paper = _motion_window(t, 0.003, 0.118, 0.008, 0.045)
        clip = _burst(t, 0.082, 34.0, 0.002)
        paper_body = 0.55 * mid_noise * paper + 0.18 * high_noise * paper
        copper = clip * (
            0.14 * _resonance(t, 0.082, 354.0, 27.0)
            + 0.08 * _resonance(t, 0.082, 619.0, 41.0)
        )
        return paper_body + 0.20 * high_noise * clip + copper
    if cue_id == "attack_whoosh":
        air = _motion_window(t, 0.008, 0.238, 0.070, 0.050)
        edge = _motion_window(t, 0.055, 0.222, 0.055, 0.038)
        wire = _motion_window(t, 0.032, 0.205, 0.060, 0.060)
        return (
            0.62 * mid_noise * air
            + 0.19 * high_noise * edge
            + 0.08 * _resonance(t, 0.032, 173.0, 10.0) * wire
        )
    if cue_id == "hit_impact":
        strike = _burst(t, 0.003, 34.0, 0.0025)
        grit = _burst(t, 0.006, 61.0, 0.001)
        body = (
            0.42 * _resonance(t, 0.003, 103.0, 21.0)
            + 0.20 * _resonance(t, 0.003, 157.0, 30.0, 0.4)
        )
        return (
            0.60 * low_noise * strike
            + 0.22 * mid_noise * strike
            + 0.15 * high_noise * grit
            + body
        )
    if cue_id == "block_guard":
        strike = _burst(t, 0.004, 43.0, 0.0015)
        plate = (
            0.28 * _resonance(t, 0.004, 407.0, 22.0)
            + 0.15 * _resonance(t, 0.004, 683.0, 31.0, 0.2)
            + 0.07 * _resonance(t, 0.004, 1031.0, 46.0, 0.5)
        )
        damp = _motion_window(t, 0.018, 0.148, 0.018, 0.065)
        return (
            0.38 * mid_noise * strike
            + 0.18 * high_noise * strike
            + plate
            + 0.08 * low_noise * damp
        )
    if cue_id == "defeat_break":
        first = _burst(t, 0.004, 31.0, 0.002)
        second = _burst(t, 0.088, 39.0, 0.002)
        third = _burst(t, 0.176, 48.0, 0.002)
        contacts = first + 0.72 * second + 0.48 * third
        loose_parts = _motion_window(t, 0.030, 0.345, 0.040, 0.105)
        bodies = (
            0.20 * _resonance(t, 0.004, 181.0, 18.0)
            + 0.12 * _resonance(t, 0.088, 227.0, 25.0, 0.3)
            + 0.07 * _resonance(t, 0.176, 313.0, 34.0, 0.5)
        )
        return (
            0.32 * mid_noise * contacts
            + 0.14 * high_noise * contacts
            + 0.16 * low_noise * loose_parts
            + bodies
        )
    if cue_id == "turn_commit":
        switch = _burst(t, 0.004, 48.0, 0.002)
        latch = _burst(t, 0.068, 69.0, 0.0015)
        return (
            0.36 * low_noise * switch
            + 0.22 * mid_noise * switch
            + 0.30 * high_noise * latch
            + 0.13 * _resonance(t, 0.004, 143.0, 33.0)
            + 0.08 * _resonance(t, 0.068, 526.0, 57.0)
        )
    raise ValueError(f"unknown cue: {cue_id}")


def _render(cue: Cue) -> list[float]:
    rng = random.Random(cue.seed)
    sample_count = round(cue.duration * SAMPLE_RATE)
    low_noise = _lowpass(_noise_buffer(rng, sample_count), 310.0)
    mid_noise = _bandpass(_noise_buffer(rng, sample_count), 260.0, 2600.0)
    high_noise = _bandpass(_noise_buffer(rng, sample_count), 1200.0, 6200.0)
    values = [
        _cue_sample(
            CONFIG.get('kernels', {}).get(cue.cue_id, cue.cue_id),
            index / SAMPLE_RATE,
            low_noise[index],
            mid_noise[index],
            high_noise[index],
        )
        for index in range(sample_count)
    ]
    dc_offset = sum(values) / len(values)
    values = [value - dc_offset for value in values]
    fade_samples = min(round(0.025 * SAMPLE_RATE), sample_count)
    for fade_index in range(fade_samples):
        gain = (fade_samples - fade_index - 1) / max(fade_samples - 1, 1)
        values[sample_count - fade_samples + fade_index] *= gain
    peak = max(abs(value) for value in values)
    gain = cue.target_peak / peak if peak else 1.0
    return [max(-1.0, min(1.0, value * gain)) for value in values]


def synthesize(cue: Cue) -> bytes:
    return b"".join(
        struct.pack("<h", round(value * 32767))
        for value in _render(cue)
    )


def write_cue(cue: Cue, output_dir: Path) -> dict[str, object]:
    path = output_dir / f"{cue.cue_id}.wav"
    frames = synthesize(cue)
    with wave.open(str(path), "wb") as target:
        target.setnchannels(CHANNELS)
        target.setsampwidth(SAMPLE_WIDTH)
        target.setframerate(SAMPLE_RATE)
        target.writeframes(frames)
    return {
        "id": cue.cue_id,
        "path": ((str(CONFIG.get('runtime_prefix', 'audio/runtime/sfx')) + '/' + path.name) if CONFIG.get('legacy_paths', False) else ((path.relative_to(ROOT).as_posix()) if path.is_relative_to(ROOT) else path.name)),
        "duration_seconds": cue.duration,
        "sample_rate": SAMPLE_RATE,
        "channels": CHANNELS,
        "sample_width_bytes": SAMPLE_WIDTH,
        "seed": cue.seed,
        "function": cue.function,
        "materials": list(cue.materials),
        "target_peak": cue.target_peak,
        "target_peak_dbfs": round(20.0 * math.log10(cue.target_peak), 2),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def generate(output_dir: Path) -> dict[str, object]:
    if not CONFIG.get('allow_replace', False) and any((output_dir / name).exists() for name in [*[cue.cue_id + '.wav' for cue in CUES], 'manifest.json']):
        raise ValueError('Audio output already exists')
    output_dir.mkdir(parents=True, exist_ok=True)
    expected = {f"{cue.cue_id}.wav" for cue in CUES} | {"manifest.json"}
    for stale in output_dir.iterdir():
        if (
            CONFIG.get('remove_stale', False)
            and stale.is_file()
            and stale.name not in expected
            and not stale.name.endswith(".import")
        ):
            stale.unlink()
    records = [write_cue(cue, output_dir) for cue in CUES]
    manifest = {**CONFIG.get('manifest_fields', {'generator': 'game-dev-tools:rpg-combat', 'style': '', 'provenance': {'kind': 'deterministic procedural synthesis', 'external_recordings': []}}), 'generator_version': GENERATOR_VERSION, 'cues': records}
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        type=Path,
        default=output_path("rpg-combat"),
    )
    args = parser.parse_args()
    require_program('rpg-combat')
    selected = args.output if args.output.is_absolute() else project_path(args.output)
    manifest = generate(selected)
    print(
        "COMBAT_SFX_GENERATED "
        f"cues={len(manifest['cues'])} sample_rate={SAMPLE_RATE} "
        f"generator_version={GENERATOR_VERSION}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
