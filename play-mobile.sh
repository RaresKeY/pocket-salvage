#!/bin/sh
# Preview current local source with phone controls; mouse drag emulates one finger.
set -eu
launcher_path=$(readlink -f -- "$0")
project_root=$(CDPATH= cd -- "$(dirname -- "$launcher_path")" && pwd -P)
exec "$project_root/play.sh" --resolution 844x390 "$@" -- --touch-controls --mobile-preview
