"""Extend the pinned loader with declared helper-module context isolation."""
from pathlib import Path
import importlib.util
import json
import os
import sys


def export_tool(module_name, entry_path, tool_path, namespace):
    entry = Path(entry_path).resolve()
    project = next(p for p in entry.parents if (p / 'tools/game-dev-tools.json').is_file())
    manifest = json.loads((project / 'tools/game-dev-tools.json').read_text())
    names = manifest.get('context_modules', [])
    for name in names:
        if not isinstance(name, str) or not name.isidentifier() or 'src/' + name + '.py' not in manifest['files']:
            raise RuntimeError('Context helper must belong to the pinned closure')
    previous = {name: sys.modules.pop(name) for name in names if name in sys.modules}
    previous_root = os.environ.get('GAME_DEV_TOOLS_ROOT')
    if previous_root is None:
        os.environ['GAME_DEV_TOOLS_ROOT'] = str((project / manifest.get('owner', '../game-dev-tools')).resolve())
    try:
        path = Path(__file__).with_name('consumer_loader.py')
        spec = importlib.util.spec_from_file_location('_pinned_base_loader', path)
        base = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(base)
        base.export_tool(module_name, entry_path, tool_path, namespace)
    finally:
        for name in names:
            sys.modules.pop(name, None)
        sys.modules.update(previous)
        if previous_root is None:
            os.environ.pop('GAME_DEV_TOOLS_ROOT', None)
        else:
            os.environ['GAME_DEV_TOOLS_ROOT'] = previous_root
