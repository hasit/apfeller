#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"
. "$ROOT_DIR/tests/helpers/framework_env.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

setup_framework_env "$ROOT_DIR" "$tmp_dir"
framework_run_manager install define >/dev/null

args_file="$tmp_dir/define-args.txt"
stub_output='word: hola lang: es meaning: hello example: hola amiga (hello friend)'
output=$(
  APFELLER_STUB_ARGS_FILE="$args_file" \
  APFELLER_STUB_OUTPUT="$stub_output" \
  framework_run_app define -i es -o en hola
)

assert_contains "$output" 'word: hola' "define should print the word field"
assert_contains "$output" 'lang: es' "define should print the language field"
assert_contains "$output" 'meaning: hello' "define should print the meaning field"
assert_contains "$output" 'example: hola amiga (hello friend)' "define should print the example field"

stub_args=$(cat "$args_file")
assert_contains "$stub_args" 'Input language: es. Output language: en. Term: hola' "define should render the prompt template with declared args"

help_output=$(framework_run_app define --help)
assert_contains "$help_output" '-c, --copy' "define help should include the generated copy flag"
assert_contains "$help_output" '--in VALUE' "define help should include declared string args"
assert_contains "$help_output" '(default: auto)' "define help should show arg defaults"
assert_contains "$help_output" '(default: en)' "define help should show output language defaults"

cat >"$TEST_STUB_DIR/pbcopy" <<'EOF'
#!/bin/sh
cat >"$APFELLER_PBCOPY_CAPTURE"
EOF
chmod +x "$TEST_STUB_DIR/pbcopy"

copy_capture="$tmp_dir/copied-define.txt"
copy_output=$(
  APFELLER_PBCOPY_CAPTURE="$copy_capture" \
  APFELLER_STUB_OUTPUT="$stub_output" \
  framework_run_app define -c hola
)

assert_contains "$copy_output" '(copied)' "define copy mode should report clipboard success"
assert_contains "$(cat "$copy_capture")" 'meaning: hello' "define should copy the formatted response"

set +e
missing_field_output=$(
  APFELLER_STUB_OUTPUT='word: hola lang: es meaning: hello' \
  framework_run_app define hola 2>&1
)
missing_status=$?
set -e

if [ "$missing_status" -eq 0 ]; then
  printf '%s\n' "expected define to reject missing structured fields" >&2
  exit 1
fi

assert_contains "$missing_field_output" 'missing field: example' "define should reject incomplete structured output"

too_large=$(awk 'BEGIN { for (i = 0; i < 900; i++) printf "c" }')
marker="$tmp_dir/define-apfel-called"

set +e
oversized_output=$(
  APFELLER_STUB_MARKER="$marker" \
  APFELLER_STUB_FAIL_IF_CALLED=1 \
  framework_run_app define "$too_large" 2>&1
)
status=$?
set -e

if [ "$status" -eq 0 ]; then
  printf '%s\n' "expected define to reject oversized input" >&2
  exit 1
fi

assert_contains "$oversized_output" "Input too large for define" "define should explain the context budget limit"
assert_file_not_exists "$marker"
