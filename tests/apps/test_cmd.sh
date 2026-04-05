#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM

mkdir -p "$tmp_dir/bin"
cp "$ROOT_DIR/tests/helpers/apfel_stub.sh" "$tmp_dir/bin/apfel"
chmod +x "$tmp_dir/bin/apfel"

output=$(PATH="$tmp_dir/bin:$PATH" APFELLER_STUB_OUTPUT='find . -name "*.log"' "$ROOT_DIR/apps/cmd/bin/cmd" "find all log files")

assert_contains "$output" '$ find . -name "*.log"' "cmd should print the generated command"
