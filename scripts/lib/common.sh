#!/usr/bin/env bash
#
# scripts/lib/common.sh — shared helpers.
#
# Source this from every script:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGING_DIR="${REPO_ROOT}/staging"
MANIFESTS_DIR="${REPO_ROOT}/manifests"

die() {
  echo "✘ $*" >&2
  exit 1
}

info() {
  echo "→ $*"
}

ok() {
  echo "✔ $*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# Validate a manifest version argument like "v1" / "v2".
require_version() {
  local v="${1:-}"
  [[ -n "$v" ]] || die "Missing version (e.g. v1)"
  [[ "$v" =~ ^v[0-9]+$ ]] || die "Version must match ^v[0-9]+\$, got: $v"
  echo "$v"
}

manifest_path() {
  echo "${MANIFESTS_DIR}/$1.json"
}

require_manifest() {
  local path
  path="$(manifest_path "$1")"
  [[ -f "$path" ]] || die "Manifest not found: $path"
  echo "$path"
}

staging_dir_for() {
  echo "${STAGING_DIR}/$1"
}
