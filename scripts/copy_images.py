#!/usr/bin/env python3
"""Copy asset-catalog images into a flat Resources dir as <set>.png / <set>@2x.png."""
import json, shutil, subprocess, sys
from pathlib import Path

catalog, out = Path(sys.argv[1]), Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
count = 0
for imageset in catalog.rglob("*.imageset"):
    name = imageset.stem
    have = set()
    for img in json.loads((imageset / "Contents.json").read_text())["images"]:
        if "filename" not in img:
            continue
        scale = img.get("scale", "1x")
        suffix = "" if scale == "1x" else "@" + scale
        shutil.copy(imageset / img["filename"], out / f"{name}{suffix}.png")
        have.add(scale)
        count += 1
    # Xcode derives a missing 1x from the 2x; do the same (half size) so named lookup works.
    if "1x" not in have and "2x" in have:
        two = out / f"{name}@2x.png"
        w, h = (int(subprocess.check_output(["sips", "-g", k, str(two)], text=True).split()[-1]) for k in ("pixelWidth", "pixelHeight"))
        subprocess.run(["sips", "-z", str(h // 2), str(w // 2), str(two), "--out", str(out / f"{name}.png")], check=True, capture_output=True)
        count += 1
print(f"copied {count} images")
