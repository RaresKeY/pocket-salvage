#!/usr/bin/env python3
"""Generate The Fifth Fold's original deterministic music, ambience, and effects."""

from __future__ import annotations

import hashlib
import json
import math
import shutil
import subprocess
import wave
from pathlib import Path

import numpy as np

from audio_profile import ROOT, profile, output_path, project_path, destination, require_program, select_output
CONFIG = profile('fifth-fold-audio')
RATE = int(CONFIG.get('rate', 24000))
TAU = math.tau
OUTPUT = output_path('fifth-fold-audio')
WORK = project_path(CONFIG.get('work', '.local/audio_work'))


def buffer(seconds: float) -> np.ndarray:
    return np.zeros((round(seconds * RATE), 2), dtype=np.float64)


def tone(
    mix: np.ndarray,
    start: float,
    duration: float,
    frequency: float,
    amplitude: float,
    pan: float = 0.0,
    attack: float = 0.008,
    release: float = 0.45,
    partials: tuple[float, ...] = (1.0, 2.01, 3.97),
) -> None:
    begin = max(0, round(start * RATE))
    end = min(len(mix), begin + round(duration * RATE))
    if end <= begin:
        return
    t = np.arange(end - begin, dtype=np.float64) / RATE
    envelope = np.minimum(1.0, t / max(attack, 0.001)) * np.exp(-t / max(release, 0.01))
    signal = np.zeros_like(t)
    weight = 0.0
    for index, partial in enumerate(partials, 1):
        partial_weight = 1.0 / (index**1.35)
        signal += np.sin(TAU * frequency * partial * t) * partial_weight
        weight += partial_weight
    signal *= envelope * amplitude / weight
    left = math.sqrt((1.0 - pan) * 0.5)
    right = math.sqrt((1.0 + pan) * 0.5)
    mix[begin:end, 0] += signal * left
    mix[begin:end, 1] += signal * right


def paper_hit(mix: np.ndarray, rng: np.random.Generator, start: float, amplitude: float, pan: float, woody: bool = False) -> None:
    duration = 0.20 if woody else 0.11
    begin = max(0, round(start * RATE))
    end = min(len(mix), begin + round(duration * RATE))
    if end <= begin:
        return
    t = np.arange(end - begin, dtype=np.float64) / RATE
    raw = rng.normal(0.0, 1.0, end - begin)
    kernel_size = 19 if woody else 7
    filtered = np.convolve(raw, np.ones(kernel_size) / kernel_size, mode="same")
    envelope = np.exp(-t / (0.055 if woody else 0.025))
    signal = filtered * envelope * amplitude
    if woody:
        signal += np.sin(TAU * 92.0 * t) * np.exp(-t / 0.08) * amplitude * 0.55
    mix[begin:end, 0] += signal * math.sqrt((1.0 - pan) * 0.5)
    mix[begin:end, 1] += signal * math.sqrt((1.0 + pan) * 0.5)


def drone(mix: np.ndarray, notes: tuple[float, ...], amplitude: float, drift: float) -> None:
    t = np.arange(len(mix), dtype=np.float64) / RATE
    for index, frequency in enumerate(notes):
        phase = np.sin(TAU * t / (13.0 + index * 4.0)) * drift
        signal = np.sin(TAU * frequency * t + phase) + np.sin(TAU * frequency * 2.003 * t) * 0.18
        pan = -0.55 + index * (1.1 / max(1, len(notes) - 1))
        mix[:, 0] += signal * amplitude * math.sqrt((1.0 - pan) * 0.5)
        mix[:, 1] += signal * amplitude * math.sqrt((1.0 + pan) * 0.5)


