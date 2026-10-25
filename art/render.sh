#!/bin/zsh
# Renders icon PNGs from art/*.svg. Needs rsvg-convert (Homebrew librsvg).
set -euo pipefail
cd "${0:A:h}/.."
A=Rectangle/Assets.xcassets/AppIcon.appiconset
for pt in 16 32 128 256 512; do
  rsvg-convert -w $pt     -h $pt     art/icon-1024.svg -o $A/mac${(l:3::0:)pt}pts1x.png
  rsvg-convert -w $((pt*2)) -h $((pt*2)) art/icon-1024.svg -o $A/mac${(l:3::0:)pt}pts2x.png
done
S=Rectangle/Assets.xcassets/StatusTemplate.imageset
rsvg-convert -w 22 -h 22 art/status.svg -o $S/RectangleStatusTemplate.png
rsvg-convert -w 22 -h 22 art/status.svg -o $S/RectangleStatusTemplate22.png
rsvg-convert -w 44 -h 44 art/status.svg -o $S/RectangleStatusTemplate44.png

mkdir -p build/AppIcon.iconset
for pt in 16 32 128 256 512; do
  rsvg-convert -w $pt       -h $pt       art/icon-1024.svg -o build/AppIcon.iconset/icon_${pt}x${pt}.png
  rsvg-convert -w $((pt*2)) -h $((pt*2)) art/icon-1024.svg -o build/AppIcon.iconset/icon_${pt}x${pt}@2x.png
done
iconutil -c icns build/AppIcon.iconset -o build/AppIcon.icns
