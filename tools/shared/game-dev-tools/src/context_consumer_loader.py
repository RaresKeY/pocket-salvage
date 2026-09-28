"""Pinned execution in consumer globals with isolated caller helpers."""
from pathlib import Path
import importlib.util
import hashlib
import json
import os
import sys
from types import ModuleType


class _NamespaceModule(ModuleType):
    """Let class decorators resolve the actual consumer execution namespace."""
    def __init__(self, name, namespace):
        super().__init__(name)
        self._namespace = namespace

    @property
    def __dict__(self):
        return self._namespace

    def __getattr__(self, name):
        try:
            return self._namespace[name]
        except KeyError:
            raise AttributeError(name) from None


def export_tool(module_name, entry_path, tool_path, namespace):
    entry = Path(entry_path).resolve()
    project = next(p for p in entry.parents if (p / 'tools/game-dev-tools.json').is_file())
    manifest = json.loads((project / 'tools/game-dev-tools.json').read_text())
    names = manifest.get('context_modules', [])
    for name in names:
        if not isinstance(name, str) or not name.isidentifier() or 'src/' + name + '.py' not in manifest['files']:
            raise RuntimeError('Context helper must belong to the pinned closure')
    default = (project / manifest.get('owner', '../game-dev-tools')).resolve()
    shared = Path(os.environ.get('GAME_DEV_TOOLS_ROOT', default))
    if not (shared / tool_path).is_file():
        shared = project / 'tools/shared/game-dev-tools'
    if not (shared / tool_path).is_file():
        raise RuntimeError('Missing shared tool checkout or pinned offline copy')
    for relative, expected in manifest['files'].items():
        file = shared / relative
        if not file.is_file() or hashlib.sha256(file.read_bytes()).hexdigest() != expected:
            raise RuntimeError(f'Shared tool pin mismatch: {relative}; run the reviewed sync procedure')
    path = shared / tool_path
    isolated = {'game_dev_tools_context', *names, *[file.stem for file in path.parent.glob('*.py')]}
    previous = {name: sys.modules.pop(name) for name in isolated if name in sys.modules}
    environment = {key: os.environ.get(key) for key in ['GAME_DEV_TOOLS_PROJECT_ROOT', 'GAME_DEV_TOOLS_WORLD', 'GAME_DEV_TOOLS_CONFIG']}
    os.environ['GAME_DEV_TOOLS_PROJECT_ROOT'] = str(project)
    if manifest.get('config'):
        os.environ['GAME_DEV_TOOLS_CONFIG'] = str(project / manifest['config'])
    if manifest.get('world'):
        os.environ['GAME_DEV_TOOLS_WORLD'] = manifest['world']
    previous_path = list(sys.path)
    sys.path[:0] = [str(path.parent), str(shared / 'src')]
    name = f'_shared_{project.name.replace("-", "_")}_{path.stem}'
    metadata = {key: namespace.get(key) for key in ['__name__', '__file__', '__package__', '__spec__', '__loader__']}
    spec = importlib.util.spec_from_file_location(name, path)
    namespace.update(__name__=name, __file__=str(path), __package__=spec.parent,
                     __spec__=spec, __loader__=spec.loader)
    # Execute once in the adapter's own globals. Copying function objects leaves
    # them bound to another dictionary and breaks legacy RATE/OUT/function edits.
    sys.modules[name] = _NamespaceModule(name, namespace)
    try:
        exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    finally:
        sys.path[:] = previous_path
        for isolated_name in isolated:
            sys.modules.pop(isolated_name, None)
        sys.modules.update(previous)
        for key, value in environment.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
        for key, value in metadata.items():
            if value is None:
                namespace.pop(key, None)
            else:
                namespace[key] = value
    namespace['__shared_origin__'] = str(path)
    namespace['__shared_revision__'] = manifest['revision']
