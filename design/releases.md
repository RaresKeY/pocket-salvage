# Public delivery

## User design

RaresKeY, 2026-09-25: [exact directive](../prompts/source/public-release.md). Make the repository public, rename it to the game name, keep AGENTS.md and CLAUDE.md ignored and local, build releases on pushed tags, publish artifacts, update a playable GitHub Pages site, and test the work. Report collaborator migration issues. This supersedes the earlier private `random-game` identity and local-only release automation choice.

## AI-inferred design

Use `pocket-salvage` as the repository slug and `v0.1.3` as the first published automated patch release (`v0.1.2` exposed a draft-lookup defect and remains an unchanged historical tag). Test main pushes; stable `vMAJOR.MINOR.PATCH` tags must match the project version and belong to main. Tagged releases test and export Windows/Linux/Web twice, using the existing reproducible packager. Keep macOS outside automated releases until target-machine validation is available.

Use checksum-pinned official Godot 4.7 downloads on an ephemeral Ubuntu runner, Python and shell, with bounded jobs and no dependency installation through JavaScript tooling. Main checks download only the editor; tags also fetch templates. This avoids downloading the 5 GB general-purpose CI image on every push. Hosted headless checks prove behavior/export consistency, not hardware rendering. Local engine work retains the shared managed runner.

Release ZIPs and manifests belong to GitHub Releases. A separate `gh-pages` deployment branch holds the extracted Web package, `.nojekyll`, and source/version metadata; it never merges into main. Request a Pages build explicitly after pushing because workflow-token pushes alone do not trigger Pages. Preserve deployment history without force-pushing. Deploy only the newest stable release and verify the live metadata and payload. Local candidates are removed after verified publication.

Keep the local checkout folder unchanged so existing processes and paths keep working. GitHub redirects the former repository URL; contributors should update origin and preserve their agent files before pulling the removal commit. Existing history remains public, including old agent-file revisions. Portable contributor rules remain committed under docs and examples_agents.
