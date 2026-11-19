#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source bin/lib.sh
mkdir -p "$log_dir"
notify() {
  osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title (item 2 of argv) sound name "Glass"' -e 'end run' -- "$1" "$app_title"
  echo "$(date '+%F %T') $1"
}
if [ ! -s "$expiry_file" ]; then
  notify "Nie wiem, kiedy wygasa podpis. Uruchom bin/install.sh"
  exit 0
fi
expiry_epoch="$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$(cat "$expiry_file")" +%s)"
hours_left=$(( (expiry_epoch - $(date +%s)) / 3600 ))
[ "$hours_left" -le "${REMIND_HOURS:-36}" ] || exit 0
notify "Wygasa $(date -j -r "$expiry_epoch" "+%d.%m %H:%M"). Podłącz iPhone'a, zaloguj Xcode, potem bin/renew.sh"
