"""Rain masters stay soft, unclipped, seamless and reproducible without playback."""
import math
from pathlib import Path
import struct
import sys
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools/audio'))
from make_rain import TIERS, rain_samples
from make_sfx import RATE


class RainAudioTest(unittest.TestCase):
    def test_masters_and_spectral_softness(self):
        previous_rms = 0.0
        for name, recipe in TIERS.items():
            with self.subTest(tier=name), wave.open(str(ROOT / 'assets/audio' / (name + '.wav'))) as wav:
                self.assertEqual((wav.getnchannels(), wav.getsampwidth(), wav.getframerate()), (1, 2, RATE))
                raw = wav.readframes(wav.getnframes())
                values = [s / 32767 for s in struct.unpack('<%dh' % (len(raw)//2), raw)]
                generated = b''.join(struct.pack('<h', int(max(-1, min(1, v))*32767)) for v in rain_samples(*recipe))
                self.assertEqual(raw, generated, 'Committed audio matches its seeded recipe')
                rms = math.sqrt(sum(v*v for v in values) / len(values))
                roughness = math.sqrt(sum((b-a)**2 for a,b in zip(values, values[1:])) / (len(values)-1)) / rms
                self.assertLess(roughness, 0.4, 'High-frequency sample jumps remain suppressed')
                self.assertLess(max(map(abs, values)), 0.5)
                self.assertLess(abs(values[-1] - values[0]), 1/32767)
                self.assertGreater(rms, previous_rms)
                previous_rms = rms
                print(name, 'RMS', round(rms,4), 'roughness', round(roughness,4))


if __name__ == '__main__':
    unittest.main()
