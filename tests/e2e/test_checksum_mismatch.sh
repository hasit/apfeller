#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

dist_dir="$tmp_dir/dist"
home_dir="$tmp_dir/home"
stub_dir="$tmp_dir/bin"
manager_stage="$tmp_dir/manager"

mkdir -p "$stub_dir"
cp "$ROOT_DIR/tests/helpers/apfel_stub.sh" "$stub_dir/apfel"
chmod +x "$stub_dir/apfel"

(cd "$ROOT_DIR" && scripts/package_release.sh --output-dir "$dist_dir")
printf '%s\n' "tampered" >>"$dist_dir/cmd-0.1.0.tar.gz"

mkdir -p "$manager_stage" "$home_dir/.local/bin"
tar -xzf "$dist_dir/apfeller.tar.gz" -C "$manager_stage"
cp "$manager_stage/bin/apfeller" "$home_dir/.local/bin/apfeller"
chmod +x "$home_dir/.local/bin/apfeller"

catalog_url="file://$dist_dir/apfeller-catalog.tsv"
release_base_url="file://$dist_dir"

set +e
output=$(
  HOME="$home_dir" \
  PATH="$home_dir/.local/bin:$stub_dir:$PATH" \
  APFELLER_CATALOG_URL="$catalog_url" \
  APFELLER_RELEASE_BASE_URL="$release_base_url" \
  apfeller install cmd 2>&1
)
status=$?
set -e

if [ "$status" -eq 0 ]; then
  printf '%s\n' "expected install to fail on checksum mismatch" >&2
  exit 1
fi

assert_contains "$output" 'Checksum mismatch for cmd' "install should fail when the bundle checksum changes"
