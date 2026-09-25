# Pocket Salvage

A four-minute scrapyard shift. Drive a swinging crane, swap between a magnet and a claw, and sort ten pieces of scrap before time runs out.

**[Play in your browser](https://pocket-salvage.web.app/)** · **[Download for Windows or Linux](https://github.com/RaresKeY/pocket-salvage/releases/latest)**

[Alternate play link: GitHub Pages](https://rareskey.github.io/pocket-salvage/). Firebase is a manually deployed release snapshot; GitHub Pages updates with each tagged release.

![Pocket Salvage: a crane above a moonlit scrapyard, with copper, rubber and steel sorting bins.](marketing/pocket-salvage.png)

## Current release

Source on `main` adds a 12-slot level grid: Clear, Breezy and Violent are unlocked; the remaining nine are placeholders. Replay keeps your chosen level. This is not yet in the published Web builds.

The [latest release](https://github.com/RaresKeY/pocket-salvage/releases/latest) adds per-round weather: clear, fog, wind, rain or storm. Wind pushes the crane and airborne scrap, rain makes scrap slippery, and lightning briefly cuts magnet power. Harder weather multiplies a positive final score.

It also retains the v0.1.5 improvements: better Firefox audio continuity during frame stalls, reduced cable and HUD work, and a 60 FPS target on Web. Keyboard, standard controllers and mobile touch controls are supported. Music and SFX have separate controls; click **Start** to enable browser audio. This release also adds square pixel-font menus, pause-menu volume sliders, curved wind trails and sparse fading dust.

## How to play

The **magnet lifts steel**; the **claw grabs copper and rubber**. Park your current head at an empty tool stand on the left, then pick up the other. Drop scrap into its matching bin.

Correct sorts earn **100 points**. A wrong bin throws the item back and costs **25 points**. Clear the yard early for **5 points per second remaining**.

| Action | Keyboard | Controller (standard layout) |
|---|---|---|
| Start / resume / replay | Enter or the on-screen button | A / south face button |
| Move / raise / lower | WASD or arrow keys | Left stick or D-pad |
| Grab / release | Space | A / south face button |
| Park / pick up a head | E | X / west face button |
| Pause / resume | P or Escape | Start or B / east face button |
| Restart | R | Y / north face button |
| Toggle music / SFX | M for music; HUD buttons | Left / right bumper |

On mobile Web browsers, a **bottom-right touch controller** appears automatically: hold arrows to move and lift; tap **Grip** or **Swap**. You can use movement and action buttons together. Turn your phone sideways for a wider yard. Start, pause, resume and audio controls remain on-screen.

For desktop downloads, extract the whole ZIP and keep the executable beside its PCK file. Run `pocket-salvage.exe` on Windows or `pocket-salvage.x86_64` on Linux. The downloadable Web ZIP needs an HTTP server; use either hosted play link for immediate browser play.

## Development

Made with **Godot 4.7**. Import `project.godot`, run the project, then choose **Play prototype** from the yard preview. To open the playable scene directly, use `labs/salvage/lab.tscn`.

On Linux with the shared `godot-podman` runner configured, `./play.sh` launches the game with desktop audio and `./tests/check` runs the suite. These scripts require that runner; `play.sh` also requires a PulseAudio-compatible desktop audio socket. Setup and alternative test commands are in the [contributor guide](docs/collaboration.md) and [test guide](tests/README.md).

- [Contributor guide](docs/collaboration.md) — setup, direct-main workflow, and migration from `random-game`.
- [Specs](specs/_readme.md) and [design](design/_readme.md) — current behavior, decisions, and human/AI attribution.
- [Builds and releases](specs/builds.md) — local exports, checksums, tag automation, Firebase hosting, and platform validation.
- [Performance review](docs/performance-review.md) — Firefox/Linux measurements, audio checks, and remaining limitations.

Main pushes run tests. Matching version tags test and build Windows, Linux and Web releases, then update GitHub Pages. Linux and Firefox/Linux have runtime validation. Windows exports are built and hash-verified but still need a Windows-machine playtest.
