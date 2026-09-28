"""Synthesise the salvage round's retro sound effects into assets/audio/ as 16-bit mono WAVs.

Deterministic (fixed seed), standard library only. Rerun after changing a recipe:
    python3 tools/audio/make_sfx.py
"""
import math
import random
import struct
import wave
from pathlib import Path

from audio_profile import ROOT, profile, output_path, destination, select_output
from audio_expression import compile_recipe
CONFIG = profile('pocket-sfx')
RATE = int(CONFIG.get('rate', 22050))
OUT = output_path('pocket-sfx')
RENDER_SEED = int(CONFIG.get('seed', 7))


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
    rng = random.Random(RENDER_SEED)
    count = int(RATE * seconds)
    return [sample(i / RATE, i / count, rng.uniform(-1, 1)) for i in range(count)]


def envelope(progress, attack=0.02, decay_power=1.5):
    if progress < attack:
        return progress / attack
    return (1.0 - (progress - attack) / (1.0 - attack)) ** decay_power


def sweep(start, end, progress):
    return start * (end / start) ** progress


RECIPES = {name: (float(recipe['seconds']), compile_recipe(recipe['expression'], {'tone': tone, 'envelope': envelope, 'sweep': sweep})) for name, recipe in CONFIG.get('recipes', {}).items()}
LOOPS = {name: compile_recipe(expression, {'tone': tone, 'envelope': envelope, 'sweep': sweep}) for name, expression in CONFIG.get('loops', {}).items()}


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
    with wave.open(str(destination(OUT / f"{name}.wav", "pocket-sfx")), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(frames)


def seal_loop(samples, seconds):
    """Bend the first and last `seconds` towards a shared midpoint so the loop seam doesn't click.
    The taper keeps the rest of the sound untouched."""
    overlap = int(RATE * seconds)
    midpoint = (samples[0] + samples[-1]) * 0.5
    first, last = samples[0], samples[-1]
    for i in range(overlap):
        weight = (1.0 - i / overlap) ** 2
        samples[i] += (midpoint - first) * weight
        samples[-1 - i] += (midpoint - last) * weight
    return samples


def normalise(samples, rms):
    """Remove any DC offset, then scale to the given RMS loudness."""
    mean = sum(samples) / len(samples)
    samples = [value - mean for value in samples]
    current = math.sqrt(sum(value * value for value in samples) / len(samples))
    return [value * rms / current for value in samples]


def lowpass(value, states, alpha):
    """Run `value` through cascaded one-pole low-pass stages, updating `states` in place."""
    for stage in range(len(states)):
        states[stage] += alpha * (value - states[stage])
        value = states[stage]
    return value


def loop_samples(sample):
    """A one-second loop of a recipe, sealed at the seam."""
    return seal_loop(render(1.0, sample), 0.02)


def main():
    global OUT
    OUT = select_output('pocket-sfx', OUT)
    for name, (seconds, sample) in RECIPES.items():
        write(name, render(seconds, sample))
    for name, sample in LOOPS.items():
        write(name, loop_samples(sample))
    from make_rain import generate as generate_rain
    from make_wind import generate as generate_wind
    generators = {'pocket-rain': generate_rain, 'pocket-wind': generate_wind}
    extra = sum(generators[name]() for name in CONFIG.get('extra_programs', []))
    print(f"wrote {len(RECIPES) + len(LOOPS) + extra} sounds to {OUT}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
