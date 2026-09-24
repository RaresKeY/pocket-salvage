#!/usr/bin/env python3
"""Export a clean Git snapshot using the shared Godot Podman toolchain."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
import time
import zipfile
import platform
import zlib

ROOT = Path(__file__).resolve().parents[2]
TARGETS = {
    'linux': ('Linux', 'pocket-salvage.x86_64', 'linux_release.x86_64'),
    'windows': ('Windows', 'pocket-salvage.exe', 'windows_release_x86_64.exe'),
    'web': ('Web', 'index.html', 'web_nothreads_release.zip'),
    'macos': ('macOS', 'pocket-salvage.zip', 'macos.zip'),
}


def command(args, **kwargs):
    return subprocess.check_output(args, text=True, **kwargs).strip()


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def zip_files(destination, files, epoch):
    timestamp = time.gmtime(max(315532800, epoch))[:6]
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data, mode in sorted(files):
            item = zipfile.ZipInfo(name, timestamp)
            item.create_system = 3
            item.external_attr = mode << 16
            item.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(item, data)


def inside(args):
    epoch = int(os.environ['SOURCE_DATE_EPOCH'])
    project = ROOT / 'project.godot'
    text = project.read_text()
    text = re.sub(r'run/main_scene=.*', 'run/main_scene="res://labs/salvage/lab.tscn"', text)
    if "macos" in args.targets:
        text = text.replace("[rendering]", "[rendering]\ntextures/vram_compression/import_etc2_astc=true")
    project.write_text(text)
    (ROOT / "output").mkdir()
    (ROOT / "output/.gdignore").touch()
    # Archive mtimes and generated metadata must not depend on invocation time.
    for path in ROOT.rglob('*'):
        if path.is_file():
            os.utime(path, (epoch, epoch))
    engine = command(['godot', '--version'])
    templates = Path('/opt/godot-export-templates/4.7.stable')
    info = {'engine': engine, 'engine_sha256': digest(Path(shutil.which('godot'))), 'python': platform.python_version(), 'zlib': zlib.ZLIB_VERSION, 'templates': {key: digest(templates / TARGETS[key][2]) for key in args.targets}}
    subprocess.run(['godot', '--headless', '--editor', '--import', '--quit'], check=True)
    for key in args.targets:
        preset, filename, _ = TARGETS[key]
        target = ROOT / 'output' / key
        target.mkdir(parents=True)
        subprocess.run(['godot', '--headless', '--export-release', preset, str(target / filename)], check=True)
        if key == 'macos':
            archive = target / filename
            with zipfile.ZipFile(archive) as source:
                entries = [(item.filename, source.read(item), item.external_attr >> 16) for item in source.infolist()]
            zip_files(archive, entries, epoch)
    (ROOT / 'toolchain.json').write_text(json.dumps(info, indent=2) + '\n')


def build_once(destination, args, source, epoch, runner):
    with tempfile.TemporaryDirectory(prefix='snapshot-', dir=ROOT / 'build') as directory:
        snapshot = Path(directory)
        archive = subprocess.check_output(['git', 'archive', source], cwd=ROOT)
        with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
            stream.extractall(snapshot, filter='data')
        subprocess.run([str(runner), 'run', '--project', str(snapshot), '--image', args.image,
                        '--purpose', 'reproducible-prototype-export', '--display', 'none',
                        '--env', f'SOURCE_DATE_EPOCH={epoch}', '--env', 'TZ=UTC',
                        '--', 'python3', 'tools/build/build_all.py', '--inside', '--targets', *args.targets], check=True)
        toolchain = json.loads((snapshot / 'toolchain.json').read_text())
        shutil.copytree(snapshot / 'output', destination)
    return toolchain


def hashes(directory):
    return {str(path.relative_to(directory)): digest(path) for path in sorted(directory.rglob('*')) if path.is_file() and path.name != '.gdignore'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--targets', nargs='+', choices=TARGETS, default=list(TARGETS))
    parser.add_argument('--verify', action='store_true', help='rebuild a second clean snapshot and require identical exported bytes')
    parser.add_argument('--image', default='localhost/godot-podman:4.7')
    parser.add_argument('--inside', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.inside:
        inside(args)
        return
    if command(['git', 'status', '--porcelain'], cwd=ROOT):
        raise SystemExit('Build requires a clean committed checkout (including untracked source files).')
    source = command(['git', 'rev-parse', 'HEAD'], cwd=ROOT)
    epoch = int(command(['git', 'show', '-s', '--format=%ct', source], cwd=ROOT))
    version = re.search(r'config/version="([^"]+)"', (ROOT / 'project.godot').read_text()).group(1)
    runner = Path(os.environ.get('GODOT_PODMAN_RUNNER', ROOT.parent / 'godot-podman/bin/godot-podman')).resolve()
    if not runner.is_file():
        raise SystemExit('Set GODOT_PODMAN_RUNNER to the shared godot-podman wrapper.')
    (ROOT / 'build').mkdir(exist_ok=True)
    (ROOT / 'build/.gdignore').touch()
    final = ROOT / 'build' / f'pocket-salvage-{version}'
    if final.exists():
        raise SystemExit(f'Candidate already exists; preserve or remove that exact generated directory before rebuilding: {final}')
    with tempfile.TemporaryDirectory(prefix='candidate-', dir=ROOT / 'build') as directory:
        staging = Path(directory) / 'candidate'
        toolchain = build_once(staging, args, source, epoch, runner)
        payload = hashes(staging)
        if args.verify:
            repeated = Path(directory) / 'repeat'
            other_toolchain = build_once(repeated, args, source, epoch, runner)
            if payload != hashes(repeated) or toolchain != other_toolchain:
                changed = sorted(key for key in payload.keys() | hashes(repeated).keys() if payload.get(key) != hashes(repeated).get(key))
                raise SystemExit(f'Reproducibility check failed: {changed}')
        for key in args.targets:
            if key == 'macos':
                continue  # Native exporter already supplies a normalized app archive.
            folder = staging / key
            zip_files(staging / f'pocket-salvage-{version}-{key}.zip',
                      [(str(path.relative_to(folder)), path.read_bytes(), path.stat().st_mode) for path in folder.rglob('*') if path.is_file()], epoch)
        manifest = {'version': version, 'source_commit': source, 'source_date_epoch': epoch,
                    'startup_scene': 'res://labs/salvage/lab.tscn', 'image_reference': args.image,
                    'toolchain': toolchain, 'packager': {'python': platform.python_version(), 'zlib': zlib.ZLIB_VERSION}, 'targets': args.targets,
                    'reproducibility': 'two-clean-snapshots-identical' if args.verify else 'not-compared',
                    'sha256': hashes(staging)}
        (staging / 'manifest.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
        staging.rename(final)
    print(f'BUILD_OK {final}')


if __name__ == '__main__':
    main()
