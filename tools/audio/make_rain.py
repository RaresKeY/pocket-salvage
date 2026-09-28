#!/usr/bin/env python3
"""Compatibility entry point; implementation is pinned in game-dev-tools."""
from pathlib import Path as _Path
import importlib.util as _import

_entry = _Path(__file__).resolve()
_project = next(p for p in _entry.parents if (p / 'tools/game-dev-tools.json').is_file())
_path = _project / 'tools/shared/game-dev-tools/src/context_consumer_loader.py'
_spec = _import.spec_from_file_location('_game_dev_tools_loader', _path)
_loader = _import.module_from_spec(_spec)
_spec.loader.exec_module(_loader)
_loader.export_tool(__name__, __file__, 'tools/audio-synthesis/src/pocket-salvage/tools/audio/make_rain.py', globals())

if __name__ == '__main__':
    raise SystemExit(main())
