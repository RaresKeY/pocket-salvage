#!/usr/bin/env python3
"""Validate deterministic runtime combat SFX and committed provenance."""

from __future__ import annotations

import hashlib
import json
import math
import struct
import tempfile
import wave
from pathlib import Path

from generate_combat_sfx import (
    CHANNELS,
    CUES,
    GENERATOR_VERSION,
    SAMPLE_RATE,
    SAMPLE_WIDTH,
    generate,
)


from audio_profile import ROOT, output_path
RUNTIME = output_path('rpg-combat')
MANIFEST = RUNTIME / "manifest.json"


def fail(message: str) -> None:
    raise SystemExit(f"COMBAT_SFX_FAILED: {message}")


def main() -> int:
    if not MANIFEST.exists():
        fail("missing manifest; run make build-combat-sfx")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if manifest.get("generator_version") != GENERATOR_VERSION:
        fail("manifest generator version is stale")
    provenance = manifest.get("provenance", {})
    if (
        provenance.get("kind") != "deterministic procedural synthesis"
        or provenance.get("external_recordings") != []
    ):
        fail("manifest must declare recording-free procedural provenance")
    records = manifest.get("cues", [])
    if len(records) != len(CUES):
        fail(f"expected {len(CUES)} cues, found {len(records)}")
    by_id = {record.get("id"): record for record in records}
    if set(by_id) != {cue.cue_id for cue in CUES}:
        fail("manifest cue IDs do not match the generator contract")

    with tempfile.TemporaryDirectory(prefix="rpg-1-sfx-") as temp_name:
        regenerated = Path(temp_name)
        generated = generate(regenerated)
        regenerated_by_id = {
            record["id"]: record for record in generated["cues"]
        }
        for cue in CUES:
            path = RUNTIME / f"{cue.cue_id}.wav"
            if not path.exists():
                fail(f"missing {path.relative_to(ROOT)}")
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            if digest != by_id[cue.cue_id].get("sha256"):
                fail(f"manifest hash is stale for {cue.cue_id}")
            if digest != regenerated_by_id[cue.cue_id]["sha256"]:
                fail(f"{cue.cue_id} is not deterministic generator output")
            record = by_id[cue.cue_id]
            if record.get("materials") != list(cue.materials):
                fail(f"{cue.cue_id} material identity is stale")
            if not math.isclose(
                float(record.get("target_peak", 0.0)),
                cue.target_peak,
                abs_tol=1e-6,
            ):
                fail(f"{cue.cue_id} target peak is stale")
            with wave.open(str(path), "rb") as source:
                if source.getframerate() != SAMPLE_RATE:
                    fail(f"{cue.cue_id} is not {SAMPLE_RATE} Hz")
                if source.getnchannels() != CHANNELS:
                    fail(f"{cue.cue_id} must be mono")
                if source.getsampwidth() != SAMPLE_WIDTH:
                    fail(f"{cue.cue_id} must be 16-bit PCM")
                duration = source.getnframes() / source.getframerate()
                if not 0.08 <= duration <= 0.50:
                    fail(f"{cue.cue_id} duration {duration:.3f}s is unsafe")
                frames = source.readframes(source.getnframes())
                samples = [
                    value / 32768.0
                    for (value,) in struct.iter_unpack("<h", frames)
                ]
                peak = max(abs(value) for value in samples)
                rms = math.sqrt(
                    sum(value * value for value in samples) / len(samples)
                )
                dc_offset = abs(sum(samples) / len(samples))
                tail = samples[-480:]
                tail_rms = math.sqrt(
                    sum(value * value for value in tail) / len(tail)
                )
                crest_db = 20.0 * math.log10(peak / max(rms, 1e-9))
                if not math.isclose(peak, cue.target_peak, abs_tol=0.002):
                    fail(
                        f"{cue.cue_id} peak {peak:.3f} does not match "
                        f"authored target {cue.target_peak:.3f}"
                    )
                if peak > 0.51:
                    fail(f"{cue.cue_id} peak {peak:.3f} is too loud")
                if not 0.015 <= rms <= 0.14:
                    fail(f"{cue.cue_id} RMS {rms:.3f} is outside contract")
                if not 7.0 <= crest_db <= 24.0:
                    fail(
                        f"{cue.cue_id} crest {crest_db:.1f} dB "
                        "is outside the dry transient contract"
                    )
                if dc_offset > 0.01:
                    fail(f"{cue.cue_id} DC offset {dc_offset:.4f} is unsafe")
                if tail_rms > 0.012:
                    fail(f"{cue.cue_id} tail {tail_rms:.3f} is not settled")

    unexpected = {
        path.name
        for path in RUNTIME.iterdir()
        if path.is_file() and not path.name.endswith(".import")
    } - ({f"{cue.cue_id}.wav" for cue in CUES} | {"manifest.json"})
    if unexpected:
        fail(f"unexpected runtime files: {sorted(unexpected)}")
    print(
        "COMBAT_SFX_OK "
        f"cues={len(CUES)} sample_rate={SAMPLE_RATE} "
        f"channels=mono deterministic=true generator_version={GENERATOR_VERSION}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
