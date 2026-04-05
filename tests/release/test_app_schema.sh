#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

run_invalid_case() {
  case_name=$1
  rewrite_manifest=$2
  expected_message=$3

  tmp_dir=$(mktemp -d)
  repo_dir="$tmp_dir/repo"
  cp -R "$ROOT_DIR" "$repo_dir"

  sh -c "$rewrite_manifest" sh "$repo_dir"

  set +e
  output=$(
    APFELLER_ROOT_DIR="$repo_dir" \
    sh "$ROOT_DIR/scripts/package_release.sh" --output-dir "$tmp_dir/dist" 2>&1
  )
  status=$?
  set -e

  rm -rf "$tmp_dir"

  if [ "$status" -eq 0 ]; then
    printf 'expected packaging to fail for %s\n' "$case_name" >&2
    exit 1
  fi

  assert_contains "$output" "$expected_message" "$case_name should fail for the expected reason"
}

run_invalid_case \
  "invalid kind/output combination" \
  'cat >"$1/apps/cmd/app.toml" <<'"'"'EOF'"'"'
id = "cmd"
version = "0.1.0"
summary = "broken"
description = "broken"
command = "cmd"
kind = "ai-command"
requires_commands = ["apfel"]
supported_shells = ["fish", "zsh"]

[help]
usage = "cmd TEST"
examples = ["cmd test"]

[input]
mode = "rest"
name = "request"
required = true

[prompt]
system = "broken"
template = "{{input}}"
max_context_tokens = 4096
max_input_bytes = 100
max_output_tokens = 50

[output]
mode = "text"
EOF' \
  "Invalid kind/output combination"

run_invalid_case \
  "duplicate long flag" \
  'cat >"$1/apps/define/app.toml" <<'"'"'EOF'"'"'
id = "define"
version = "0.1.0"
summary = "broken"
description = "broken"
command = "define"
kind = "ai-text"
requires_commands = ["apfel"]
supported_shells = ["fish", "zsh"]

[help]
usage = "define TEST"
examples = ["define hola"]

[input]
mode = "rest"
name = "term"
required = true

[[args]]
name = "in"
type = "string"
long = "lang"
short = "i"
description = "Input language"
default = "auto"

[[args]]
name = "out"
type = "string"
long = "lang"
short = "o"
description = "Output language"
default = "en"

[prompt]
system = "broken"
template = "{{input}}"
max_context_tokens = 4096
max_input_bytes = 100
max_output_tokens = 50

[output]
mode = "structured_text"
fields = ["word", "lang", "meaning", "example"]
EOF' \
  "Duplicate long option"

run_invalid_case \
  "reserved arg name" \
  'cat >"$1/apps/define/app.toml" <<'"'"'EOF'"'"'
id = "define"
version = "0.1.0"
summary = "broken"
description = "broken"
command = "define"
kind = "ai-text"
requires_commands = ["apfel"]
supported_shells = ["fish", "zsh"]

[help]
usage = "define TEST"
examples = ["define hola"]

[input]
mode = "rest"
name = "term"
required = true

[[args]]
name = "copy"
type = "string"
long = "copy"
short = "i"
description = "Broken reserved arg"
default = "auto"

[prompt]
system = "broken"
template = "{{input}}"
max_context_tokens = 4096
max_input_bytes = 100
max_output_tokens = 50

[output]
mode = "text"
EOF' \
  "Reserved arg name"

run_invalid_case \
  "unsupported nested section" \
  'printf "%s\n" "[help.extra]" >>"$1/apps/cmd/app.toml"' \
  "Unsupported section syntax"

run_invalid_case \
  "removed local-command kind" \
  'cat >"$1/apps/cmd/app.toml" <<'"'"'EOF'"'"'
id = "cmd"
version = "0.1.0"
summary = "broken"
description = "broken"
command = "cmd"
kind = "local-command"
requires_commands = ["apfel"]
supported_shells = ["fish", "zsh"]

[help]
usage = "cmd TEST"
examples = ["cmd test"]

[input]
mode = "rest"
name = "request"
required = true

[output]
mode = "shell_command"
EOF' \
  "Unsupported kind"

run_invalid_case \
  "removed local_passthrough output" \
  'cat >"$1/apps/cmd/app.toml" <<'"'"'EOF'"'"'
id = "cmd"
version = "0.1.0"
summary = "broken"
description = "broken"
command = "cmd"
kind = "ai-command"
requires_commands = ["apfel"]
supported_shells = ["fish", "zsh"]

[help]
usage = "cmd TEST"
examples = ["cmd test"]

[input]
mode = "rest"
name = "request"
required = true

[prompt]
system = "broken"
template = "{{input}}"
max_context_tokens = 4096
max_input_bytes = 100
max_output_tokens = 50

[output]
mode = "local_passthrough"
EOF' \
  "Unsupported output mode"

run_invalid_case \
  "removed hooks.local_run key" \
  'cat >"$1/apps/cmd/app.toml" <<'"'"'EOF'"'"'
id = "cmd"
version = "0.1.0"
summary = "broken"
description = "broken"
command = "cmd"
kind = "ai-command"
requires_commands = ["apfel"]
supported_shells = ["fish", "zsh"]

[help]
usage = "cmd TEST"
examples = ["cmd test"]

[input]
mode = "rest"
name = "request"
required = true

[prompt]
system = "broken"
template = "{{input}}"
max_context_tokens = 4096
max_input_bytes = 100
max_output_tokens = 50

[output]
mode = "shell_command"

[hooks]
local_run = "hooks/local_run.sh"
EOF' \
  "Unsupported key hooks.local_run"
