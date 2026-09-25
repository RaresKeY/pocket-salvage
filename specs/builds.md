# Standalone prototype builds

Reviewed: 2026-09-25. Implementation: public-delivery change based on `815c9b9`; final verification revision recorded below after deployment.

The user requested a versioned standalone prototype and reproducible builds. Export presets cover Linux x86_64, Windows x86_64, Web (single-thread WebAssembly) and unsigned macOS universal. Mobile input and signing are outside this prototype. Platform availability is separate from tested runtime support: Linux and Web can be exercised on the development workstation; Windows and macOS require target-machine playtests.

Run `python3 tools/build/build_all.py --verify` from clean committed source. The script uses only Python's standard library and the shared `godot-podman` runner (sibling checkout, or `GODOT_PODMAN_RUNNER`). It does not install an engine or templates. `--targets linux web` narrows the build; default builds all four. `--image` chooses an already-present toolchain image.

Each build extracts `git archive HEAD` into an isolated temporary snapshot, stamps all source mtimes from the commit timestamp (`SOURCE_DATE_EPOCH`), and changes only that snapshot's startup to `labs/salvage/lab.tscn`. Text scenes remain text in the package: Godot 4.7 binary scene conversion synthesizes node IDs that vary between clean exports. Disabling that conversion in the snapshot removes this source of differing bytes. The export feature `standalone` suppresses lab navigation. The project version is the source of the displayed/released version. Source and editor startup are not rewritten. All resources are exported because layout entries load textures by constructed paths; static dependency discovery alone misses those textures.

The output is ignored `build/pocket-salvage-<version>/`: runnable platform directories, Linux/Windows/Web ZIP packages, the normalized macOS application ZIP, and `manifest.json`. The manifest records full source revision, epoch, Godot version and executable SHA256, exact export-template SHA256 digests, Python/zlib versions, selected targets and every output SHA256. `--verify` exports twice from independent snapshots and fails unless all exported bytes and toolchain fingerprints match. ZIP order, timestamps and Unix modes are normalized. A manifest without `--verify` explicitly says `not-compared`; repeatability is not inferred from a successful export. Compare with the same engine/templates and Python/zlib toolchain; this does not claim that rebuilding Godot itself is reproducible.

Existing candidate paths are refused so retained artifacts are never silently overwritten. Temporary snapshots are removed on success or failure. Keep the current requested candidate locally; remove only that exact generated directory when replacing it. The build tool itself performs no publishing. The user explicitly requested a GitHub release on 2026-09-25, allowing a release tag for v0.1.1 and Windows/Linux/Web asset uploads. That release used local builds. The later public-delivery request enables the tag workflow below. Verify remote asset hashes/sizes, then remove the generated local candidate. No itch upload, signing or license change is included.

Launch Linux's `linux/pocket-salvage.x86_64` beside its PCK. Serve `web/` over HTTP (for example `python3 -m http.server --directory build/pocket-salvage-0.1.0/web 8000`) and open its `index.html`; file URLs cannot load WebAssembly reliably. Windows requires the EXE and neighboring PCK together. macOS is unsigned and unnotarized; its archive is an export candidate, not a verified public distribution.

Verification: export each preset, compare independent snapshot outputs with `--verify`, then exercise the Linux and Web candidates. Engine behavior changes still require `./tests/check`; headless export success is not hardware-rendering or gameplay evidence.

2026-09-24 validation: v0.1.0 candidate source `9c188d0` passed the four-target `--verify` comparison with `two-clean-snapshots-identical` in its manifest. The packaged Linux executable started without engine errors on NVIDIA RTX2080Ti through the managed runner/Gamescope. Firefox156.0.1 loaded the packaged Web build; keyboard start, movement, reeling, magnet toggle and pause produced the expected ready/running/paused captures and no game-console errors. Windows and macOS were exported and compared, but not executed. The complete engine suite and five-size source GPU captures passed independently. Later documentation commits do not change this candidate’s recorded source identity.

