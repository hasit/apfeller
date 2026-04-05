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

too_large=$(awk 'BEGIN { for (i = 0; i < 1100; i++) printf "a" }')
marker="$tmp_dir/cmd-apfel-called"

set +e
oversized_output=$(
  PATH="$tmp_dir/bin:$PATH" \
  APFELLER_STUB_MARKER="$marker" \
  APFELLER_STUB_FAIL_IF_CALLED=1 \
  "$ROOT_DIR/apps/cmd/bin/cmd" "$too_large" 2>&1
)
status=$?
set -e

if [ "$status" -eq 0 ]; then
  printf '%s\n' "expected cmd to reject oversized input" >&2
  exit 1
fi

assert_contains "$oversized_output" "Input too large for cmd" "cmd should explain the context budget limit"
assert_file_not_exists "$marker"
