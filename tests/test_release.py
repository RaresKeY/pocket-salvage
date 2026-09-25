"""Release safety checks without engine execution, network access or credentials."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools/build'))
import build_all
import publish_release as release


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def candidate(self):
        for target in ('windows', 'linux', 'web'):
            directory = self.root / target
            directory.mkdir()
            (directory / 'payload').write_bytes((target + ' game').encode())
            build_all.zip_files(self.root / f'pocket-salvage-1.2.3-{target}.zip',
                                [('payload', (directory / 'payload').read_bytes(), 0o100755)], 1700000000)
        manifest = {'version': '1.2.3', 'source_commit': 'source', 'targets': ['windows', 'linux', 'web'],
                    'reproducibility': 'two-clean-snapshots-identical', 'sha256': build_all.hashes(self.root)}
        (self.root / 'manifest.json').write_text(json.dumps(manifest))
        return manifest

    def test_valid_candidate_and_checksums(self):
        self.candidate()
        assets = release.validate_candidate(self.root, '1.2.3', 'source')
        self.assertEqual(len(assets), 5)
        self.assertEqual(len((self.root / 'SHA256SUMS').read_text().splitlines()), 4)

    def test_tampered_payload_and_wrong_identity_are_rejected(self):
        self.candidate()
        with self.assertRaises(ValueError):
            release.validate_candidate(self.root, '1.2.3', 'other-source')
        (self.root / 'web/payload').write_text('changed')
        with self.assertRaises(ValueError):
            release.validate_candidate(self.root, '1.2.3', 'source')

    def test_archive_must_match_payload_even_if_manifest_has_both_hashes(self):
        manifest = self.candidate()
        archive = self.root / 'pocket-salvage-1.2.3-web.zip'
        build_all.zip_files(archive, [('payload', b'wrong game', 0o100644)], 1700000000)
        manifest['sha256'][archive.name] = build_all.digest(archive)
        (self.root / 'manifest.json').write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, 'Archive differs'):
            release.validate_candidate(self.root, '1.2.3', 'source')

    def test_unverified_and_path_escape_manifest_are_rejected(self):
        manifest = self.candidate()
        manifest['reproducibility'] = 'not-compared'
        (self.root / 'manifest.json').write_text(json.dumps(manifest))
        with self.assertRaises(ValueError):
            release.validate_candidate(self.root, '1.2.3', 'source')
        manifest['reproducibility'] = 'two-clean-snapshots-identical'
        manifest['sha256']['../outside'] = 'ignored'
        (self.root / 'manifest.json').write_text(json.dumps(manifest))
        with self.assertRaises(ValueError):
            release.validate_candidate(self.root, '1.2.3', 'source')

    def test_canonical_stable_tags_only(self):
        self.assertGreater(release.version_tuple('v1.10.0'), release.version_tuple('v1.9.9'))
        for tag in ('1.2.3', 'v01.2.3', 'v1.2', 'v1.2.3-rc1', 'v1.2.3\n', 'v1.2.3;echo bad'):
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                release.version_tuple(tag)

    def test_tag_must_match_project_and_main_ancestry(self):
        def git(*args):
            return release.run('git', *args, cwd=self.root)
        git('init', '-b', 'main')
        git('config', 'user.name', 'Fixture')
        git('config', 'user.email', 'fixture@example.invalid')
        (self.root / 'project.godot').write_text('config/version="1.2.3"\n')
        git('add', '.')
        git('commit', '-m', 'Fixture')
        git('branch', 'origin/main')
        git('tag', 'v1.2.3')
        with patch.object(release, 'ROOT', self.root):
            self.assertEqual(release.guard('v1.2.3')[0], '1.2.3')
            with self.assertRaises(ValueError):
                release.guard('v1.2.4')
            git('checkout', '-b', 'unmerged')
            (self.root / 'project.godot').write_text('config/version="1.2.4"\n')
            git('commit', '-am', 'Unmerged')
            git('tag', 'v1.2.4')
            with self.assertRaises(subprocess.CalledProcessError):
                release.guard('v1.2.4')


if __name__ == '__main__':
    unittest.main()
