#!/usr/bin/env python3
"""Install checksum-pinned official Godot downloads on an ephemeral hosted runner."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import urllib.request
import zipfile

RELEASE = 'https://github.com/godotengine/godot-builds/releases/download/4.7-stable/'
EDITOR = ('Godot_v4.7-stable_linux.x86_64.zip', '0b1a6c54c2c619c12e169fe9241edda4b81080b519451cec2984bf0d2c6cb73c')
TEMPLATES = ('Godot_v4.7-stable_export_templates.tpz', '9714459dc071907c0f3d5f17d608faf69e7cda21331fc5d39c4503ffa4e99eec')


def download(directory, pinned):
    name, expected = pinned
    path = directory / name
    with urllib.request.urlopen(RELEASE + name, timeout=120) as response, path.open('wb') as output:
        shutil.copyfileobj(response, output)
    with path.open('rb') as source:
        if hashlib.file_digest(source, 'sha256').hexdigest() != expected:
            path.unlink()
            raise ValueError(f'Official download checksum mismatch: {name}')
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--templates', action='store_true')
    args = parser.parse_args()
    if os.environ.get('GITHUB_ACTIONS') != 'true':
        raise SystemExit('CI setup is restricted to GitHub Actions; use the shared runner locally.')
    root = Path(os.environ['RUNNER_TEMP']) / 'pocket-salvage-godot'
    root.mkdir()
    binary = root / 'bin'
    binary.mkdir()
    archive = download(root, EDITOR)
    with zipfile.ZipFile(archive) as source:
        with source.open('Godot_v4.7-stable_linux.x86_64') as stream, (binary / 'godot').open('wb') as output:
            shutil.copyfileobj(stream, output)
    (binary / 'godot').chmod(0o755)
    archive.unlink()
    templates = root / 'share/godot/export_templates/4.7.stable'
    if args.templates:
        templates.mkdir(parents=True)
        archive = download(root, TEMPLATES)
        with zipfile.ZipFile(archive) as source:
            for name in ('linux_release.x86_64', 'windows_release_x86_64.exe', 'web_nothreads_release.zip', 'version.txt'):
                with source.open('templates/' + name) as stream, (templates / name).open('wb') as output:
                    shutil.copyfileobj(stream, output)
        (templates / 'linux_release.x86_64').chmod(0o755)
        archive.unlink()
    with Path(os.environ['GITHUB_PATH']).open('a') as output:
        output.write(str(binary) + '\n')
    with Path(os.environ['GITHUB_ENV']).open('a') as output:
        output.write(f'GODOT_EXPORT_TEMPLATES={templates}\nXDG_DATA_HOME={root / "share"}\n')
    print('CI_TOOLCHAIN_READY official Godot 4.7; pinned downloads verified')


if __name__ == '__main__':
    main()
