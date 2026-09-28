"""Author the cup-entry plonk as portable PCM. Python standard library only."""
from pathlib import Path
import math
import random
import struct
import wave

from audio_profile import ROOT, profile, output_path, destination, require_program
CONFIG = profile('odd-cup-plonk')
RATE = int(CONFIG.get('rate', 44100))
DURATION = float(CONFIG.get('duration', .32))
def render():
    rng = random.Random(int(CONFIG.get("seed", 260926)))
    samples = []
    body_phase = bubble_phase = small_phase = 0.0
    wet = 0.0
    for i in range(round(RATE * DURATION)):
        t = i / RATE
        # Rounded low impact, then a rising bubble resonance and small wet tail.
        body_phase += math.tau * (125 + 210 * math.exp(-t / .014)) / RATE
        body = .72 * math.sin(body_phase) * math.exp(-t / .034)
        bubble_time = max(0., t - .012)
        bubble_phase += math.tau * (540 + 620 * (1 - math.exp(-bubble_time / .034))) / RATE
        bubble = .30 * math.sin(bubble_phase) * (1-math.exp(-bubble_time/.002)) * math.exp(-bubble_time/.037)
        small_time = max(0., t - .051)
        small_phase += math.tau * (1150 + 560 * (1-math.exp(-small_time/.022))) / RATE
        small = .085 * math.sin(small_phase) * (1-math.exp(-small_time/.003)) * math.exp(-small_time/.025)
        wet += .19 * (rng.uniform(-1,1)-wet)
        splash = .30 * wet * math.exp(-t/.022)
        attack = 1-math.exp(-t/.0008)
        tail = min(1., max(0., (DURATION-t)/.025))
        samples.append((body+bubble+small+splash)*attack*tail)
    # Small ceramic-space reflections, kept beneath the water body.
    source = samples[:]
    for delay, gain in ((.016,.075),(.029,.035)):
        offset = round(delay*RATE)
        for i in range(offset,len(samples)):
            samples[i] += source[i-offset]*gain*min(1.,(len(samples)-1-i)/(RATE*.025))
    peak=max(abs(v) for v in samples)
    samples=[v*float(CONFIG.get("peak", .28))/peak for v in samples]
    samples[0]=samples[-1]=0.
    return samples


def main():
    require_program('odd-cup-plonk')
    samples = render()
    path = destination(output_path('odd-cup-plonk') / str(CONFIG.get('file', 'plonk.wav')), 'odd-cup-plonk')
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(RATE)
        out.writeframes(b''.join(struct.pack('<h', round(v*32767)) for v in samples))
    print(f'{path.relative_to(ROOT)}: {DURATION}s, {RATE} Hz mono PCM16, peak {float(CONFIG.get("peak", .28)):g}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
