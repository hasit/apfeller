#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUTPUT_DIR="$ROOT_DIR/dist"
TAB=$(printf '\t')
TMP_DIR=""

usage() {
  cat <<'EOF'
Usage: scripts/package_release.sh [--output-dir DIR]
EOF
}

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

ensure_dir() {
  mkdir -p "$1"
}

require_tools() {
  for tool in "$@"; do
    command -v "$tool" >/dev/null 2>&1 || fail "Missing required tool: $tool"
  done
}

reset_manifest_vars() {
  APFELLER_ID=
  APFELLER_VERSION=
  APFELLER_SUMMARY=
  APFELLER_DESCRIPTION=
  APFELLER_ENTRYPOINT=
  APFELLER_REQUIRES=
  APFELLER_SUPPORTED_SHELLS=
  APFELLER_BUNDLE_FILES=
  APFELLER_ARCHIVE=
}

validate_single_line_field() {
  field_name=$1
  value=$2

  case "$value" in
    *"$TAB"*)
      fail "Field $field_name contains a tab"
      ;;
  esac

  case "$value" in
    *'
'*)
      fail "Field $field_name contains a newline"
      ;;
  esac
}

load_manifest() {
  manifest=$1

  reset_manifest_vars
  # shellcheck disable=SC1090
  . "$manifest"

  [ -n "$APFELLER_ID" ] || fail "Missing APFELLER_ID in $manifest"
  [ -n "$APFELLER_VERSION" ] || fail "Missing APFELLER_VERSION in $manifest"
  [ -n "$APFELLER_SUMMARY" ] || fail "Missing APFELLER_SUMMARY in $manifest"
  [ -n "$APFELLER_DESCRIPTION" ] || fail "Missing APFELLER_DESCRIPTION in $manifest"
  [ -n "$APFELLER_ENTRYPOINT" ] || fail "Missing APFELLER_ENTRYPOINT in $manifest"
  [ -n "$APFELLER_SUPPORTED_SHELLS" ] || fail "Missing APFELLER_SUPPORTED_SHELLS in $manifest"
  [ -n "$APFELLER_BUNDLE_FILES" ] || fail "Missing APFELLER_BUNDLE_FILES in $manifest"
  [ -n "$APFELLER_ARCHIVE" ] || fail "Missing APFELLER_ARCHIVE in $manifest"

  validate_single_line_field "APFELLER_ID" "$APFELLER_ID"
  validate_single_line_field "APFELLER_VERSION" "$APFELLER_VERSION"
  validate_single_line_field "APFELLER_SUMMARY" "$APFELLER_SUMMARY"
  validate_single_line_field "APFELLER_DESCRIPTION" "$APFELLER_DESCRIPTION"
  validate_single_line_field "APFELLER_ENTRYPOINT" "$APFELLER_ENTRYPOINT"
  validate_single_line_field "APFELLER_REQUIRES" "$APFELLER_REQUIRES"
  validate_single_line_field "APFELLER_SUPPORTED_SHELLS" "$APFELLER_SUPPORTED_SHELLS"
  validate_single_line_field "APFELLER_ARCHIVE" "$APFELLER_ARCHIVE"
}

split_csv() {
  csv=$1
  [ -n "$csv" ] || return 0

  old_ifs=$IFS
  IFS=,
  # shellcheck disable=SC2086
  set -- $csv
  IFS=$old_ifs

  for item in "$@"; do
    [ -n "$item" ] || continue
    printf '%s\n' "$item"
  done
}

resolve_bundle_source() {
  app_dir=$1
  relative_path=$2

  if [ -f "$app_dir/$relative_path" ]; then
    printf '%s\n' "$app_dir/$relative_path"
    return 0
  fi

  if [ -f "$ROOT_DIR/runtime/$relative_path" ]; then
    printf '%s\n' "$ROOT_DIR/runtime/$relative_path"
    return 0
  fi

  fail "Missing bundle file: $relative_path"
}

copy_bundle_file() {
  app_dir=$1
  relative_path=$2
  stage_dir=$3
  source_path=$(resolve_bundle_source "$app_dir" "$relative_path")
  destination_path="$stage_dir/$relative_path"

  ensure_dir "$(dirname "$destination_path")"
  cp "$source_path" "$destination_path"
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

require_tools tar shasum

APPS_OUTPUT_DIR="$OUTPUT_DIR"
CATALOG_ASSET_PATH="$OUTPUT_DIR/apfeller-catalog.tsv"
MANAGER_ASSET_PATH="$OUTPUT_DIR/apfeller.tar.gz"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/apfeller-package.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM HUP

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

printf 'id\tversion\tsummary\tdescription\tentrypoint\trequires\tsupported_shells\tbundle_archive\tsha256\n' >"$CATALOG_ASSET_PATH"

for manifest in "$ROOT_DIR"/apps/*/app.env; do
  app_dir=$(dirname "$manifest")
  load_manifest "$manifest"

  stage_dir="$TMP_DIR/stage-$APFELLER_ID"
  archive_path="$APPS_OUTPUT_DIR/$APFELLER_ARCHIVE"

  rm -rf "$stage_dir"
  mkdir -p "$stage_dir"

  split_csv "$APFELLER_BUNDLE_FILES" | while IFS= read -r relative_path; do
    copy_bundle_file "$app_dir" "$relative_path" "$stage_dir"
  done

  chmod +x "$stage_dir/bin/"*
  tar -czf "$archive_path" -C "$stage_dir" .

  archive_sha=$(shasum -a 256 "$archive_path" | awk '{print $1}')
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$APFELLER_ID" \
    "$APFELLER_VERSION" \
    "$APFELLER_SUMMARY" \
    "$APFELLER_DESCRIPTION" \
    "$APFELLER_ENTRYPOINT" \
    "$APFELLER_REQUIRES" \
    "$APFELLER_SUPPORTED_SHELLS" \
    "$APFELLER_ARCHIVE" \
    "$archive_sha" >>"$CATALOG_ASSET_PATH"

  printf 'Packaged %s %s\n' "$APFELLER_ID" "$APFELLER_VERSION"
done

manager_stage_dir="$TMP_DIR/manager"
rm -rf "$manager_stage_dir"
mkdir -p "$manager_stage_dir/bin" "$manager_stage_dir/completions/fish" "$manager_stage_dir/completions/zsh"

cp "$ROOT_DIR/shell/bin/apfeller" "$manager_stage_dir/bin/apfeller"
cp "$ROOT_DIR/shell/completions/fish/apfeller.fish" "$manager_stage_dir/completions/fish/apfeller.fish"
cp "$ROOT_DIR/shell/completions/zsh/_apfeller" "$manager_stage_dir/completions/zsh/_apfeller"

chmod +x "$manager_stage_dir/bin/apfeller"
tar -czf "$MANAGER_ASSET_PATH" -C "$manager_stage_dir" .
