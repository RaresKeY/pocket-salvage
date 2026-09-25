# Pocket Salvage

A four-minute scrapyard shift. Drive a swinging crane, swap between a magnet and a claw, and sort ten pieces of scrap before time runs out.

**[Play in your browser](https://rareskey.github.io/pocket-salvage/)** · **[Download for Windows or Linux](https://github.com/RaresKeY/pocket-salvage/releases/latest)**

![Pocket Salvage: a crane above a moonlit scrapyard, with copper, rubber and steel sorting bins.](marketing/pocket-salvage.png)

## How to play

The **magnet lifts steel**; the **claw grabs copper and rubber**. Park your current head at an empty tool stand on the left, then pick up the other. Drop scrap into its matching bin.

Correct sorts earn **100 points**. A wrong bin throws the item back and costs **25 points**. Clear the yard early for **5 points per second remaining**.

| Key | Action |
|---|---|
| Enter | Start the round |
| A / D or ← / → | Move the crane |
| W / S or ↑ / ↓ | Raise / lower the head |
| Space | Grab / release |
| E | Park / pick up a head at a tool stand |
| P or Escape | Pause |
| R | Restart |
| M | Toggle music |

Play with a keyboard. The HUD also has music and sound-effect controls. For desktop downloads, extract the whole ZIP and keep the executable beside its PCK file.

## Development

Made with **Godot 4.7**. Open `project.godot` and choose **Play prototype** from the yard preview. On a workstation configured with the shared Godot runner, `./play.sh` launches the game with desktop audio and `./tests/check` runs the test suite.

- [Contributor guide](docs/collaboration.md) — setup, direct-main workflow, and migration from `random-game`.
- [Specs](specs/_readme.md) and [design](design/_readme.md) — current behavior, decisions, and human/AI attribution.
- [Builds and releases](specs/builds.md) — local exports, checksums, tag automation, and platform validation.

Main pushes run tests. Matching version tags test and build Windows, Linux and Web releases, then update the playable site. Windows exports are built and checked but still need a Windows-machine playtest.
