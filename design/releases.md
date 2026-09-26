# Public delivery

## User design

RaresKeY, 2026-09-25: [exact directive](../prompts/source/public-release.md). Make the repository public, rename it to the game name, keep AGENTS.md and CLAUDE.md ignored and local, build releases on pushed tags, publish artifacts, update a playable GitHub Pages site, and test the work. Report collaborator migration issues. This supersedes the earlier private `random-game` identity and local-only release automation choice.

RaresKeY’s follow-up asks for the public README cleanup after the delivery work (verbatim in the same source record).

RaresKeY, 2026-09-25: [Firebase directive](../prompts/source/firebase-hosting.md). Deploy the latest build once at `pocket-salvage.web.app`, use that URL in GitHub About, and retain the GitHub Pages URL in README.

RaresKeY’s [follow-up](../prompts/source/firebase-hosting.md) requests refreshing the stale README.

RaresKeY’s [next request](../prompts/source/firebase-hosting.md) authorizes a new GitHub build/release and deployment to Firebase.

RaresKeY’s latest [deployment directive](../prompts/source/firebase-hosting.md) requests updating both hosted sites with the new wind/UI changes.

RaresKeY’s [marketing refresh request](../prompts/source/marketing-refresh.md) asks to remake the marketing PNG and update the stale README.

RaresKeY, 2026-09-26: [requested updating GitHub builds and Firebase](../prompts/source/firebase-hosting.md) after approving the Blood Moon tint defaults.

## AI-inferred design

Use `pocket-salvage` as the repository slug and `v0.1.3` as the first published automated patch release (`v0.1.2` exposed a draft-lookup defect and remains an unchanged historical tag). Test main pushes; stable `vMAJOR.MINOR.PATCH` tags must match the project version and belong to main. Tagged releases test and export Windows/Linux/Web twice, using the existing reproducible packager. Keep macOS outside automated releases until target-machine validation is available.

Use checksum-pinned official Godot 4.7 downloads on an ephemeral Ubuntu runner, Python and shell, with bounded jobs and no dependency installation through JavaScript tooling. Main checks download only the editor; tags also fetch templates. This avoids downloading the 5 GB general-purpose CI image on every push. Hosted headless checks prove behavior/export consistency, not hardware rendering. Local engine work retains the shared managed runner.

Release ZIPs and manifests belong to GitHub Releases. A separate `gh-pages` deployment branch holds the extracted Web package, `.nojekyll`, and source/version metadata; it never merges into main. Request a Pages build explicitly after pushing because workflow-token pushes alone do not trigger Pages. Preserve deployment history without force-pushing. Deploy only the newest stable release and verify the live metadata and payload. Local candidates are removed after verified publication.

The original delivery pass kept the checkout folder unchanged. RaresKeY’s later [controller/mobile request](../prompts/source/controller-mobile.md) explicitly asks to rename it too; the main checkout becomes `pocket-salvage` and linked-worktree pointers are repaired. GitHub redirects the former repository URL; contributors should update origin and preserve their agent files before pulling the removal commit. Existing history remains public, including old agent-file revisions. Portable contributor rules remain committed under docs and examples_agents.

Public README presentation: lead with Play/Download, a real gameplay capture and keyboard controls; link to contributor/spec/build details instead of reproducing the internal project map. Keep the selected promotional capture in `marketing/`, outside Godot’s import tree.

Firebase uses a dedicated `pocket-salvage` project/site and the existing checksum-verified v0.1.5 Web release. Keep this a manual snapshot, leave tag-triggered GitHub Pages delivery in place, and label both destinations clearly. Host only the extracted release payload plus version/source metadata, revalidate cached files, and keep deployment artifacts/logs ignored.

README refresh: summarize the published v0.1.5 audio/performance behavior, distinguish the manual Firebase snapshot from automatically updated Pages, and document actual desktop/source launch prerequisites. Keep detailed profiling evidence in its existing review.

Use v0.1.6 for the requested release, including Dale’s weather implementation that arrived before publication. Run the existing tag workflow, then deploy its verified Web package to Firebase manually.

Use v0.1.7 for curved wind, sparse dust, square pixel UI, bundled Tiny5 and pause volume controls. Run tagged delivery, then deploy the same verified Web payload to Firebase. Local Developer options remain excluded from exported UI.

Marketing refresh: use fresh, unmodified 1280×720 native gameplay and level-grid captures from `3557892`, with the existing game art and UI. Keep gameplay as the hero, place the grid beside its explanation, and explicitly distinguish source-only levels from hosted v0.1.7. This request changes documentation and promotional captures, not releases or deployments.

Use v0.1.8 for the current five-level game, Storm/twister, Blood Moon defaults, skyline/wind refinements and mobile overlay. Run the existing tagged Windows/Linux/Web pipeline and deploy its verified Web ZIP to Firebase.

Release README refresh: describe all five published levels and Storm’s initial calm period; retain existing marketing images and label their older four-level view.

## Audio balance release, 2026-09-26

### User design

RaresKeY requests commit/push, a build/release tag and Firebase sync after the reward adjustment ([exact words](../prompts/source/reward-audio-release.md)).

### AI-inferred design

Use patch version v0.1.9 for the softer wind and quieter correct-delivery chime. Use the existing tagged Windows/Linux/Web workflow, then deploy its checksum-verified Web payload to Firebase and verify the live files.
