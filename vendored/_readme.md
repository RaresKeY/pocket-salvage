# Dependency Map

This directory owns third-party dependencies and related provenance. No third-party dependency is vendored yet. Godot and the workstation runner are external prerequisites, not copied dependencies.

When adding a dependency, record its name, purpose, upstream source, pinned version or revision, license, integrity information where applicable, local patches, owning source paths, and update/verification procedure. Link its focused provenance document from this map.

Keep required third-party notices in `THIRD_PARTY_NOTICES.md` at the repository root, separately from this map. Add that file when an actual dependency or asset requires it; no notices or project license are invented by the bootstrap.
