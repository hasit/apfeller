#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM

mkdir -p "$tmp_dir/bin"
cp "$ROOT_DIR/tests/helpers/apfel_stub.sh" "$tmp_dir/bin/apfel"
chmod +x "$tmp_dir/bin/apfel"

stub_output='word: hola lang: es meaning: hello example: hola, amiga (hello, friend)'
output=$(PATH="$tmp_dir/bin:$PATH" APFELLER_STUB_OUTPUT="$stub_output" "$ROOT_DIR/apps/define/bin/define" hola)

assert_contains "$output" 'word: hola' "define should print the word field"
assert_contains "$output" 'lang: es' "define should print the language field"
assert_contains "$output" 'meaning: hello' "define should print the meaning field"
assert_contains "$output" 'example: hola, amiga (hello, friend)' "define should print the example field"

too_large=$(awk 'BEGIN { for (i = 0; i < 900; i++) printf "c" }')
marker="$tmp_dir/define-apfel-called"

set +e
oversized_output=$(
  PATH="$tmp_dir/bin:$PATH" \
  APFELLER_STUB_MARKER="$marker" \
  APFELLER_STUB_FAIL_IF_CALLED=1 \
  "$ROOT_DIR/apps/define/bin/define" "$too_large" 2>&1
)
status=$?
set -e

if [ "$status" -eq 0 ]; then
  printf '%s\n' "expected define to reject oversized input" >&2
  exit 1
fi

assert_contains "$oversized_output" "Input too large for define" "define should explain the context budget limit"
assert_file_not_exists "$marker"
