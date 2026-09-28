"""Explicit project context for reusable generators; no caller-file inference."""
from pathlib import Path
import json
import os

ROOT = Path(os.environ.get('GAME_DEV_TOOLS_PROJECT_ROOT', Path.cwd())).resolve()
CONFIG_PATH = os.environ.get('GAME_DEV_TOOLS_CONFIG')
CONFIG = json.loads(Path(CONFIG_PATH).read_text()) if CONFIG_PATH else {}
if not isinstance(CONFIG, dict):
    raise ValueError('Tool configuration must be a JSON object')
WORLD = os.environ.get('GAME_DEV_TOOLS_WORLD', str(CONFIG.get('world', ROOT.name)))


def settings(family):
    value = CONFIG.get(family, {})
    if not isinstance(value, dict):
        raise ValueError(f'{family} settings must be an object')
    return value


def relative_path(value):
    path = Path(value)
    if path.is_absolute() or '..' in path.parts:
        raise ValueError('Configured paths must stay inside the selected project')
    return ROOT / path
