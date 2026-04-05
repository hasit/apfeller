#!/bin/sh

set -eu

ROOT_DIR=${APFELLER_ROOT_DIR:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
OUTPUT_DIR="$ROOT_DIR/dist"
TMP_DIR=""

# shellcheck disable=SC1091
. "$ROOT_DIR/scripts/lib/app_framework.sh"

usage() {
  cat <<'EOF'
Usage: scripts/package_release.sh [--output-dir DIR]
EOF
}

ensure_dir() {
  mkdir -p "$1"
}

require_tools() {
  for tool in "$@"; do
    command -v "$tool" >/dev/null 2>&1 || appfw_fail "Missing required tool: $tool"
  done
}

shell_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

write_env_assignment() {
  key=$1
  value=$2
  printf '%s=' "$key"
  shell_quote "$value"
  printf '\n'
}

copy_relative_file() {
  app_dir=$1
  relative_path=$2
  stage_dir=$3

  case "$relative_path" in
    ''|/*|../*|*/../*|*'/..')
      appfw_fail "Hook paths must stay within the app directory: $relative_path"
      ;;
  esac

  source_path="$app_dir/$relative_path"
  [ -f "$source_path" ] || appfw_fail "Missing hook file: $relative_path"

  destination_path="$stage_dir/$relative_path"
  ensure_dir "$(dirname "$destination_path")"
  cp "$source_path" "$destination_path"
  chmod +x "$destination_path"
}

emit_runtime_manifest() {
  manifest_path=$1

  {
    write_env_assignment APFELLER_APP_ID "$APP_ID"
    write_env_assignment APFELLER_APP_VERSION "$APP_VERSION"
    write_env_assignment APFELLER_APP_SUMMARY "$APP_SUMMARY"
    write_env_assignment APFELLER_APP_DESCRIPTION "$APP_DESCRIPTION"
    write_env_assignment APFELLER_APP_COMMAND "$APP_COMMAND"
    write_env_assignment APFELLER_APP_KIND "$APP_KIND"
    write_env_assignment APFELLER_APP_REQUIRES "$APP_REQUIRES"
    write_env_assignment APFELLER_APP_SUPPORTED_SHELLS "$APP_SUPPORTED_SHELLS"
    write_env_assignment APFELLER_HELP_USAGE "$APP_HELP_USAGE"
    write_env_assignment APFELLER_INPUT_MODE "$APP_INPUT_MODE"
    write_env_assignment APFELLER_INPUT_NAME "$APP_INPUT_NAME"
    write_env_assignment APFELLER_INPUT_REQUIRED "$APP_INPUT_REQUIRED"
    write_env_assignment APFELLER_PROMPT_SYSTEM "$APP_PROMPT_SYSTEM"
    write_env_assignment APFELLER_PROMPT_TEMPLATE "$APP_PROMPT_TEMPLATE"
    write_env_assignment APFELLER_PROMPT_MAX_CONTEXT_TOKENS "$APP_PROMPT_MAX_CONTEXT_TOKENS"
    write_env_assignment APFELLER_PROMPT_MAX_INPUT_BYTES "$APP_PROMPT_MAX_INPUT_BYTES"
    write_env_assignment APFELLER_PROMPT_MAX_OUTPUT_TOKENS "$APP_PROMPT_MAX_OUTPUT_TOKENS"
    write_env_assignment APFELLER_OUTPUT_MODE "$APP_OUTPUT_MODE"
    write_env_assignment APFELLER_OUTPUT_FIELDS "$APP_OUTPUT_FIELDS"
    write_env_assignment APFELLER_HOOK_BUILD_PROMPT "$APP_HOOK_BUILD_PROMPT"
    write_env_assignment APFELLER_HOOK_PRE_RUN "$APP_HOOK_PRE_RUN"
  } >"$manifest_path"
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

CATALOG_ASSET_PATH="$OUTPUT_DIR/apfeller-catalog.tsv"
MANAGER_ASSET_PATH="$OUTPUT_DIR/apfeller.tar.gz"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/apfeller-package.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM HUP

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

printf 'id\tversion\tsummary\tdescription\tcommand\tkind\trequires\tsupported_shells\tbundle_archive\tsha256\n' >"$CATALOG_ASSET_PATH"

for manifest in "$ROOT_DIR"/apps/*/app.toml; do
  [ -f "$manifest" ] || continue

  app_dir=$(dirname "$manifest")
  args_file="$TMP_DIR/$(basename "$app_dir")-args.tsv"
  examples_file="$TMP_DIR/$(basename "$app_dir")-examples.txt"
  appfw_load_definition "$manifest" "$args_file" "$examples_file"

  archive_name="$APP_ID-$APP_VERSION.tar.gz"
  archive_path="$OUTPUT_DIR/$archive_name"
  stage_dir="$TMP_DIR/stage-$APP_ID"

  rm -rf "$stage_dir"
  mkdir -p "$stage_dir/runtime"

  cp "$manifest" "$stage_dir/app.toml"
  cp "$args_file" "$stage_dir/runtime/args.tsv"
  cp "$examples_file" "$stage_dir/runtime/examples.txt"
  emit_runtime_manifest "$stage_dir/runtime/manifest.env"

  if [ -n "$APP_HOOK_BUILD_PROMPT" ]; then
    copy_relative_file "$app_dir" "$APP_HOOK_BUILD_PROMPT" "$stage_dir"
  fi

  if [ -n "$APP_HOOK_PRE_RUN" ]; then
    copy_relative_file "$app_dir" "$APP_HOOK_PRE_RUN" "$stage_dir"
  fi

  tar -czf "$archive_path" -C "$stage_dir" .
  archive_sha=$(shasum -a 256 "$archive_path" | awk '{print $1}')

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$APP_ID" \
    "$APP_VERSION" \
    "$APP_SUMMARY" \
    "$APP_DESCRIPTION" \
    "$APP_COMMAND" \
    "$APP_KIND" \
    "$APP_REQUIRES" \
    "$APP_SUPPORTED_SHELLS" \
    "$archive_name" \
    "$archive_sha" >>"$CATALOG_ASSET_PATH"

  printf 'Packaged %s %s\n' "$APP_ID" "$APP_VERSION"
done

manager_stage_dir="$TMP_DIR/manager"
rm -rf "$manager_stage_dir"
mkdir -p "$manager_stage_dir/bin" "$manager_stage_dir/completions/fish" "$manager_stage_dir/completions/zsh"

cp "$ROOT_DIR/shell/bin/apfeller" "$manager_stage_dir/bin/apfeller"
cp "$ROOT_DIR/shell/completions/fish/apfeller.fish" "$manager_stage_dir/completions/fish/apfeller.fish"
cp "$ROOT_DIR/shell/completions/zsh/_apfeller" "$manager_stage_dir/completions/zsh/_apfeller"

chmod +x "$manager_stage_dir/bin/apfeller"
tar -czf "$MANAGER_ASSET_PATH" -C "$manager_stage_dir" .
