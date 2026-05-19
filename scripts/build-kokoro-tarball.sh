#!/usr/bin/env bash
#
# scripts/build-kokoro-tarball.sh — produce the Kokoro English-subset
# tarball at staging/<version>/kokoro-82m-en.tar.gz from the upstream
# HuggingFace repo FluidInference/kokoro-82m-coreml.
#
# This is the Option-A packaging recipe for Kokoro (locked in
# M1_PLAN.md / upstream/kokoro.md). The upstream repo is multi-file
# CoreML; we mirror only the English-language subset (~200 MB
# uncompressed) and ship as a single .tar.gz that scripts/publish.sh
# uploads to the asset-host release.
#
# Idempotent: skips re-download if the same commit SHA was already
# materialised at staging/<version>/kokoro-82m-en/.
#
# Usage:
#   scripts/build-kokoro-tarball.sh v1                # default branch (main)
#   KOKORO_REVISION=<hash> scripts/build-kokoro-tarball.sh v1
#
# Prereqs:
#   - huggingface-cli (`pip install huggingface_hub`)
#   - GNU tar or bsdtar (macOS ships bsdtar as `tar`)

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_cmd huggingface-cli
require_cmd tar

VERSION="$(require_version "${1:-}")"
STAGING="$(staging_dir_for "$VERSION")"
mkdir -p "$STAGING"

HF_REPO="FluidInference/kokoro-82m-coreml"
REVISION="${KOKORO_REVISION:-main}"
SUBSET_DIR="${STAGING}/kokoro-82m-en"
TARBALL="${STAGING}/kokoro-82m-en.tar.gz"
COMMIT_FILE="${STAGING}/kokoro-82m-en.commit.txt"

# English-only minimum subset (see upstream/kokoro.md).
# Each entry is a glob passed to `huggingface-cli download --include`.
INCLUDES=(
  "kokoro_21_15s_v2.mlmodelc/*"
  "G2PEncoder.mlmodelc/*"
  "G2PDecoder.mlmodelc/*"
  "g2p_vocab.json"
  "vocab_index.json"
  "us_gold.json"
  "us_lexicon_cache.json"
  "config.json"
)

info "Building Kokoro $VERSION tarball from ${HF_REPO}@${REVISION}"
info "Subset: ${#INCLUDES[@]} include globs (English-only)"

# Resolve the actual commit SHA (so 'main' is pinned for reproducibility).
RESOLVED_SHA="$(
  huggingface-cli repo info "$HF_REPO" --revision "$REVISION" 2>/dev/null \
    | awk '/^sha: /{print $2; exit}' \
  || true
)"
if [[ -z "$RESOLVED_SHA" ]]; then
  info "Could not resolve commit SHA via 'huggingface-cli repo info'; falling back to revision string."
  RESOLVED_SHA="$REVISION"
fi
info "Pinned source commit: $RESOLVED_SHA"

# Idempotency: if we've already materialised this exact commit, skip.
if [[ -f "$COMMIT_FILE" && -d "$SUBSET_DIR" ]]; then
  prior="$(cat "$COMMIT_FILE")"
  if [[ "$prior" == "$RESOLVED_SHA" ]]; then
    ok "Subset already materialised at ${SUBSET_DIR} (commit $prior). Skipping download."
  else
    info "Existing subset is commit $prior; rebuilding to $RESOLVED_SHA."
    rm -rf "$SUBSET_DIR"
  fi
fi

if [[ ! -d "$SUBSET_DIR" ]]; then
  mkdir -p "$SUBSET_DIR"
  include_flags=()
  for pat in "${INCLUDES[@]}"; do
    include_flags+=("--include" "$pat")
  done
  info "Downloading subset → $SUBSET_DIR"
  huggingface-cli download "$HF_REPO" \
    --revision "$RESOLVED_SHA" \
    --local-dir "$SUBSET_DIR" \
    "${include_flags[@]}"
  echo "$RESOLVED_SHA" > "$COMMIT_FILE"
  ok "Downloaded subset; commit recorded at $COMMIT_FILE"
fi

# Build the tarball. Use sorted entries for reproducibility.
info "Building $TARBALL"
# `tar -C staging -czf staging/kokoro-82m-en.tar.gz kokoro-82m-en/`
tar -C "$STAGING" -czf "$TARBALL" "kokoro-82m-en"

bytes="$(wc -c <"$TARBALL" | tr -d ' ')"
ok "Built $TARBALL ($bytes bytes)"

echo
echo "Next: scripts/hash.sh $VERSION   # then publish.sh, then app-manifest.sh"
