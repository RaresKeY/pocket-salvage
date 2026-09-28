"""Original deterministic synthesized Foley; no recordings or external packages."""
from pathlib import Path
import argparse
import math
import random
import struct
import wave

from audio_profile import ROOT, profile, output_path, project_path, destination, require_program
CONFIG = profile('fog-foley')
RATE = int(CONFIG.get('rate', 32000))
OUT = output_path('fog-foley')


def render(kind, duration, seed):
    rng = random.Random(seed)
    low = 0.0
    slow = 0.0
    samples = []
    softened = 0.0
    softened_twice = 0.0
    is_step = kind.startswith("step_")
    is_crampon = kind.startswith("crampon_")
    for i in range(int(duration * RATE)):
        t = i / RATE
        u = t / duration
        noise = rng.uniform(-1, 1)
        low += (noise - low) * 0.075
        slow += (noise - slow) * 0.006
        high = noise - low
        attack_seconds = 0.09 if kind in ('wind', 'sweep', 'snow_slide') else 0.026 if is_step else 0.018
        attack = math.sin(min(1, t / attack_seconds) * math.pi / 2) ** 2
        tail = math.sin(min(1, (duration - t) / 0.08) * math.pi / 2) ** 2
        if kind == "wind":
            # Integer-period modulation and overlap at the seam make a calm loop.
            gain = 0.45 + 0.2 * math.sin(math.tau * u) + 0.12 * math.sin(math.tau * u * 3)
            value = (low * 0.7 + slow * 2.8) * gain
        elif kind in ("throw", "sweep", "snow_slide"):
            swell = math.sin(math.pi * u) ** (1.4 if kind == "sweep" else 0.7)
            value = (low * 1.9 + high * 0.035) * swell
            if kind == "snow_slide":
                value += high * 0.06 * math.exp(-t * 8)
        elif is_crampon:
            # Small steel teeth seat in stone: dry grit and a muted tick,
            # not the long resonant ring of the grappling hook.
            scrape = math.sin(math.pi * u) ** 1.3 * math.exp(-t * 12)
            value = (low * .8 + high * .045) * scrape
            for frequency, strength in [(710, .16), (1437, .09), (2261, .035)]:
                frequency *= 1 + (seed % 3 - 1) * .035
                value += math.sin(math.tau * frequency * t) * strength * math.exp(-t * 48)
            value += low * .5 * math.exp(-t * 36)
        elif kind == "metal":
            value = high * 0.32 * math.exp(-t * 75)
            for frequency, strength, decay in [(1270, .24, 15), (2093, .17, 11), (3471, .10, 20), (613, .14, 26)]:
                value += math.sin(math.tau * frequency * t) * strength * math.exp(-t * decay)
            value += low * math.exp(-t * 30)
        elif kind == "hook_reject":
            # A glancing clink followed by a descending, gritty skid: clearly
            # different from the sustained successful-catch metal resonance.
            value = low * .6 * math.exp(-t * 30)
            for start, strength in [(0, .42), (.073, .24)]:
                elapsed = t - start
                if elapsed >= 0:
                    envelope = (1 - math.exp(-elapsed * 550)) * math.exp(-elapsed * 44)
                    value += (math.sin(math.tau * 840 * elapsed) + .3 * math.sin(math.tau * 1510 * elapsed)) * strength * envelope
            skid = max(0, t - .045)
            envelope = (1 - math.exp(-skid * 65)) * math.exp(-skid * 13)
            phase = math.tau * (320 * skid + 390 / 12 * (1 - math.exp(-skid * 12)))
            value += (math.sin(phase) * .16 + low * .85 + high * .025) * envelope
        elif kind == "bow":
            value = math.sin(math.tau * (160 * t + 12 * (1 - math.exp(-t * 15)))) * math.exp(-t * 23) * .32
            value += high * .1 * math.exp(-t * 40) + low * math.sin(math.pi * u) * .4
        elif kind == "arrow_wood":
            # A dull shaft impact, followed by short, uneven fiber breaks.
            # No metal ring or bright explosive snap; the cave bus adds space.
            value = low * .85 * math.exp(-t * 27)
            for frequency, strength in [(173, .40), (367, .20), (719, .07)]:
                value += math.sin(math.tau * frequency * t) * strength * math.exp(-t * 32)
            for start, strength, decay in [(.055, .9, 95), (.086, .65, 120), (.128, .35, 80)]:
                elapsed = t - start
                if elapsed >= 0:
                    envelope = (1 - math.exp(-elapsed * 650)) * math.exp(-elapsed * decay)
                    value += (low * 2.1 + high * .13) * strength * envelope
        elif kind == "deer":
            value = math.sin(math.tau * 83 * t) * math.exp(-t * 34) * .48 + low * math.exp(-t * 18) * .9
        else:
            # Soft compression thump followed by dry, irregular snow crystals.
            grains = (.3 + .7 * abs(math.sin(t * 133 + seed))) * math.exp(-t * 10)
            value = high * grains * .22 + low * math.exp(-t * 13) * .9
            value += math.sin(math.tau * 95 * t) * .18 * math.exp(-t * 35)
        # Two gentle low-pass stages remove brittle hiss and metallic needles.
        cutoff = 850 if kind in ('wind', 'sweep', 'snow_slide') else 1650 if is_step or is_crampon else 2100
        coefficient = 1 - math.exp(-math.tau * cutoff / RATE)
        softened += (value - softened) * coefficient
        softened_twice += (softened - softened_twice) * coefficient
        samples.append(softened_twice * attack * tail)
    if kind == "wind":
        overlap = RATE // 2
        # Blend the trailing half second over the beginning, then omit it.
        for i in range(overlap):
            blend = i / overlap
            samples[i] = samples[-overlap+i] * (1-blend) + samples[i] * blend
        samples = samples[:-overlap]
    dc = sum(samples) / len(samples)
    samples = [x - dc for x in samples]
    rms = math.sqrt(sum(x*x for x in samples) / len(samples)) or 1
    # Quiet RMS targets plus a separate peak ceiling, not peak-only boosting.
    target_db = -34 if kind == 'wind' else -31 if kind in ('sweep', 'snow_slide') else -29 if is_crampon else -27
    peak_cap = 10 ** (-15 / 20)
    peak = max(abs(x) for x in samples) or 1
    gain = min(10 ** (target_db / 20) / rms, peak_cap / peak)
    return b"".join(struct.pack("<h", int(max(-peak_cap, min(peak_cap, x * gain)) * 32767)) for x in samples)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--steps-only", action="store_true", help="Regenerate only the four footstep variants")
    parser.add_argument("--crampons-only", action="store_true", help="Generate only the two rock-climbing footstep variants")
    parser.add_argument("--wood-only", action="store_true", help="Generate only the arrow impact and timber break")
    parser.add_argument("--hook-reject-only", action="store_true", help="Generate only the ungrippable-stone hook bounce")
    parser.add_argument('--output')
    args = parser.parse_args()
    require_program('fog-foley')
    global OUT
    if args.output:
        OUT = project_path(args.output)
    OUT.mkdir(parents=True, exist_ok=True)
    effects = CONFIG.get('effects', [])
    for job in effects:
        name, duration = str(job['name']), float(job['duration'])
        kind, seed = str(job.get('kind', name)), int(job['seed'])
        if args.steps_only and not kind.startswith("step_"):
            continue
        if args.crampons_only and not kind.startswith("crampon_"):
            continue
        if args.wood_only and kind != "arrow_wood":
            continue
        if args.hook_reject_only and kind != "hook_reject":
            continue
        with wave.open(str(destination(OUT / f"{name}.wav", "fog-foley")), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(RATE)
            output.writeframes(render(kind, duration, seed))


if __name__ == "__main__":
    main()