def midi(note: int) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def finish(mix: np.ndarray, loop_fade: float = 1.25) -> np.ndarray:
    fade = min(round(loop_fade * RATE), len(mix) // 5)
    if fade:
        blend = np.linspace(0.0, 1.0, fade, endpoint=False)[:, None]
        mix[-fade:] = mix[-fade:] * (1.0 - blend) + mix[:fade] * blend
    peak = float(np.max(np.abs(mix)))
    if peak > 0.0:
        mix *= 0.78 / peak
    return np.tanh(mix * 1.08) * 0.90


def music(name: str, seconds: float, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    mix = buffer(seconds)
    plan = CONFIG['music_plans'][name]
    roots, motif, pulse, texture = (plan[key] for key in ('roots', 'motif', 'pulse', 'texture'))
    drone(mix, tuple(midi(note) for note in roots), float(plan.get('drone_amplitude', .032)), 0.22)
    phrase = 2.0
    phrase_index = 0
    while phrase < seconds - 3.0:
        for index, note in enumerate(motif):
            offset = index * (0.74 if plan.get('fast', False) else 1.08)
            tone(
                mix,
                phrase + offset,
                2.2,
                midi(note + (12 if phrase_index % 4 == 3 and index == 4 else 0)),
                0.085,
                -0.55 + index * 0.27,
                0.004 if texture != "page" else 0.035,
                0.55 if texture != "binder" else 0.8,
                (1.0, 2.0, 3.01) if texture != "binder" else (1.0, 2.71, 4.12),
            )
        phrase += 8.0 if plan.get('fast', False) else 10.5
        phrase_index += 1
    hit = 0.8
    hit_index = 0
    while hit < seconds - 0.6:
        jitter = float(rng.uniform(-0.035, 0.035))
        paper_hit(mix, rng, hit + jitter, 0.055 if texture == "type" else 0.034, -0.7 + (hit_index % 5) * 0.35, texture in ("type", "binder"))
        if texture == "binder" and hit_index % 4 == 0:
            tone(mix, hit, 0.4, midi(84), 0.035, 0.5, 0.001, 0.12, (1.0, 2.79))
        if texture == "type" and hit_index % 3 == 0:
            tone(mix, hit, 0.28, midi(38), 0.055, -0.2, 0.001, 0.09, (1.0, 1.49))
        hit += pulse
        hit_index += 1
    return finish(mix)


def ambience(name: str, seconds: float, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    mix = buffer(seconds)
    plan = CONFIG['ambience_plans'][name]
    roots = tuple(midi(note) for note in plan['roots'])
    drone(mix, roots, 0.026, 0.48)
    spacing = float(plan['spacing'])
    event = 0.7
    while event < seconds - 0.4:
        pan = float(rng.uniform(-0.9, 0.9))
        paper_hit(mix, rng, event + float(rng.uniform(-0.12, 0.12)), 0.025, pan, plan.get('woody', False))
        if plan.get('bell', False):
            tone(mix, event + 0.08, 0.55, midi(86), 0.018, -pan, 0.001, 0.18, (1.0, 3.4))
        event += spacing
    return finish(mix, 0.8)


def effect(name: str, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    durations = {key: float(value['duration']) for key, value in CONFIG['effect_specs'].items()}
    mix = buffer(durations[name])
    if name in ("ui", "cycle"):
        tone(mix, 0.0, durations[name], 620.0 if name == "ui" else 760.0, 0.20, 0.1, 0.001, 0.07, (1.0, 2.0))
    elif name == "jump":
        tone(mix, 0.0, 0.25, 180.0, 0.18, 0.0, 0.005, 0.13, (1.0, 1.5, 2.02))
        tone(mix, 0.07, 0.18, 260.0, 0.11, 0.2, 0.004, 0.10, (1.0, 2.0))
    elif name == "footstep":
        paper_hit(mix, rng, 0.0, 0.28, 0.0, True)
    elif name == "stamp":
        paper_hit(mix, rng, 0.0, 0.42, 0.0, True)
        tone(mix, 0.01, 0.36, 92.0, 0.22, -0.1, 0.002, 0.11, (1.0, 2.0))
    elif name == "fold":
        for index in range(7):
            paper_hit(mix, rng, index * 0.055, 0.11 - index * 0.008, -0.65 + index * 0.2)
        tone(mix, 0.18, 0.36, 330.0, 0.10, 0.15, 0.02, 0.18, (1.0, 2.01))
    elif name == "tear":
        for index in range(10):
            paper_hit(mix, rng, index * 0.038, 0.15, -0.8 + index * 0.16)
    elif name == "pickup":
        paper_hit(mix, rng, 0.0, 0.16, -0.2)
        tone(mix, 0.04, 0.25, 420.0, 0.12, 0.2, 0.003, 0.12, (1.0, 2.0))
    elif name in ("ink", "note", "help", "checkpoint"):
        chord = CONFIG['effect_specs'][name]['chord']
        for index, frequency in enumerate(chord):
            tone(mix, index * 0.10, durations[name] - index * 0.06, frequency, 0.14, -0.45 + index * 0.42, 0.006, 0.24, (1.0, 2.0))
    elif name == "reset":
        for index in range(5):
            tone(mix, index * 0.055, 0.38, 330.0 * 2 ** (-index / 12), 0.11, 0.0, 0.002, 0.14, (1.0, 1.5))
        paper_hit(mix, rng, 0.18, 0.16, 0.0)
    return finish(mix, 0.0)


def write_wav(path: Path, mix: np.ndarray) -> None:
    destination(path, 'fifth-fold-audio')
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(mix, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(2)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(pcm.tobytes())


def ogg_crc(page: bytes) -> int:
    checksum = 0
    for value in page:
        checksum ^= value << 24
        for _ in range(8):
            if checksum & 0x80000000:
                checksum = ((checksum << 1) ^ 0x04C11DB7) & 0xFFFFFFFF
            else:
                checksum = (checksum << 1) & 0xFFFFFFFF
    return checksum


def normalize_ogg_serial(path: Path, serial: int) -> None:
    """Replace FFmpeg's randomized Ogg serial and repair every page CRC."""
    data = bytearray(path.read_bytes())
    cursor = 0
    pages = 0
    while cursor < len(data):
        if data[cursor:cursor + 4] != b"OggS" or cursor + 27 > len(data):
            raise ValueError(f"Malformed Ogg page at byte {cursor}: {path}")
        segment_count = data[cursor + 26]
        table_end = cursor + 27 + segment_count
        if table_end > len(data):
            raise ValueError(f"Truncated Ogg segment table: {path}")
        page_end = table_end + sum(data[cursor + 27:table_end])
        if page_end > len(data):
            raise ValueError(f"Truncated Ogg page payload: {path}")
        data[cursor + 14:cursor + 18] = int(serial & 0xFFFFFFFF).to_bytes(4, "little")
        data[cursor + 22:cursor + 26] = b"\0\0\0\0"
        checksum = ogg_crc(bytes(data[cursor:page_end]))
        data[cursor + 22:cursor + 26] = checksum.to_bytes(4, "little")
        cursor = page_end
        pages += 1
    if pages == 0:
        raise ValueError(f"Ogg stream contains no pages: {path}")
    path.write_bytes(data)


def encode_ogg(source: Path, target: Path, serial: int) -> None:
    destination(target, 'fifth-fold-audio')
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(source), "-c:a", "libvorbis", "-q:a", "5", str(target)],
        check=True,
    )
    normalize_ogg_serial(target, serial)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    global OUTPUT
    OUTPUT = select_output('fifth-fold-audio', OUTPUT)
    if shutil.which("ffmpeg") is None:
        raise SystemExit("ffmpeg is required for deterministic Vorbis encoding")
    groups = [('music', CONFIG.get('music_jobs', []), music), ('ambience', CONFIG.get('ambience_jobs', []), ambience), ('sfx', CONFIG.get('effect_jobs', []), effect)]
    for kind, declared, render in groups:
        for job in declared:
            destination(OUTPUT / kind / (job['name'] + ('.wav' if kind == 'sfx' else '.ogg')), 'fifth-fold-audio')
    destination(OUTPUT / 'audio_manifest.json', 'fifth-fold-audio')
    WORK.mkdir(parents=True, exist_ok=True)
    jobs: list[dict[str, object]] = []
    for kind, declared, render in groups:
        for job in declared:
            name, seed = job['name'], int(job['seed'])
            kernel = job.get('kernel', name)
            if kind == 'sfx':
                target = OUTPUT / kind / (name + '.wav')
                rendered = effect(kernel, seed)
                seconds = len(rendered) / RATE
                write_wav(target, rendered)
            else:
                seconds = float(job['seconds'])
                wav_path = WORK / (('ambience_' if kind == 'ambience' else '') + name + '.wav')
                target = OUTPUT / kind / (name + '.ogg')
                write_wav(wav_path, render(kernel, seconds, seed))
                encode_ogg(wav_path, target, seed)
            jobs.append({'kind': kind, 'name': name, 'file': target.relative_to(ROOT).as_posix(), 'seconds': seconds, 'seed': seed, 'sha256': sha256(target)})
    manifest = {'version': 1, 'generator': CONFIG.get('generator', 'game-dev-tools:fifth-fold-audio'), 'sample_rate': RATE, 'assets': jobs}
    (OUTPUT / 'audio_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    counts = [len(declared) for kind, declared, render in groups]
    print(f"{CONFIG.get('message_prefix', 'AUDIO_GENERATED')} assets={len(jobs)} music={counts[0]} ambience={counts[1]} sfx={counts[2]}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
