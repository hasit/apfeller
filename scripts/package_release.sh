#!/bin/sh

set -eu

ROOT_DIR=${APFELLER_ROOT_DIR:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
OUTPUT_DIR="$ROOT_DIR/dist"
TMP_DIR=""

usage() {
  cat <<'EOF'
Usage: scripts/package_release.sh [--output-dir DIR]
EOF
}

require_tools() {
  for tool in "$@"; do
    command -v "$tool" >/dev/null 2>&1 || {
      printf '%s\n' "Missing required tool: $tool" >&2
      exit 1
    }
  done
}

while [ $# -gt 0 ]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

require_tools tar

MANAGER_ASSET_PATH="$OUTPUT_DIR/apfeller.tar.gz"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/apfeller-package.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM HUP

mkdir -p "$OUTPUT_DIR"
rm -f "$MANAGER_ASSET_PATH"

manager_stage_dir="$TMP_DIR/manager"
rm -rf "$manager_stage_dir"
mkdir -p "$manager_stage_dir/bin" "$manager_stage_dir/completions/fish" "$manager_stage_dir/completions/zsh"

cp "$ROOT_DIR/shell/bin/apfeller" "$manager_stage_dir/bin/apfeller"
cp "$ROOT_DIR/shell/completions/fish/apfeller.fish" "$manager_stage_dir/completions/fish/apfeller.fish"
cp "$ROOT_DIR/shell/completions/zsh/_apfeller" "$manager_stage_dir/completions/zsh/_apfeller"

chmod +x "$manager_stage_dir/bin/apfeller"
tar -czf "$MANAGER_ASSET_PATH" -C "$manager_stage_dir" .
printf '%s\n' "Packaged apfeller manager"
