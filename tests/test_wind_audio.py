"""Wind master stays soft and varied, with a reproducible seamless long loop."""
import math
from pathlib import Path
import struct
import sys
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools/audio'))
from make_wind import wind_samples
from make_sfx import RATE


def rms(values):
    return math.sqrt(sum(v*v for v in values) / len(values))


class WindAudioTest(unittest.TestCase):
    def test_master(self):
        with wave.open(str(ROOT / 'assets/audio/wind_loop.wav')) as wav:
            self.assertEqual((wav.getnchannels(), wav.getsampwidth(), wav.getframerate()), (1, 2, RATE))
            self.assertGreaterEqual(wav.getnframes() / RATE, 20, 'Avoid obvious short repetition')
            raw = wav.readframes(wav.getnframes())
        values = [s / 32767 for s in struct.unpack('<%dh' % (len(raw)//2), raw)]
        level = rms(values)
        self.assertTrue(0.03 < level < 0.06, 'Keep the wind bed quiet but audible')
        roughness = rms([b-a for a,b in zip(values, values[1:])]) / level
        self.assertLess(roughness, 0.15, 'Suppress abrasive high-frequency hiss')
        self.assertLess(max(map(abs, values)), 0.4)
        self.assertLessEqual(abs(values[-1] - values[0]), 1/32767)
        windows = [rms(values[i:i+RATE]) for i in range(0, len(values), RATE)]
        self.assertGreater(max(windows) / min(windows), 1.8, 'Wind should swell and recede')
        self.assertLess(max(abs(b-a) for a,b in zip(windows, windows[1:])), 0.025, 'Swells remain gentle')
        generated = b''.join(struct.pack('<h', int(max(-1, min(1, v))*32767)) for v in wind_samples())
        self.assertEqual(raw, generated, 'Master matches the seeded recipe')
        print('wind RMS', round(level, 4), 'roughness', round(roughness, 4), 'swell ratio', round(max(windows)/min(windows), 2))


if __name__ == '__main__':
    unittest.main()
