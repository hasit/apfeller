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
