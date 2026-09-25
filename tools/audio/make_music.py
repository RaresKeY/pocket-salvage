"""Synthesise the yard's quiet background loop into assets/audio/music_yard.wav.

Slow pad chords (Am F C G), a soft bass and a sparse plucked arpeggio, 32 seconds.
Every note is written modulo the loop length, so tails wrap round and the loop has no seam.
    python3 tools/audio/make_music.py
"""
import math
import random

from make_sfx import RATE, tone, write

BPM = 90
BEAT = 60 / BPM
BAR = BEAT * 4
BARS_PER_CHORD = 3
CHORDS = [  # root, then the chord's notes, as semitones above A
    (0, [0, 3, 7]),     # Am
    (-4, [-4, 0, 3]),   # F
    (3, [3, 7, 10]),    # C
    (-2, [-2, 2, 5]),   # G
]
LENGTH = BAR * BARS_PER_CHORD * len(CHORDS)
ARPEGGIO = [0, 2, 1, 2, None, 2, 1, None]  # chord-note index per eighth; None rests


def pitch(semitones, octave):
    return 220.0 * 2 ** (octave + semitones / 12)


def add_note(buffer, start, seconds, voice, attack, release):
    count = len(buffer)
    first = int(start * RATE)
    for i in range(int((seconds + release) * RATE)):
        t = i / RATE
        if t < attack:
            level = t / attack
        elif t < seconds:
            level = 1.0
        else:
            level = max(0.0, 1.0 - (t - seconds) / release)
        buffer[(first + i) % count] += level * voice(t)


def main():
    buffer = [0.0] * int(LENGTH * RATE)
    chord_seconds = BAR * BARS_PER_CHORD
    for index, (root, notes) in enumerate(CHORDS):
        start = index * chord_seconds
        for note in notes:
            f = pitch(note, -1)
            add_note(buffer, start, chord_seconds, lambda t, f=f: 0.06 * (tone(f, t, "sine") + 0.5 * tone(f * 1.003, t, "sine") + 0.2 * tone(f * 2, t, "triangle")), 2.5, 3.0)
        bass = pitch(root, -2)
        add_note(buffer, start, chord_seconds, lambda t, f=bass: 0.08 * tone(f, t, "sine"), 1.0, 2.0)
        rng = random.Random(index)
        for bar in range(BARS_PER_CHORD):
            for eighth, pick in enumerate(ARPEGGIO):
                if pick is None or rng.random() < 0.3:
                    continue
                f = pitch(notes[pick], 1)
                at = start + bar * BAR + eighth * BEAT / 2
                add_note(buffer, at, 0.05, lambda t, f=f: 0.035 * tone(f, t, "triangle") * math.exp(-t * 3.0), 0.005, 1.2)
    peak = max(abs(s) for s in buffer)
    write("music_yard", [s / peak * 0.8 for s in buffer])
    print(f"wrote music_yard.wav, {LENGTH:.1f}s")


if __name__ == "__main__":
    main()
