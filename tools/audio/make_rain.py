"""Soft, deterministic rain beds. Standard library only; no raw white-noise layer.

Run python3 tools/audio/make_rain.py to regenerate only the three rain WAVs.
"""
import math
import random
from make_sfx import RATE, write

# Name, low-pass cutoff, RMS amplitude, seed. Density grows without a bright hiss.
TIERS = {
    'rain_slight_loop': (700, 0.035, 71),
    'rain_loop': (950, 0.055, 72),
    'rain_violent_loop': (1200, 0.075, 73),
}


def rain_samples(cutoff, amplitude, seed):
    count = RATE * 8
    rng = random.Random(seed)
    noise = [rng.uniform(-1, 1) for _ in range(count)]
    # Three cascaded low-pass stages remove the abrasive high-frequency noise.
    # Warm up over a complete repeated period so the filter also loops smoothly.
    alpha = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    states = [0.0] * 3
    samples = []
    for cycle in range(2):
        for i, value in enumerate(noise):
            for stage in range(3):
                states[stage] += alpha * (value - states[stage])
                value = states[stage]
            if cycle:
                # Slow, periodic variation; no square-wave tremolo or sharp taps.
                phase = 2 * math.pi * i / count
                samples.append(value * (0.87 + 0.08 * math.sin(phase) + 0.05 * math.sin(phase * 3)))
    mean = sum(samples) / count
    samples = [value - mean for value in samples]
    rms = math.sqrt(sum(value * value for value in samples) / count)
    samples = [value * amplitude / rms for value in samples]
    # Gentle local correction makes the quantized loop endpoints identical.
    midpoint = (samples[0] + samples[-1]) * 0.5
    first, last = samples[0], samples[-1]
    overlap = int(RATE * 0.025)
    for i in range(overlap):
        weight = (1 - i / overlap) ** 2
        samples[i] += (midpoint - first) * weight
        samples[-1-i] += (midpoint - last) * weight
    return samples


def generate():
    for name, recipe in TIERS.items():
        write(name, rain_samples(*recipe))


if __name__ == '__main__':
    generate()
    print('Wrote slight, normal and violent soft rain loops.')
