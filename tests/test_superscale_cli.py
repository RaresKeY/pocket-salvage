"""Exercise real CLI failures and provenance using Godot inside the managed container."""
import hashlib
import json
from pathlib import Path
import subprocess
import struct
import tempfile
import unittest
import zlib

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/pixel_lab/calibration.png"


class SuperscaleCLI(unittest.TestCase):
    def invoke(self, *args):
        return subprocess.run(
            ["godot", "--headless", "--path", str(ROOT), "--script", "tools/pixel_art/superscale.gd", "--", *args],
            cwd=ROOT, capture_output=True, text=True, timeout=30,
        )

    def test_output_provenance_and_no_overwrite(self):
        before = SOURCE.read_bytes()
        (ROOT / ".local").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / ".local") as folder:
            target = Path(folder) / "10x.png"
            args = ("--input", str(SOURCE), "--factor", "10", "--output", str(target))
            result = self.invoke(*args)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            record = json.loads(Path(str(target) + ".json").read_text())
            self.assertEqual(record["output_size"], [320, 320])
            self.assertEqual(record["source_sha256"], hashlib.sha256(before).hexdigest())
            self.assertEqual(record["output_sha256"], hashlib.sha256(target.read_bytes()).hexdigest())
            self.assertFalse(Path(record["source"]).is_absolute())
            output_before = target.read_bytes()
            self.assertNotEqual(self.invoke(*args).returncode, 0)
            self.assertEqual(target.read_bytes(), output_before)
            for factor in ["0", "-2", "2.5", "33"]:
                bad = self.invoke("--input", str(SOURCE), "--factor", factor, "--output", str(Path(folder) / "bad.png"))
                self.assertNotEqual(bad.returncode, 0, bad.stdout)
                self.assertFalse((Path(folder) / "bad.png").exists())
        self.assertEqual(SOURCE.read_bytes(), before)

    def test_rejects_missing_input_and_unknown_flags(self):
        self.assertNotEqual(self.invoke("--input", "missing.png", "--factor", "10", "--output", "unused.png").returncode, 0)
        self.assertNotEqual(self.invoke("--wat").returncode, 0)

    def test_png_precision_and_header_limits(self):
        def chunk(kind, data):
            return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

        (ROOT / ".local").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / ".local") as folder:
            folder = Path(folder)
            header = struct.pack(">IIBBBBB", 1, 1, 16, 6, 0, 0, 0)
            deep = folder / "deep.png"
            deep.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(b"\x00" + b"\xff\xff" * 4)) + chunk(b"IEND", b""))
            result = self.invoke("--input", str(deep), "--factor", "1", "--output", str(folder / "out.png"))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("16-bit", result.stderr)
            oversized = folder / "oversized.png"
            oversized.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 16385, 1, 8, 6, 0, 0, 0)))
            result = self.invoke("--input", str(oversized), "--factor", "1", "--output", str(folder / "out.png"))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("edge limit", result.stderr)
            self.assertFalse((folder / "out.png").exists())


if __name__ == "__main__":
    unittest.main()