2026-09-25 v0.1.1 validation: source `d7a7b4624d09c85fe9b67d80980499bb68cd4922` passed local `--targets windows linux web --verify`, with byte-identical output/toolchain hashes across two clean exports and valid ZIP CRCs. All three ZIPs and `manifest.json` have a separate `SHA256SUMS` download. Exported Linux started and exited normally on NVIDIA RTX 2080 Ti Compatibility. Firefox loaded the Web package over loopback HTTP and passed actual keyboard start/move/reel/grip/pause/restart interactions with no console errors. A test-only Web Audio analyser upstream of a muted destination measured nonzero music, zero after M mute, nonzero grip SFX with music off, and nonzero restored music. No exported file was modified for that check. Browser renderer identification was the privacy-masked NVIDIA WebGL string, not an exact adapter measurement. Windows was built and compared but not executed. Subjective speaker listening remains unverified. The source suite passed again after incorporating `9883433`; [audio/UI review](../docs/audio-ui-review.md) records source-level visual and mixer evidence. Release assets are published from the recorded source commit, independently of later documentation-only commits.

## Public automation

`.github/workflows/delivery.yml` runs release unit tests and the complete headless engine suite on main pushes. Stable `vMAJOR.MINOR.PATCH` tags additionally require an exact `project.godot` version match, tag/checkout equality and ancestry on `origin/main`. They export Windows/Linux/Web twice and compare payload/toolchain hashes before publishing. Jobs have 15-minute check and 25-minute release limits; releases serialize without cancelling a running publication. There are no builds on ordinary main pushes and no macOS CI export.

Hosted jobs use the digest-pinned Godot 4.7 CI image, Python and shell, with container-installed Python/fontconfig (and GitHub CLI for release). `--ci-direct` is restricted to GitHub Actions; locally the packager still uses the shared Godot Podman wrapper. `GODOT_EXPORT_TEMPLATES` points to the hosted image’s template location. The manifest records actual engine/template/Python/zlib versions and hashes; apt-installed glue is not asserted to be bit-identical across future job runs. Headless CI is not hardware-renderer evidence.

`publish_release.py` checks candidate identity, every manifest hash, archive CRCs and exact ZIP/payload agreement. It uploads ZIPs, manifest and SHA256SUMS to a draft, downloads and compares their bytes, then publishes. Retries verify existing assets and refuse to replace differing published bytes. Older stable versions may publish downloads but do not replace a newer live release.

Pages serves the extracted Web payload from `gh-pages` at https://rareskey.github.io/pocket-salvage/. Deployment adds `.nojekyll` and `build.json` with version/source identity. The branch preserves its deployment history and is never merged into main. A Pages build is explicitly requested through the API after the push; workflow-token pushes do not trigger it by themselves. Publication polls the matching build, waits for live metadata and compares every hosted game file’s SHA256. Only then is the local candidate removed. A failed deployment leaves the release available; rerun the failed release job to retry. Workflow jobs retain no extra Actions artifact archives.

Release procedure: commit a new project version with matching specs/design; fetch/rebase/recheck and push main; create the matching annotated version tag, fetch once more, verify its source is on current main, and push that tag. Never move a published tag. For example, after preparing version `0.1.2`:

```sh
git fetch origin
git rebase origin/main
git push origin main
git tag -a v0.1.2 -m 'Pocket Salvage 0.1.2'
git fetch origin
git merge-base --is-ancestor 'v0.1.2^{commit}' origin/main
git push origin v0.1.2
```

The Pages source must be configured once to `gh-pages` at `/`. Existing release v0.1.1 assets remain intact. Public visibility does not add a project license.

2026-09-25 public-delivery preflight: six offline release-contract tests and the complete managed engine suite passed (`CHECKS_OK`). Reachable Git history (1,543 named objects) had no matches for the inspected credential patterns or sensitive filenames; this is a bounded scan, not a universal secrets guarantee. Repository rename/public visibility and Dale’s unchanged write grant were confirmed through the GitHub API. Hosted delivery and live-browser evidence are recorded after the first tag run.
