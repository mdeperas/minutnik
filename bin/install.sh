#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source bin/lib.sh
[ -f lokalne/zestawy.json ] || echo "Brak lokalne/zestawy.json (bin/generuj-zestawy): apka dostanie wariant publiczny." >&2
xcodegen generate -q
commit="$(git rev-parse --short HEAD)"
git diff --quiet HEAD -- "$sources" project.yml || commit="$commit+zmiany"
released="$(TZ=Europe/Warsaw git log -1 --format=%cd --date=format-local:'%d.%m.%Y %H:%M')"
xcodebuild -project "$project" -scheme "$scheme" -destination "id=$device" \
  -derivedDataPath build -allowProvisioningUpdates build -quiet \
  CURRENT_PROJECT_VERSION="$(git rev-list --count HEAD)" MINUTNIK_GIT_COMMIT="$commit" MINUTNIK_RELEASE_DATE="$released"
xcrun devicectl device install app --device "$device" "$app"
mkdir -p "$(dirname "$expiry_file")" "$log_dir"
profile_expiry "$app/embedded.mobileprovision" > "$expiry_file"
