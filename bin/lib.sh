lokalne="lokalne/srodowisko.sh"
if [ ! -f "$lokalne" ]; then
  echo "Brak $lokalne. Skopiuj lokalne.example/ do lokalne/ i wpisz swoje wartości." >&2
  exit 1
fi
source "$lokalne"
device="$DEVICE_ID"
app_title="Minutnik"
bundle_id="com.md4ps.minutnik"
subsystem="com.md4ps.minutnik"
project="Minutnik.xcodeproj"
scheme="Minutnik"
sources="Minutnik"
app="build/Build/Products/Debug-iphoneos/Minutnik.app"
expiry_file="$HOME/Library/Application Support/Minutnik/expiry"
log_dir="$HOME/Library/Logs/Minutnik"

profile_expiry() { security cms -D -i "$1" | plutil -extract ExpirationDate raw -o - -; }
