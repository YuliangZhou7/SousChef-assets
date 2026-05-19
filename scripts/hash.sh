#!/usr/bin/env bash
#
# scripts/hash.sh — compute SHA-256 + byte size for every mirrored
# file in staging/<version>/, write back into manifests/<version>.json.
#
# Idempotent. Files that haven't changed leave their manifest entries
# untouched. Files that aren't present in staging/ are reported and
# skipped (sha256 stays "TBD").
#
# Usage:
#   scripts/hash.sh v1

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_cmd /usr/bin/python3

VERSION="$(require_version "${1:-}")"
MANIFEST="$(require_manifest "$VERSION")"
STAGING="$(staging_dir_for "$VERSION")"

[[ -d "$STAGING" ]] || die "Staging not found: $STAGING. Run scripts/mirror.sh $VERSION first."

if command -v sha256sum >/dev/null 2>&1; then
  SHA_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA_CMD="shasum -a 256"
else
  die "Neither sha256sum nor shasum found."
fi

/usr/bin/python3 - "$MANIFEST" "$STAGING" "$SHA_CMD" <<'PY'
import json, os, subprocess, sys

manifest_path, staging, sha_cmd = sys.argv[1], sys.argv[2], sys.argv[3]
with open(manifest_path) as f:
    data = json.load(f)

updated = False
for asset in data["assets"]:
    path = os.path.join(staging, asset["filename"])
    if not os.path.exists(path):
        print(f"⚠ {asset['id']}: not in staging ({path}); skipping.")
        continue
    size = os.path.getsize(path)
    result = subprocess.run(
        sha_cmd.split() + [path],
        capture_output=True,
        text=True,
        check=True,
    )
    digest = result.stdout.split()[0]
    if asset.get("sha256") != digest or asset.get("size_bytes") != size:
        asset["sha256"] = digest
        asset["size_bytes"] = size
        updated = True
        print(f"→ {asset['id']}: sha256={digest[:16]}…  size={size} bytes")
    else:
        print(f"✔ {asset['id']}: unchanged")

if updated:
    with open(manifest_path, "w") as f:
        json.dump(data, f, indent=2, sort_keys=False)
        f.write("\n")
    print()
    print(f"Wrote updated manifest: {manifest_path}")
else:
    print()
    print("No manifest changes.")
PY
