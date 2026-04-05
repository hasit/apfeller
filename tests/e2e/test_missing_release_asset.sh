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
  APFELLER_CATALOG_URL="https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv" \
  sh "$ROOT_DIR/shell/bin/apfeller" list 2>&1
)
list_status=$?
set -e

if [ "$list_status" -eq 0 ]; then
  printf '%s\n' "expected apfeller list to fail when the catalog release asset is missing" >&2
  exit 1
fi

assert_contains "$list_output" 'apfeller could not load the app catalog right now.' "list should use a user-facing catalog error"
assert_contains "$list_output" 'Check your internet connection and try again.' "list should tell the user what to do next"
assert_not_contains "$list_output" 'APFELLER_CATALOG_URL' "list should not expose override variables"
assert_not_contains "$list_output" 'Downloading app catalog...' "non-interactive failures should not render progress bars"

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

assert_contains "$self_update_output" 'apfeller could not download its latest files right now.' "update --self should use a user-facing manager error"
assert_contains "$self_update_output" 'Check your internet connection and try again.' "update --self should tell the user what to do next"
assert_not_contains "$self_update_output" 'Publish a release' "update --self should not mention maintainer actions"
assert_not_contains "$self_update_output" 'APFELLER_INSTALL_URL' "update --self should not expose override variables"
assert_not_contains "$self_update_output" 'Downloading apfeller update...' "non-interactive failures should not render progress bars"
