"""Build the CC0 event cues in assets/audio/sfx/events/ from the downloaded source packs. Needs ffmpeg.

Usage: python3 tools/audio/build_event_cues.py <sources>
<sources> holds the unzipped packs listed in vendored/cc0-event-audio.md:
  kenney_impact-sounds/, 100-CC0-SFX_0/, sfx_100_v2/ and wind_woosh_loop.ogg.
"""
from pathlib import Path
import subprocess
import sys

from audio_profile import ROOT, profile, output_path, destination, require_program
CONFIG = profile('odd-event-cues')
OUT = output_path('odd-event-cues')
CUES = CONFIG.get('cues', {})


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    require_program('odd-event-cues')
    sources = Path(sys.argv[1]).resolve()
    for cue, files in CUES.items():
        for name, source, filters in files:
            if not (sources / source).resolve().is_relative_to(sources):
                raise ValueError('Cue source escapes the supplied recording root')
            destination(OUT / cue / name, 'odd-event-cues')
    for cue, files in CUES.items():
        (OUT / cue).mkdir(parents=True, exist_ok=True)
        for name, source, filters in files:
            args = ["ffmpeg", "-v", "error", "-y", "-i", str(sources / source)]
            args += ["-af", filters, "-c:a", "libvorbis", "-q:a", "5"] if filters else ["-c", "copy"]
            subprocess.run([*args, str(OUT / cue / name)], check=True)
            print(f"{cue}/{name} <- {source}")


if __name__ == "__main__":
    main()
