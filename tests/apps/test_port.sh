#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"
. "$ROOT_DIR/tests/helpers/framework_env.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

setup_framework_env "$ROOT_DIR" "$tmp_dir"
framework_run_manager install port >/dev/null

output=$(framework_run_app port 65535)
assert_contains "$output" 'Port 65535 is not in use.' "port should report unused ports cleanly"

help_output=$(framework_run_app port --help)
assert_contains "$help_output" '--all' "port help should include generated local-command args"
assert_contains "$help_output" 'port -a 5432' "port help should include examples from TOML"

set +e
invalid_output=$(framework_run_app port nope 2>&1)
status=$?
set -e

if [ "$status" -eq 0 ]; then
  printf '%s\n' "expected port to reject invalid input" >&2
  exit 1
fi

assert_contains "$invalid_output" 'port must be a number between 1 and 65535' "port should preserve local hook validation"
