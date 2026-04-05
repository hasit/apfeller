#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"
. "$ROOT_DIR/tests/helpers/framework_env.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

setup_framework_env "$ROOT_DIR" "$tmp_dir"
framework_run_manager install oneliner >/dev/null

args_file="$tmp_dir/oneliner-args.txt"
output=$(
  APFELLER_STUB_ARGS_FILE="$args_file" \
  APFELLER_STUB_OUTPUT='awk -F, "{sum += \$3} END {print sum}" file.csv' \
  framework_run_app oneliner "sum the third column"
)

assert_contains "$output" '$ awk -F, "{sum += \$3} END {print sum}" file.csv' "oneliner should print the generated pipeline"
stub_args=$(cat "$args_file")
assert_contains "$stub_args" 'sum the third column' "oneliner should pass the rendered request to apfel"

help_output=$(framework_run_app oneliner --help)
assert_contains "$help_output" '-c, --copy' "oneliner help should include the generated copy flag"
assert_contains "$help_output" '-x, --execute' "oneliner help should include the generated execute flag"
assert_contains "$help_output" 'oneliner -x "count unique IPs in access.log"' "oneliner help should include examples from TOML"

too_large=$(awk 'BEGIN { for (i = 0; i < 1100; i++) printf "b" }')
marker="$tmp_dir/oneliner-apfel-called"

set +e
oversized_output=$(
  APFELLER_STUB_MARKER="$marker" \
  APFELLER_STUB_FAIL_IF_CALLED=1 \
  framework_run_app oneliner "$too_large" 2>&1
)
status=$?
set -e

if [ "$status" -eq 0 ]; then
  printf '%s\n' "expected oneliner to reject oversized input" >&2
  exit 1
fi

assert_contains "$oversized_output" "Input too large for oneliner" "oneliner should explain the context budget limit"
assert_file_not_exists "$marker"
