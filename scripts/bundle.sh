#!/bin/zsh
# Builds "Rectangle Ultra.app" with SwiftPM only (no Xcode), ad-hoc signed.
set -euo pipefail
cd "${0:A:h}/.."
CONFIG=${1:-release}
APP="build/Rectangle Ultra.app"
ID=local.rectangleultra
if [[ $CONFIG == debug ]]; then ID+=.debug; fi  # debug builds get their own permission + prefs
swift build -c "$CONFIG" --product RectangleUltra
BIN=$(swift build -c "$CONFIG" --show-bin-path)
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/RectangleUltra" "$APP/Contents/MacOS/Rectangle Ultra"
cp -R "$BIN/MASShortcut_MASShortcut.bundle" "$APP/Contents/Resources/"
sed -e 's/$(DEVELOPMENT_LANGUAGE)/en/' \
    -e 's/$(EXECUTABLE_NAME)/Rectangle Ultra/' \
    -e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/$ID/" \
    -e 's/$(PRODUCT_NAME)/Rectangle Ultra/' \
    -e 's/$(MARKETING_VERSION)/0.1.0/' \
    -e 's/$(CURRENT_PROJECT_VERSION)/112/' \
    -e 's/$(MACOSX_DEPLOYMENT_TARGET)/14.0/' \
    Rectangle/Info.plist > "$APP/Contents/Info.plist"
plutil -replace CFBundleIconFile -string AppIcon "$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/Info.plist"
art/render.sh
cp build/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
python3 scripts/copy_images.py Rectangle/Assets.xcassets "$APP/Contents/Resources"
missing=0
for n in $(grep -rhoE '(imageLiteralResourceName|named): *"[A-Za-z0-9_.]+"' Rectangle | grep -oE '"[^"]+"' | tr -d '"' | sort -u); do
  [[ -e "$APP/Contents/Resources/$n.png" || -e "$APP/Contents/Resources/$n.icns" ]] || { echo "missing image: $n"; missing=1; }
done
(( missing == 0 ))
codesign --force --sign - --entitlements Rectangle/RectangleRelease.entitlements "$APP"
codesign --verify --strict "$APP" && echo "built: $APP"
