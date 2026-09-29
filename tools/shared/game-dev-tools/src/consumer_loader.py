"""Compatibility entry loader for revision-pinned shared tool copies."""
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import sys


def export_tool(module_name, entry_path, tool_path, namespace):
    entry = Path(entry_path).resolve()
    project = next((p for p in entry.parents if (p / 'tools/game-dev-tools.json').is_file()), None)
    if project is None:
        raise RuntimeError('Missing tools/game-dev-tools.json consumer manifest')
    manifest = json.loads((project / 'tools/game-dev-tools.json').read_text())
    default = project.parent / 'game-dev-tools'
    shared = Path(os.environ.get('GAME_DEV_TOOLS_ROOT', default))
    if not (shared / tool_path).is_file():
        shared = project / 'tools/shared/game-dev-tools'
    if not (shared / tool_path).is_file():
        raise RuntimeError('Missing shared tool checkout or pinned offline copy')
    for relative, expected in manifest['files'].items():
        file = shared / relative
        if not file.is_file() or hashlib.sha256(file.read_bytes()).hexdigest() != expected:
            raise RuntimeError(f'Shared tool pin mismatch: {relative}; run the reviewed sync procedure')
    previous = {key: os.environ.get(key) for key in ['GAME_DEV_TOOLS_PROJECT_ROOT', 'GAME_DEV_TOOLS_WORLD', 'GAME_DEV_TOOLS_CONFIG']}
    os.environ['GAME_DEV_TOOLS_PROJECT_ROOT'] = str(project)
    config = manifest.get('config')
    if config:
        os.environ['GAME_DEV_TOOLS_CONFIG'] = str(project / config)
    if manifest.get('world'):
        os.environ['GAME_DEV_TOOLS_WORLD'] = manifest['world']
    path = shared / tool_path
    previous_path = list(sys.path)
    # Every pinned shared helper can bind caller state at import time. Isolate
    # the complete declared helper closure, so importing a second project does
    # not reuse another project's alignment (or later family) profile.
    pinned_helpers = {Path(relative).stem for relative in manifest['files']
                      if Path(relative).parent == Path('src') and Path(relative).suffix == '.py'}
    isolated_names = {'game_dev_tools_context', *pinned_helpers, *[file.stem for file in path.parent.glob('*.py')]}
    previous_modules = {name: sys.modules.pop(name) for name in isolated_names if name in sys.modules}
    sys.path[:0] = [str(path.parent), str(shared / 'src')]
    try:
        name = f'_shared_{project.name.replace("-", "_")}_{path.stem}'
        spec = importlib.util.spec_from_file_location(name, path)
        module = importlib.util.module_from_spec(spec)
        sys.modules[name] = module
        spec.loader.exec_module(module)
    finally:
        sys.path[:] = previous_path
        for isolated_name in isolated_names:
            sys.modules.pop(isolated_name, None)
        sys.modules.update(previous_modules)
        for key, value in previous.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
    namespace.update({key: value for key, value in vars(module).items() if not key.startswith('__')})
    namespace['__shared_origin__'] = str(path)
    namespace['__shared_revision__'] = manifest['revision']
