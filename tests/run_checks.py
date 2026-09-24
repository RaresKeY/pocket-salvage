"""Bounded engine checks that also fail on logged script errors and missing markers."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BASE = ["godot", "--headless", "--path", str(ROOT)]
checks = [
    (BASE + ["--editor", "--import", "--quit"], None),
    (BASE + ["--script", "tests/sprite_playground_test.gd", "--quit-after", "600", "--max-fps", "60"], "SPRITE_PLAYGROUND_TEST_OK"),
    (BASE + ["--script", "tests/pixel_scaling_test.gd"], "PIXEL_SCALING_TEST_OK"),
    (BASE + ["--script", "tests/rope_test.gd"], "ROPE_TEST_OK"),
    (BASE + ["--script", "tests/rope_lab_test.gd"], "ROPE_LAB_TEST_OK"),
    (BASE + ["--script", "tests/physics_parts_test.gd"], "PHYSICS_PARTS_TEST_OK"),
    (BASE + ["--scene", "res://labs/physics/lab.tscn", "--quit-after", "120"], None),
    (BASE + ["--scene", "res://labs/rope/lab.tscn", "--quit-after", "120"], None),
    ([sys.executable, "tests/test_superscale_cli.py"], None),
    (BASE + ["--quit-after", "60", "--", "--self-test"], "PIXEL_LAB_TEST_OK"),
    (BASE + ["--quit-after", "2"], None),
]
for command, marker in checks:
    try:
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=90)
    except subprocess.TimeoutExpired:
        raise SystemExit(f"Check timed out: {command}")
    output = result.stdout + result.stderr
    print(output, end="", flush=True)
    if result.returncode or "SCRIPT ERROR:" in output or "ERROR:" in output or (marker and marker not in output):
        raise SystemExit(f"Check failed: {command}")
print("CHECKS_OK")
