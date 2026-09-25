"""Copy sprites rendered by Bitwright's render-game into assets/bitwright/ under game names, then make the 8x copies.

    npx tsx tools/sprite/render-game.ts --set scrapyard --out <render dir>     (in the Bitwright repo)
    python3 tools/pixel_art/import_bitwright.py <render dir> [key ...]

render-game names files by set key (`gull_1.png`); the game names them by role (`critter_gull_01.png`).
Only keys listed in NAMES are imported (or just the keys named on the command line), and existing files are never replaced.
"""
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NAMES = {
    "moon": "backdrop_moon",
    "cloud": "backdrop_cloud",
    "skyline": "backdrop_skyline_tile",
    "heap": "backdrop_junk_heap",
    "floodlight": "yard_floodlight",
    "beacon": "yard_beacon",
    "smoke": "fx_smoke",
    "gull": "critter_gull",
    "crow": "critter_crow",
    "rat": "critter_rat",
    "gull_perched": "critter_gull_perched",
    "claw": "crane_claw",
    "stand": "tool_stand",
}


def main(render_dir: Path, only: list[str]) -> None:
    manifest = json.loads((render_dir / "sprites.json").read_text())
    made = []
    for key, name in NAMES.items():
        if only and key not in only:
            continue
        frames = manifest[key]["frames"]
        sources = [render_dir / f"{key}.png"] if frames == 1 else [render_dir / f"{key}_{i}.png" for i in range(1, frames + 1)]
        targets = [f"{name}.png"] if frames == 1 else [f"{name}_{i:02d}.png" for i in range(1, frames + 1)]
        for source, target in zip(sources, targets):
            original = ROOT / "assets" / "bitwright" / target
            if original.exists():
                raise SystemExit(f"{original} already exists; remove it first to re-import")
            shutil.copyfile(source, original)
            subprocess.run(["godot", "--headless", "--path", str(ROOT), "--script", "tools/pixel_art/superscale.gd", "--",
                            "--input", f"assets/bitwright/{target}", "--factor", "8", "--output", f"assets/bitwright_8x/{target}"],
                           cwd=ROOT, check=True, capture_output=True)
            made.append(target)
    print(f"imported {len(made)} files: {', '.join(made)}")


if __name__ == "__main__":
    main(Path(sys.argv[1]), sys.argv[2:])
