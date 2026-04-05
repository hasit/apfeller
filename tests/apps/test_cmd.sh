#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"
. "$ROOT_DIR/tests/helpers/framework_env.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

setup_framework_env "$ROOT_DIR" "$tmp_dir"
framework_run_manager install cmd >/dev/null

args_file="$tmp_dir/cmd-args.txt"
output=$(
  APFELLER_STUB_ARGS_FILE="$args_file" \
  APFELLER_STUB_OUTPUT='find . -name "*.log"' \
  framework_run_app cmd "find all log files"
)

assert_contains "$output" '$ find . -name "*.log"' "cmd should print the generated command"
stub_args=$(cat "$args_file")
assert_contains "$stub_args" 'find all log files' "cmd should pass the rendered request to apfel"

help_output=$(framework_run_app cmd --help)
assert_contains "$help_output" '-c, --copy' "cmd help should include the generated copy flag"
assert_contains "$help_output" '-x, --execute' "cmd help should include the generated execute flag"
assert_contains "$help_output" 'cmd -x "what process is using port 3000"' "cmd help should include examples from TOML"

cat >"$TEST_STUB_DIR/pbcopy" <<'EOF'
#!/bin/sh
cat >"$APFELLER_PBCOPY_CAPTURE"
EOF
chmod +x "$TEST_STUB_DIR/pbcopy"

copy_capture="$tmp_dir/copied-command.txt"
copy_output=$(
  APFELLER_PBCOPY_CAPTURE="$copy_capture" \
  APFELLER_STUB_OUTPUT='git status --short' \
  framework_run_app cmd -c "show git changes"
)

assert_contains "$copy_output" '(copied)' "cmd copy mode should report clipboard success"
assert_eq 'git status --short' "$(cat "$copy_capture")" "cmd should copy the generated command"

execute_output=$(
  printf 'y\n' | APFELLER_STUB_OUTPUT='printf framework-ran' framework_run_app cmd -x "run a tiny command"
)
assert_contains "$execute_output" '$ printf framework-ran' "cmd execute mode should still print the command"
assert_contains "$execute_output" 'framework-ran' "cmd execute mode should run the confirmed command"

too_large=$(awk 'BEGIN { for (i = 0; i < 1100; i++) printf "a" }')
marker="$tmp_dir/cmd-apfel-called"

set +e
oversized_output=$(
  APFELLER_STUB_MARKER="$marker" \
  APFELLER_STUB_FAIL_IF_CALLED=1 \
  framework_run_app cmd "$too_large" 2>&1
)
status=$?
set -e

if [ "$status" -eq 0 ]; then
  printf '%s\n' "expected cmd to reject oversized input" >&2
  exit 1
fi

assert_contains "$oversized_output" "Input too large for cmd" "cmd should explain the context budget limit"
assert_file_not_exists "$marker"
