"""Seeded, softly shifting wind; run this file to regenerate only wind_loop.wav."""
import math
import random
from make_sfx import RATE, write, seal_loop, normalise, lowpass

from audio_profile import profile, select_output
import make_sfx as _sfx
CONFIG = profile('pocket-wind')
SECONDS = float(CONFIG.get('seconds', 24))
RMS = float(CONFIG.get('rms', .045))
SEED = int(CONFIG.get('seed', 104))


def wind_samples():
    count = int(RATE * SECONDS)
    rng = random.Random(SEED)
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
            value = lowpass(value, states, alpha)
            rumble += rumble_alpha * (value - rumble)
            if cycle:
                samples.append((value - rumble) * swell)
    return seal_loop(normalise(samples, RMS), 0.025)


def generate():
    write(str(CONFIG.get('name', 'wind')), wind_samples())
    return 1


def main():
    _sfx.OUT = select_output('pocket-wind', _sfx.OUT, configured_default=True)
    generate()
    print('Wrote soft 24-second wind loop.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
