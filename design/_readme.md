# Design Map

Design captures evolving intent. Every design document distinguishes explicit **User design** from **AI-inferred design**; name individual contributors when known and date the entry. Exact human words go in [prompts/source/](../prompts/source/README.md) first; design cites them. These documents are not implementation claims.

| Document | Scope | Read when |
|---|---|---|
| [Game direction](game.md) | Pocket Salvage's crane, scrap and timed sorting loop | Extending the playable design |
| [Rope module](rope.md) | Copied source foundations and reusable crane rope | Changing the rope or its showcase |
| [Object subsystem](physics.md) | Reusable collision and visual masking capabilities; concrete objects deferred | Designing physical objects or occlusion |
| [Scene arrangement](scene_preview.md) | Teammate art arranged for local inspection | Revising the scrapyard composition |
| [Visual direction](visual-style.md) | Art-direction decisions required before image generation | Producing mockups, prompts, assets, or UI |
| [Pixel-scaling experiment](pixel_scaling_lab.md) | Integer scaling tool, art conventions, and diagnostic showcase | Extending the technical art lab |
| [Collaboration design](collaboration.md) | External worktree lanes, ownership, and serial integration | Planning parallel work or coordination tooling |
| [Crane suspension](crane.md) | Reusable suspension and load handling | Extending crane handling |
| [Sorting and rounds](round.md) | Provisional sorting/round rules | Changing scoring or round intent |
| [Round HUD](round_hud.md) | Independent state-driven UI | Extending playable feedback |
| [Level layouts](level_layout.md) | Provisional yard arrangements | Designing prototype layouts |
| [Playable integration](salvage_prototype.md) | First combined playable experiment | Revising prototype rules or integration intent |
| [Public delivery](releases.md) | Public repository, local agent files, tag releases and playable Pages site | Changing hosting or release automation |
| [Audio](audio.md) | Sound effects, crane motor loops and music; current files are AI placeholders | Changing or replacing sound or music |

Current behavior lives in [specs/](../specs/_readme.md); deferred work lives in [TODO.md](../TODO.md).
