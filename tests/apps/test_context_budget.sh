#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

dist_dir="$tmp_dir/dist"
extract_dir="$tmp_dir/extracted"

sh "$ROOT_DIR/scripts/package_release.sh" --output-dir "$dist_dir" >/dev/null
sh "$ROOT_DIR/scripts/package_catalog.sh" --output-dir "$dist_dir" --app-dir "$ROOT_DIR/fixtures/apps" --bundle-base-url "file://$dist_dir" >/dev/null
mkdir -p "$extract_dir"

for app in fixture-cmd fixture-oneliner fixture-define; do
  app_dir="$extract_dir/$app"
  app_archive=$(
    awk -F '\t' -v app_id="$app" '
      NR > 1 && $1 == app_id {
        bundle_url = $9
        sub(/^file:\/\//, "", bundle_url)
        print bundle_url
        exit
      }
    ' "$dist_dir/apfeller-catalog.tsv"
  )
  mkdir -p "$app_dir"
  tar -xzf "$app_archive" -C "$app_dir"

  # shellcheck disable=SC1090
  . "$app_dir/runtime/manifest.env"

  [ -n "$APFELLER_PROMPT_MAX_CONTEXT_TOKENS" ] || fail "Missing max context tokens for $app"
  [ -n "$APFELLER_PROMPT_MAX_INPUT_BYTES" ] || fail "Missing max input bytes for $app"
  [ -n "$APFELLER_PROMPT_MAX_OUTPUT_TOKENS" ] || fail "Missing max output tokens for $app"
  [ -n "$APFELLER_PROMPT_SYSTEM" ] || fail "Missing system prompt for $app"

  [ "$APFELLER_PROMPT_MAX_CONTEXT_TOKENS" = "4096" ] || fail "$app must declare a 4096-token window"

  prompt_bytes=$(LC_ALL=C printf '%s' "$APFELLER_PROMPT_SYSTEM" | wc -c | awk '{print $1}')
  total_budget=$((prompt_bytes + APFELLER_PROMPT_MAX_INPUT_BYTES + APFELLER_PROMPT_MAX_OUTPUT_TOKENS + 256))

  if [ "$total_budget" -gt "$APFELLER_PROMPT_MAX_CONTEXT_TOKENS" ]; then
    fail "$app exceeds the 4096-token budget: $total_budget"
  fi
done
