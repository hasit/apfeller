#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM

mkdir -p "$tmp_dir/bin"
cp "$ROOT_DIR/tests/helpers/apfel_stub.sh" "$tmp_dir/bin/apfel"
chmod +x "$tmp_dir/bin/apfel"

output=$(PATH="$tmp_dir/bin:$PATH" APFELLER_STUB_OUTPUT='awk -F, "{sum += \$3} END {print sum}" file.csv' "$ROOT_DIR/apps/oneliner/bin/oneliner" "sum the third column")

assert_contains "$output" '$ awk -F, "{sum += \$3} END {print sum}" file.csv' "oneliner should print the generated pipeline"
