#!/usr/bin/env bash
#
# scripts/app-manifest.sh — emit the JSON that ships inside the
# SousChef app at App/Resources/asset-manifest.json. Reads from
# manifests/<version>.json and rewrites it for the app's consumption
# (drops upstream-only fields, adds release URLs).
#
# Output is printed to stdout. Pipe to the in-app manifest:
#   scripts/app-manifest.sh v1 \
#     > ../SousChefApp-v2/App/Resources/asset-manifest.json
#
# Usage:
#   scripts/app-manifest.sh v1

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_cmd /usr/bin/python3

VERSION="$(require_version "${1:-}")"
MANIFEST="$(require_manifest "$VERSION")"

REPO="${GH_REPO:-YuliangZhou7/SousChef-assets}"

/usr/bin/python3 - "$MANIFEST" "$VERSION" "$REPO" <<'PY'
import json, sys

manifest_path, version, repo = sys.argv[1], sys.argv[2], sys.argv[3]
with open(manifest_path) as f:
    data = json.load(f)

base_url = f"https://github.com/{repo}/releases/download/{version}"

out = {
    "version": version,
    "base_url": base_url,
    "assets": []
}

for asset in data["assets"]:
    if asset.get("sha256", "").startswith("TBD"):
        # Still TBD; skip from the shipped manifest. The app won't
        # request this asset until it's ready.
        continue
    out["assets"].append({
        "id": asset["id"],
        "filename": asset["filename"],
        "url": f"{base_url}/{asset['filename']}",
        "sha256": asset["sha256"],
        "size_bytes": asset["size_bytes"],
        "required_if": asset.get("required_if", "always"),
        "unpacked_path": asset.get("unpacked_path", asset["filename"]),
    })

print(json.dumps(out, indent=2))
PY
