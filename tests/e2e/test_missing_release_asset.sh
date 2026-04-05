#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

stub_dir="$tmp_dir/bin"
mkdir -p "$stub_dir" "$tmp_dir/home"
cp "$ROOT_DIR/tests/helpers/curl_404_stub.sh" "$stub_dir/curl"
chmod +x "$stub_dir/curl"

set +e
list_output=$(
  HOME="$tmp_dir/home" \
  PATH="$stub_dir:$PATH" \
  APFELLER_CATALOG_URL="https://github.com/hasit/apfeller/releases/latest/download/apfeller-catalog.tsv" \
  sh "$ROOT_DIR/shell/bin/apfeller" list 2>&1
)
list_status=$?
set -e

if [ "$list_status" -eq 0 ]; then
  printf '%s\n' "expected apfeller list to fail when the catalog release asset is missing" >&2
  exit 1
fi

assert_contains "$list_output" 'Failed to download app catalog' "list should identify the missing catalog asset"
assert_contains "$list_output" 'No published GitHub release asset was found for apfeller-catalog.tsv.' "list should explain the missing catalog release asset"
assert_contains "$list_output" 'APFELLER_CATALOG_URL' "list should point to the catalog override variable"

set +e
self_update_output=$(
  HOME="$tmp_dir/home" \
  PATH="$stub_dir:$PATH" \
  APFELLER_INSTALL_URL="https://github.com/hasit/apfeller/releases/latest/download/apfeller.tar.gz" \
  sh "$ROOT_DIR/shell/bin/apfeller" update --self 2>&1
)
self_update_status=$?
set -e

if [ "$self_update_status" -eq 0 ]; then
  printf '%s\n' "expected apfeller update --self to fail when the manager release asset is missing" >&2
  exit 1
fi

assert_contains "$self_update_output" 'Failed to download manager archive' "update --self should identify the missing manager asset"
assert_contains "$self_update_output" 'No published GitHub release asset was found for apfeller.tar.gz.' "update --self should explain the missing manager release asset"
assert_contains "$self_update_output" 'APFELLER_INSTALL_URL' "update --self should point to the install override variable"
