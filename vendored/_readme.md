# Dependency Map

This directory owns dependencies and copied-source provenance. [Rope sources](rope_sources/README.md) preserves White Approach and Plug & Prosper snapshots used to derive the in-repository rope component. These are user-owned project copies, not a newly licensed third-party package. Godot and the workstation runner remain external prerequisites.

When adding a dependency, record its name, purpose, upstream source, pinned version or revision, license, integrity information where applicable, local patches, owning source paths, and update/verification procedure. Link its focused provenance document from this map.

Keep required third-party notices in `THIRD_PARTY_NOTICES.md` at the repository root, separately from this map. Add that file when an actual dependency or asset requires it; no notices or project license are invented by the bootstrap.
