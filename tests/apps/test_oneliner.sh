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

too_large=$(awk 'BEGIN { for (i = 0; i < 1100; i++) printf "b" }')
marker="$tmp_dir/oneliner-apfel-called"

set +e
oversized_output=$(
  PATH="$tmp_dir/bin:$PATH" \
  APFELLER_STUB_MARKER="$marker" \
  APFELLER_STUB_FAIL_IF_CALLED=1 \
  "$ROOT_DIR/apps/oneliner/bin/oneliner" "$too_large" 2>&1
)
status=$?
set -e

if [ "$status" -eq 0 ]; then
  printf '%s\n' "expected oneliner to reject oversized input" >&2
  exit 1
fi

assert_contains "$oversized_output" "Input too large for oneliner" "oneliner should explain the context budget limit"
assert_file_not_exists "$marker"
