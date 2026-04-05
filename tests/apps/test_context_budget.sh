#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

for app in cmd oneliner define; do
  script_path="$ROOT_DIR/apps/$app/bin/$app"

  max_context_tokens=$(sed -n 's/^MAX_CONTEXT_TOKENS=\([0-9][0-9]*\)$/\1/p' "$script_path")
  max_input_bytes=$(sed -n 's/^MAX_INPUT_BYTES=\([0-9][0-9]*\)$/\1/p' "$script_path")
  max_output_tokens=$(sed -n 's/^MAX_OUTPUT_TOKENS=\([0-9][0-9]*\)$/\1/p' "$script_path")
  system_prompt=$(sed -n "s/^system_prompt='\\(.*\\)'$/\\1/p" "$script_path")

  [ -n "$max_context_tokens" ] || fail "Missing MAX_CONTEXT_TOKENS in $script_path"
  [ -n "$max_input_bytes" ] || fail "Missing MAX_INPUT_BYTES in $script_path"
  [ -n "$max_output_tokens" ] || fail "Missing MAX_OUTPUT_TOKENS in $script_path"
  [ -n "$system_prompt" ] || fail "Missing system_prompt in $script_path"

  [ "$max_context_tokens" = "4096" ] || fail "$app must declare MAX_CONTEXT_TOKENS=4096"

  prompt_bytes=$(LC_ALL=C printf '%s' "$system_prompt" | wc -c | awk '{print $1}')
  total_budget=$((prompt_bytes + max_input_bytes + max_output_tokens + 256))

  if [ "$total_budget" -gt "$max_context_tokens" ]; then
    fail "$app exceeds the 4096-token budget: $total_budget"
  fi
done
