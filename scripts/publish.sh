#!/usr/bin/env bash
#
# scripts/publish.sh — upload staged assets to GitHub Releases for
# version <version>. Creates the release tag if it doesn't exist;
# adds missing files if it does.
#
# Idempotent. Re-running uploads only the files that aren't already
# attached to the release.
#
# Usage:
#   scripts/publish.sh v1

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_cmd gh
require_cmd /usr/bin/python3

VERSION="$(require_version "${1:-}")"
MANIFEST="$(require_manifest "$VERSION")"
STAGING="$(staging_dir_for "$VERSION")"
[[ -d "$STAGING" ]] || die "Staging not found: $STAGING. Run scripts/mirror.sh $VERSION first."

REPO="${GH_REPO:-YuliangZhou7/SousChef-assets}"

# Verify gh is authenticated.
gh auth status >/dev/null 2>&1 || die "gh not authenticated. Run 'gh auth login'."

# Create the release if it doesn't exist (--notes empty for now;
# release notes can be edited from the GitHub UI).
if ! gh release view "$VERSION" --repo "$REPO" >/dev/null 2>&1; then
  info "Creating GitHub release $VERSION on $REPO"
  gh release create "$VERSION" \
    --repo "$REPO" \
    --title "SousChef voice assets $VERSION" \
    --notes "Auto-published by scripts/publish.sh. Asset attribution: ATTRIBUTION.md."
fi

# List filenames the manifest expects to ship. Filters out:
# - assets whose sha256 is still TBD (not yet mirrored + hashed)
# - assets explicitly marked publish_eligible=false (e.g. v1's Hey Chef
#   community model, which is dev/dogfood only per its license terms)
filenames="$(
  /usr/bin/python3 -c '
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for asset in data["assets"]:
    if asset.get("sha256", "").startswith("TBD"):
        continue
    if asset.get("publish_eligible", True) is False:
        print(f"  skipping {asset[\"id\"]}: publish_eligible=false", file=sys.stderr)
        continue
    print(asset["filename"])
' "$MANIFEST"
)"

if [[ -z "$filenames" ]]; then
  die "No assets ready to publish. Run scripts/hash.sh $VERSION first."
fi

# Already-uploaded filenames for this release.
existing="$(gh release view "$VERSION" --repo "$REPO" --json assets \
  --jq '.assets[].name' 2>/dev/null || true)"

while IFS= read -r filename; do
  path="${STAGING}/${filename}"
  [[ -f "$path" ]] || { info "$filename not staged; skipping"; continue; }
  if grep -qx "$filename" <<<"$existing" 2>/dev/null; then
    ok "$filename already attached to $VERSION"
    continue
  fi
  info "Uploading $filename ($(wc -c <"$path" | tr -d ' ') bytes)"
  gh release upload "$VERSION" "$path" --repo "$REPO"
  ok "Uploaded $filename"
done <<<"$filenames"

echo
ok "Publish complete for $VERSION"
echo
echo "Next: scripts/app-manifest.sh $VERSION"
