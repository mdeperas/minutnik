#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source bin/lib.sh
minutes="${1:-30}"
stamp="$(date +%Y-%m-%d_%H-%M-%S)"
archive="$(mktemp -d)/minutnik.logarchive"
out="$log_dir/phone-$stamp.log"
mkdir -p "$log_dir"
as_root() { if [ -t 0 ]; then sudo "$@"; else SUDO_ASKPASS="$PWD/bin/askpass.sh" sudo -A "$@"; fi; }
as_root log collect --device-udid "$device" --last "${minutes}m" --output "$archive"
log show "$archive" --info --style compact --predicate "subsystem == \"$subsystem\"" > "$out"
as_root rm -rf "$(dirname "$archive")"
echo "$out ($(wc -l < "$out" | tr -d ' ') linii)"
