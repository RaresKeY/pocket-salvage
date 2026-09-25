# Desktop audio prerequisite

`tools/Containerfile.audio` extends external `localhost/godot-podman:4.7` with Debian's `libpulse0` and resolved distribution dependencies. The image is local development tooling; no library is copied into game assets or exports. Distribution licensing stays in the image. The shared image and runner source remain unchanged.

The launcher pattern follows the user-owned Supper Guard and White Approach projects: rootless image build with `--pull=never`, exact PulseAudio/PipeWire-Pulse socket forwarding, explicit PulseAudio driver, and the managed GPU runner. Rebuild the image explicitly after base-toolchain changes. No host Godot, host networking, generation SDK or broad runtime-directory mount is required.
