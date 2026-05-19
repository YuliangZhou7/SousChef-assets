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

  # 'local:<descriptor>' — file is NOT curl-fetched by mirror.sh.
  # Two flavours:
  #   - 'local:scripts/<path>'  → operator must run that build script
  #     (e.g. scripts/build-kokoro-tarball.sh for the Kokoro tarball).
  #   - 'local:manual[:<note>]' → operator places the file manually
  #     (e.g. the dev-only openwakeword.com community Hey Chef model).
  # In either case mirror.sh just checks staging and logs guidance.
  # Keeps mirror.sh's contract simple: one transport (HTTP) per
  # fetched asset; everything else is opt-in / out-of-band.
  if [[ "$url" == local:* ]]; then
    descriptor="${url#local:}"
    if [[ -f "$out" ]]; then
      ok "[$id] already staged at $out (source: local:$descriptor; not fetched via curl)."
    elif [[ "$descriptor" == scripts/* ]]; then
      info "[$id] requires local build: $descriptor $VERSION"
      info "      Run that script, then rerun scripts/mirror.sh $VERSION."
    else
      info "[$id] requires manual placement at $out (source: $descriptor)."
      info "      Drop the file in place, then rerun scripts/mirror.sh $VERSION."
    fi
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
