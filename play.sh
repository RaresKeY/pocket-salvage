#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
runner=${GODOT_PODMAN_RUNNER:-"$project_root/../godot-podman/bin/godot-podman"}

if [ ! -x "$runner" ]; then
    echo "Godot Podman runner unavailable; set GODOT_PODMAN_RUNNER to its executable path." >&2
    exit 1
fi

audio_image=localhost/pocket-salvage-audio:4.7
pulse_socket="${XDG_RUNTIME_DIR:?Desktop runtime directory is required}/pulse/native"
if [ ! -S "$pulse_socket" ]; then
    echo "Desktop audio socket unavailable: $pulse_socket" >&2
    exit 1
fi
if ! podman image exists "$audio_image"; then
    podman build --pull=never --rm --force-rm -t "$audio_image" \
        -f "$project_root/tools/Containerfile.audio" "$project_root/tools"
fi

# Import and play under one managed lock, forwarding only the desktop audio socket.
exec "$runner" run --project "$project_root" --image "$audio_image" --purpose play --display host \
    --volume "$pulse_socket:/tmp/pocket-salvage-pulse:rw" \
    --env PULSE_SERVER=unix:/tmp/pocket-salvage-pulse -- \
    sh -c '
        set -eu
        godot --headless --audio-driver Dummy --path /workspace --editor --import --quit
        exec godot --path /workspace --audio-driver PulseAudio --scene res://labs/salvage/lab.tscn "$@"
    ' play "$@"
