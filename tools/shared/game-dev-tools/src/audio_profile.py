"""Explicit caller context and output contracts for game-born audio methods."""
from pathlib import Path
import argparse
import math
from game_dev_tools_context import ROOT, settings

PROFILES = settings('audio-synthesis')


def profile(program):
    value = PROFILES.get(program, {})
    if not isinstance(value, dict):
        raise ValueError('Audio program profile must be an object: ' + program)
    return value


def project_path(value):
    path = Path(value)
    if path.is_absolute() or '..' in path.parts or not (ROOT / path).resolve().is_relative_to(ROOT):
        raise ValueError('Audio paths must stay inside the selected project: ' + str(value))
    return ROOT / path


def output_path(program, default='out/audio'):
    return project_path(profile(program).get('output', default))


def require_program(program):
    if program not in PROFILES:
        raise ValueError('Declare audio-synthesis.' + program + ' before generating a preset collection')


def destination(path, program):
    path = Path(path)
    if not path.resolve().is_relative_to(ROOT):
        raise ValueError('Audio output escapes the selected project')
    if path.exists() and not profile(program).get('allow_replace', False):
        raise ValueError('Audio output already exists: ' + str(path))
    return path


def select_output(program, default):
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', help='Project-relative output directory')
    args = parser.parse_args()
    require_program(program)
    return project_path(args.output) if args.output else output_path(program, default.relative_to(ROOT).as_posix())


for program, value in PROFILES.items():
    if not isinstance(value, dict):
        raise ValueError('Audio program profile must be an object: ' + program)
    for key in ('rate', 'duration', 'seconds', 'bpm'):
        if key in value and (isinstance(value[key], bool) or not isinstance(value[key], (int, float)) or not math.isfinite(value[key]) or value[key] <= 0):
            raise ValueError(program + '.' + key + ' must be finite and positive')
    if 'rate' in value and not isinstance(value['rate'], int):
        raise ValueError(program + '.rate must be an integer')
    if 'output' in value:
        project_path(value['output'])
