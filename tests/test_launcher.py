"""Exercise source selection without opening a window, audio device or container."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class LauncherTest(unittest.TestCase):
    def test_local_edits_symlink_and_failed_import(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            project = base / 'source project'
            project.mkdir()
            shutil.copy2(ROOT / 'play.sh', project / 'play.sh')
            runtime = base / 'runtime'
            (runtime / 'pulse').mkdir(parents=True)
            desktop = socket.socket(socket.AF_UNIX)
            self.addCleanup(desktop.close)
            desktop.bind(str(runtime / 'pulse/native'))
            binaries = base / 'bin'
            binaries.mkdir()
            log = base / 'calls.jsonl'
            helper = '''#!/usr/bin/env python3
import json, os, pathlib, subprocess, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['LAUNCH_LOG'], 'a') as log:
    log.write(json.dumps([name, args]) + '\\n')
if name == 'git':
    if 'fetch' in args or 'pull' in args: raise SystemExit(99)
    print('true' if '--is-inside-work-tree' in args else ('fixture' if '--short' in args else ' M project.godot'))
elif name == 'runner':
    os.environ['MOUNTED_PROJECT'] = args[args.index('--project') + 1]
    raise SystemExit(subprocess.call(args[args.index('--') + 1:]))
elif name == 'godot':
    project = pathlib.Path(os.environ['MOUNTED_PROJECT'])
    with open(os.environ['LAUNCH_LOG'], 'a') as log:
        log.write(json.dumps(['source', project.joinpath('project.godot').read_text()]) + '\\n')
    if '--import' in args and os.environ.get('FAIL_IMPORT'): raise SystemExit(23)
'''
            for name in ['git', 'podman', 'runner', 'godot']:
                path = binaries / name
                path.write_text(helper)
                path.chmod(0o755)
            link = base / 'play-latest'
            link.symlink_to(project / 'play.sh')
            env = dict(os.environ, PATH=str(binaries) + os.pathsep + os.environ['PATH'],
                       XDG_RUNTIME_DIR=str(runtime), GODOT_PODMAN_RUNNER=str(binaries / 'runner'),
                       LAUNCH_LOG=str(log))
            for source in ['first local scene', 'edited local scene']:
                (project / 'project.godot').write_text(source)
                log.write_text('')
                result = subprocess.run([str(link), '--quit-after', '2'], env=env, cwd=base,
                                        text=True, capture_output=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stderr)
                calls = [json.loads(line) for line in log.read_text().splitlines()]
                self.assertEqual([entry[1] for entry in calls if entry[0] == 'source'], [source, source])
                engines = [entry[1] for entry in calls if entry[0] == 'godot']
                self.assertIn('--import', engines[0])
                self.assertNotIn('--scene', engines[1])
                self.assertEqual(engines[1][-2:], ['--quit-after', '2'])
                self.assertIn(str(project), result.stdout)
                self.assertIn('local changes', result.stdout)
                self.assertFalse(any('fetch' in entry[1] or 'pull' in entry[1] for entry in calls))
            log.write_text('')
            result = subprocess.run([str(link)], env=dict(env, FAIL_IMPORT='1'),
                                    capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 23)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            self.assertEqual(sum(entry[0] == 'godot' for entry in calls), 1)


if __name__ == '__main__':
    unittest.main()
