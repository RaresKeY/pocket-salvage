"""Soft, deterministic rain beds. Standard library only; no raw white-noise layer.

Run python3 tools/audio/make_rain.py to regenerate only the three rain WAVs.
"""
import math
import random
from make_sfx import RATE, write, seal_loop, normalise, lowpass

from audio_profile import profile, select_output
import make_sfx as _sfx
CONFIG = profile('pocket-rain')
TIERS = CONFIG.get('tiers', {})
SECONDS = float(CONFIG.get('seconds', 8))


def rain_samples(cutoff, amplitude, seed):
    count = int(RATE * SECONDS)
    rng = random.Random(seed)
    noise = [rng.uniform(-1, 1) for _ in range(count)]
    # Three cascaded low-pass stages remove the abrasive high-frequency noise.
    # Warm up over a complete repeated period so the filter also loops smoothly.
    alpha = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    states = [0.0] * 3
    samples = []
    for cycle in range(2):
        for i, value in enumerate(noise):
            value = lowpass(value, states, alpha)
            if cycle:
                # Slow, periodic variation; no square-wave tremolo or sharp taps.
                phase = 2 * math.pi * i / count
                samples.append(value * (0.87 + 0.08 * math.sin(phase) + 0.05 * math.sin(phase * 3)))
    return seal_loop(normalise(samples, amplitude), 0.025)


def generate():
    for name, recipe in TIERS.items():
        write(name, rain_samples(*recipe))
    return len(TIERS)


def main():
    _sfx.OUT = select_output('pocket-rain', _sfx.OUT, configured_default=True)
    generate()
    print('Wrote slight, normal and violent soft rain loops.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
