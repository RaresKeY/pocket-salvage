"""Bounded engine checks that also fail on logged script errors and missing markers."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BASE = ["godot", "--headless", "--path", str(ROOT)]
checks = [
    (BASE + ["--editor", "--import", "--quit"], None),
    (BASE + ["--script", "tests/blood_moon_test.gd", "--quit-after", "600", "--max-fps", "60"], "BLOOD_MOON_TEST_OK"),
    (BASE + ["--script", "tests/level_selection_test.gd", "--quit-after", "300", "--max-fps", "60"], "LEVEL_SELECTION_TEST_OK"),
    (BASE + ["--script", "tests/input_test.gd", "--max-fps", "60", "--quit-after", "1800", "--", "--touch-controls"], "INPUT_TEST_OK"),
    (BASE + ["--script", "tests/audio_test.gd", "--quit-after", "1200", "--max-fps", "60"], "AUDIO_TEST_OK"),
    (BASE + ["--script", "tests/salvage_navigation_test.gd", "--max-fps", "60", "--quit-after", "300"], "SALVAGE_NAVIGATION_TEST_OK"),
    (BASE + ["--script", "tests/salvage_test.gd", "--fixed-fps", "60", "--quit-after", "20000"], "SALVAGE_TEST_OK"),
    (BASE + ["--script", "tests/physical_suspension_test.gd", "--fixed-fps", "60", "--quit-after", "1800"], "PHYSICAL_SUSPENSION_TEST_OK"),
    (BASE + ["--script", "tests/crane_test.gd", "--quit-after", "900", "--max-fps", "60"], "CRANE_TEST_OK"),
    (BASE + ["--script", "tests/round_test.gd", "--quit-after", "1500", "--max-fps", "60"], "ROUND_TEST_OK"),
    (BASE + ["--script", "tests/ambience_test.gd", "--fixed-fps", "60", "--quit-after", "6000"], "AMBIENCE_TEST_OK"),
    (BASE + ["--script", "tests/weather_test.gd", "--fixed-fps", "60", "--quit-after", "6000"], "WEATHER_TEST_OK"),
    (BASE + ["--script", "tests/debug_overlay_test.gd", "--quit-after", "300", "--max-fps", "60"], "DEVELOPER_TEST_OK"),
    (BASE + ["--script", "tests/hud_test.gd", "--quit-after", "900", "--max-fps", "60"], "HUD_TEST_OK"),
    (BASE + ["--script", "tests/level_test.gd", "--quit-after", "900", "--max-fps", "60"], "LEVEL_TEST_OK"),
    (BASE + ["--script", "tests/sprite_playground_test.gd", "--quit-after", "600", "--max-fps", "60"], "SPRITE_PLAYGROUND_TEST_OK"),
    (BASE + ["--script", "tests/yard_camera_test.gd", "--quit-after", "180", "--max-fps", "60"], "YARD_CAMERA_TEST_OK"),
    (BASE + ["--script", "tests/pixel_scaling_test.gd"], "PIXEL_SCALING_TEST_OK"),
    (BASE + ["--script", "tests/rope_test.gd"], "ROPE_TEST_OK"),
    (BASE + ["--script", "tests/rope_interpolation_test.gd", "--max-fps", "240", "--quit-after", "300"], "ROPE_INTERPOLATION_TEST_OK"),
    (BASE + ["--script", "tests/rope_sweep_test.gd"], "ROPE_SWEEP_TEST_OK"),
    (BASE + ["--script", "tests/rope_lab_test.gd"], "ROPE_LAB_TEST_OK"),
    (BASE + ["--script", "tests/physics_parts_test.gd"], "PHYSICS_PARTS_TEST_OK"),
    (BASE + ["--scene", "res://labs/physics/lab.tscn", "--quit-after", "120"], None),
    (BASE + ["--scene", "res://labs/rope/lab.tscn", "--quit-after", "120"], None),
    ([sys.executable, "tests/test_superscale_cli.py"], None),
    (BASE + ["--scene", "res://labs/pixel_scaling/lab.tscn", "--quit-after", "60", "--", "--self-test"], "PIXEL_LAB_TEST_OK"),
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
