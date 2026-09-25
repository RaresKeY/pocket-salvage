#!/usr/bin/env python3
"""Publish verified tag artifacts and deploy the identical Web payload to Pages."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time
import urllib.request
import zipfile

from build_all import ROOT, digest


def run(*args, **kwargs):
    return subprocess.check_output(args, text=True, **kwargs).strip()


def api(route, method='GET', data=None):
    args = ['gh', 'api', route, '--method', method]
    if data is not None:
        args += ['--input', '-']
    result = run(*args, input=json.dumps(data) if data is not None else None)
    return json.loads(result) if result else None


def version_tuple(tag):
    if not re.fullmatch(r'v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)', tag):
        raise ValueError('Release tags must be stable vMAJOR.MINOR.PATCH versions.')
    return tuple(map(int, tag[1:].split('.')))


def guard(tag):
    version_tuple(tag)
    version = re.search(r'config/version="([^"]+)"', (ROOT / 'project.godot').read_text())[1]
    if tag != 'v' + version:
        raise ValueError(f'Tag {tag} does not match project version {version}.')
    head = run('git', 'rev-parse', 'HEAD', cwd=ROOT)
    if run('git', 'rev-parse', f'refs/tags/{tag}^{{commit}}', cwd=ROOT) != head:
        raise ValueError('Checkout does not match the release tag.')
    subprocess.run(['git', 'merge-base', '--is-ancestor', head, 'origin/main'], cwd=ROOT, check=True)
    return version, head


def validate_candidate(candidate, version, source):
    manifest = json.loads((candidate / 'manifest.json').read_text())
    if (manifest['version'], manifest['source_commit'], set(manifest['targets']), manifest['reproducibility']) != (
            version, source, {'windows', 'linux', 'web'}, 'two-clean-snapshots-identical'):
        raise ValueError('Candidate identity, targets or repeatability do not match the release.')
    for name, expected in manifest['sha256'].items():
        path = (candidate / name).resolve()
        if not path.is_relative_to(candidate.resolve()) or digest(path) != expected:
            raise ValueError(f'Candidate checksum failed: {name}')
    assets = [candidate / f'pocket-salvage-{version}-{target}.zip' for target in ('windows', 'linux', 'web')]
    for asset in assets:
        with zipfile.ZipFile(asset) as archive:
            if archive.testzip():
                raise ValueError(f'Invalid archive: {asset.name}')
            target = asset.stem.rsplit('-', 1)[1]
            expected = {name[len(target) + 1:]: value for name, value in manifest['sha256'].items() if name.startswith(target + '/')}
            import hashlib
            actual = {item.filename: hashlib.sha256(archive.read(item)).hexdigest() for item in archive.infolist()}
            if actual != expected:
                raise ValueError(f'Archive differs from the platform payload: {asset.name}')
    assets.append(candidate / 'manifest.json')
    sums = candidate / 'SHA256SUMS'
    sums.write_text(''.join(f'{digest(path)}  {path.name}\n' for path in assets))
    return assets + [sums]


def publish(repo, tag, source, assets):
    releases = json.loads(run('gh', 'release', 'list', '--repo', repo, '--limit', '1000', '--json', 'tagName,isDraft,isPrerelease'))
    existing = next((release for release in releases if release['tagName'] == tag), None)
    if existing is None:
        api(f'repos/{repo}/releases', 'POST', {
            'tag_name': tag, 'target_commitish': source, 'name': f'Pocket Salvage {tag}', 'draft': True,
            'body': f'Play at https://{repo.split("/")[0].lower()}.github.io/{repo.split("/")[1]}/\n\n'
                    'Windows, Linux and Web packages from the same tested source. '
                    'Two independent clean exports match byte for byte. '
                    'See manifest.json and SHA256SUMS for source, toolchain and download hashes. '
                    'Windows requires a target-machine playtest; desktop exports are unsigned.\n\n'
                    f'Source: {source}'})
    release = api(f'repos/{repo}/releases/tags/{tag}')
    remote = {asset['name']: asset for asset in release['assets']}
    for path in assets:
        if path.name not in remote:
            if not release['draft']:
                raise ValueError('Published release is incomplete; refusing to mutate its assets.')
            subprocess.run(['gh', 'release', 'upload', tag, str(path), '--repo', repo], check=True)
    # Verify actual remote bytes, including on retries. Never overwrite a differing asset.
    with tempfile.TemporaryDirectory(prefix='release-verify-') as directory:
        subprocess.run(['gh', 'release', 'download', tag, '--repo', repo, '--dir', directory], check=True)
        for path in assets:
            if digest(Path(directory) / path.name) != digest(path):
                raise ValueError(f'Remote asset differs: {path.name}')
    newer = any(not r['isDraft'] and not r['isPrerelease'] and
                re.fullmatch(r'v\d+\.\d+\.\d+', r['tagName']) and version_tuple(r['tagName']) > version_tuple(tag)
                for r in releases)
    if release['draft']:
        api(f'repos/{repo}/releases/{release["id"]}', 'PATCH', {'draft': False, 'make_latest': 'false' if newer else 'true'})
    return not newer


def deploy(repo, candidate, version, source):
    metadata = {'version': version, 'source_commit': source}
    with tempfile.TemporaryDirectory(prefix='pages-') as directory:
        site = Path(directory)
        env = {**os.environ, 'GIT_AUTHOR_NAME': 'github-actions[bot]', 'GIT_COMMITTER_NAME': 'github-actions[bot]',
               'GIT_AUTHOR_EMAIL': '41898282+github-actions[bot]@users.noreply.github.com',
               'GIT_COMMITTER_EMAIL': '41898282+github-actions[bot]@users.noreply.github.com'}
        def git(*args):
            return run('git', *args, cwd=site, env=env)
        git('init', '--quiet')
        git('remote', 'add', 'origin', f'https://github.com/{repo}.git')
        git('config', 'credential.helper', '!gh auth git-credential')
        if git('ls-remote', '--heads', 'origin', 'gh-pages'):
            git('fetch', 'origin', 'gh-pages')
            git('checkout', '-b', 'gh-pages', 'FETCH_HEAD')
        else:
            git('checkout', '--orphan', 'gh-pages')
        for path in site.iterdir():
            if path.name != '.git':
                shutil.rmtree(path) if path.is_dir() else path.unlink()
        shutil.copytree(candidate / 'web', site, dirs_exist_ok=True)
        (site / '.nojekyll').touch()
        (site / 'build.json').write_text(json.dumps(metadata, indent=2) + '\n')
        git('add', '--all')
        if git('status', '--porcelain'):
            git('commit', '-m', f'Deploy Pocket Salvage {version} from {source}')
        commit = git('rev-parse', 'HEAD')
        git('fetch', 'origin')
        git('push', 'origin', 'HEAD:gh-pages')
    # A workflow-token push alone intentionally does not trigger Pages.
    api(f'repos/{repo}/pages/builds', 'POST')
    deadline = time.monotonic() + 600
    while time.monotonic() < deadline:
        status = api(f'repos/{repo}/pages/builds/latest')
        if status.get('commit') == commit:
            if status['status'] == 'errored':
                raise RuntimeError('Pages build failed: ' + str(status.get('error')))
            if status['status'] == 'built':
                break
        time.sleep(10)
    else:
        raise TimeoutError('Pages build did not finish within ten minutes.')
    url = api(f'repos/{repo}/pages')['html_url']
    # Allow the CDN to catch up, then compare every deployed game payload byte.
    for attempt in range(30):
        try:
            with urllib.request.urlopen(url + f'build.json?source={source}&attempt={attempt}', timeout=30) as response:
                if json.load(response) == metadata:
                    break
        except (OSError, ValueError):
            pass
        time.sleep(5)
    else:
        raise RuntimeError('Live Pages metadata did not reach the released version.')
    import hashlib
    for path in (candidate / 'web').iterdir():
        if path.is_file():
            with urllib.request.urlopen(url + path.name + '?source=' + source, timeout=90) as response:
                if hashlib.sha256(response.read()).hexdigest() != digest(path):
                    raise ValueError(f'Live Pages payload differs: {path.name}')
    print('PAGES_OK', url, source)


def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check-tag', action='store_true')
    args = parser.parse_args()
    tag = os.environ['GITHUB_REF_NAME']
    version, source = guard(tag)
    if args.check_tag:
        print('TAG_OK', tag, source)
        return
    repo = os.environ['GITHUB_REPOSITORY']
    candidate = ROOT / 'build' / f'pocket-salvage-{version}'
    assets = validate_candidate(candidate, version, source)
    if publish(repo, tag, source, assets):
        deploy(repo, candidate, version, source)
    else:
        print('Newer stable release exists; keeping its live Pages deployment.')
    shutil.rmtree(candidate)
    print('RELEASE_OK', tag)


if __name__ == '__main__':
    main()
