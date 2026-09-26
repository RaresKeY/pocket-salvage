"""Seeded, softly shifting wind; run this file to regenerate only wind_loop.wav."""
import math
import random
from make_sfx import RATE, write

SECONDS = 24
RMS = 0.045


def wind_samples():
    count = RATE * SECONDS
    rng = random.Random(104)
    noise = [rng.uniform(-1, 1) for _ in range(count)]
    states = [0.0] * 3
    rumble = 0.0
    rumble_alpha = 1 - math.exp(-2 * math.pi * 65 / RATE)
    samples = []
    # Repeat the noise and control curves to warm filters across the loop seam.
    for cycle in range(2):
        for i, value in enumerate(noise):
            phase = math.tau * i / count
            swell = (0.65 + 0.18 * math.sin(phase + 0.7)
                     + 0.11 * math.sin(3 * phase + 2.1)
                     + 0.06 * math.sin(5 * phase + 0.4))
            cutoff = 430 + 140 * math.sin(2 * phase + 1.2) + 80 * math.sin(5 * phase)
            alpha = 1 - math.exp(-math.tau * cutoff / RATE)
            for stage in range(3):
                states[stage] += alpha * (value - states[stage])
                value = states[stage]
            rumble += rumble_alpha * (value - rumble)
            if cycle:
                samples.append((value - rumble) * swell)
    mean = sum(samples) / count
    samples = [value - mean for value in samples]
    rms = math.sqrt(sum(value * value for value in samples) / count)
    samples = [value * RMS / rms for value in samples]
    midpoint = (samples[0] + samples[-1]) * 0.5
    first, last = samples[0], samples[-1]
    overlap = int(RATE * 0.025)
    for i in range(overlap):
        weight = (1 - i / overlap) ** 2
        samples[i] += (midpoint - first) * weight
        samples[-1-i] += (midpoint - last) * weight
    return samples


def generate():
    write('wind_loop', wind_samples())


if __name__ == '__main__':
    generate()
    print('Wrote soft 24-second wind loop.')
