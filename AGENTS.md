# Pocket Salvage: agent instructions

Shared by every contributor's agent. `CLAUDE.md` imports this file. Put machine-specific rules (runners, paths, credentials) in your own untracked notes, not here.

## Every change

1. **Before editing**, read `specs/_readme.md` and the specs that own the files you will touch, and `design/_readme.md` and the design docs for the behaviour you are changing.
2. **With the change, in the same commit**, update both compactly:
   - **Specs** say what the code does now. Replace stale facts rather than appending to them. Set the `Reviewed:` line to the date and the implementation commit reviewed. Keep verification results current.
   - **Design** says why, split in two sections:
     - **User design**: what a person explicitly asked for or approved. Name them (Dale, RaresKeY), date it, and copy their exact words into `prompts/source/` first.
     - **AI-inferred design**: every choice, number or proposal the agent made itself, marked as such, including anything a person has not yet approved.
3. Deferred work goes in `TODO.md`. Exact image or asset generation requests go in `prompts/image/`.

When unsure whether something was asked for or inferred, treat it as inferred.

## Working rules

- Commit straight to `main`. No pull requests or release tags.
- Always fetch before pushing. If `origin/main` moved, rebase unpublished commits onto it, recheck, then push. Never force-push.
- In a conflict, keep everyone's work. If that is impossible or the direction splits, stop and ask the user before resolving or pushing.
- Run the checks for engine changes (`./tests/check`, or `python3 tests/run_checks.py` with a local Godot 4.7). Report real results. Fix failures rather than weakening checks. A bug found gets a test that fails without the fix.
- Keep code DRY and reusable: one rule in one place. Shared art drawing lives in `scripts/art/yard_art.gd`.
- Read `specs/art/_readme.md` before importing or displaying art.

More background: `docs/collaboration.md` and `examples_agents/random-game.md`.
