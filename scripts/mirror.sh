#!/usr/bin/env bash
#
# scripts/mirror.sh — download every upstream asset listed in
# manifests/<version>.json into staging/<version>/.
#
# Skips files that are already present and that match the expected
# SHA-256 (if it's been computed). Re-downloads otherwise.
#
# Usage:
#   scripts/mirror.sh v1
#
# Prereqs: curl, /usr/bin/python3 (manifest parsing), sha256sum or
# shasum.

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_cmd curl
require_cmd /usr/bin/python3

VERSION="$(require_version "${1:-}")"
MANIFEST="$(require_manifest "$VERSION")"
STAGING="$(staging_dir_for "$VERSION")"
mkdir -p "$STAGING"

# Pick a SHA-256 binary that exists on the host.
if command -v sha256sum >/dev/null 2>&1; then
  SHA_CMD=(sha256sum)
elif command -v shasum >/dev/null 2>&1; then
  SHA_CMD=(shasum -a 256)
else
  die "Neither sha256sum nor shasum found on PATH."
fi

assets_json="$(
  /usr/bin/python3 -c '
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for asset in data["assets"]:
    print("\t".join([
        asset["id"],
        asset["filename"],
        asset.get("upstream_url", ""),
        asset.get("sha256", ""),
    ]))
' "$MANIFEST"
)"

if [[ -z "$assets_json" ]]; then
  die "Manifest has no assets array entries."
fi

while IFS=$'\t' read -r id filename url expected_sha; do
  out="${STAGING}/${filename}"
  if [[ "$url" == "TBD"* || -z "$url" ]]; then
    info "[$id] upstream URL still TBD; edit ${MANIFEST}, then rerun."
    continue
  fi

  if [[ -f "$out" && "$expected_sha" != "TBD"* && -n "$expected_sha" ]]; then
    actual_sha="$(${SHA_CMD[@]} "$out" | awk '{print $1}')"
    if [[ "$actual_sha" == "$expected_sha" ]]; then
      ok "[$id] already mirrored and integrity-checked."
      continue
    else
      info "[$id] hash mismatch on existing file; redownloading."
      rm -f "$out"
    fi
  fi

  info "[$id] downloading $url"
  curl -L --fail --output "$out" "$url"
  ok "[$id] wrote $out ($(wc -c <"$out" | tr -d ' ') bytes)"
done <<<"$assets_json"

ok "Mirror complete for $VERSION → $STAGING"
echo
echo "Next: scripts/hash.sh $VERSION"
