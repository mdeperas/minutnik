#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source bin/lib.sh
profiles="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
aside="build/old-profiles"

profile_name() { security cms -D -i "$1" 2>/dev/null | plutil -extract Name raw -o - - 2>/dev/null || true; }
own_profiles() {
  for file in "$profiles"/*.mobileprovision; do
    [ -e "$file" ] && [ "$(profile_name "$file")" = "iOS Team Provisioning Profile: $bundle_id" ] && echo "$file"
  done
  return 0
}
restore_aside() {
  [ -n "$(own_profiles)" ] || mv "$aside"/*.mobileprovision "$profiles/" 2>/dev/null || true
}

if ! xcrun devicectl list devices 2>/dev/null | grep "$device" | grep -qE "connected|available"; then
  echo "iPhone niepodłączony. Podłącz kablem, odblokuj i uruchom ponownie." >&2
  exit 1
fi

xcodegen generate -q
open -g -a Xcode "$project"

mkdir -p "$aside"
trap restore_aside EXIT
while IFS= read -r file; do mv "$file" "$aside/"; done < <(own_profiles)

for _ in $(seq 1 30); do
  [ -n "$(own_profiles)" ] && break
  sleep 2
done

if [ -z "$(own_profiles)" ]; then
  echo "Xcode nie pobrał nowego profilu w 60 s. Xcode → Settings (Cmd+,) → Accounts → zaloguj Apple ID i uruchom ponownie." >&2
  exit 1
fi
rm -f "$aside"/*.mobileprovision

bin/install.sh
echo "$app_title zainstalowany, podpis ważny do $(cat "$expiry_file")"
