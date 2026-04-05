#!/bin/sh

apfeller_require_apfel() {
  if command -v "${APFELLER_APFEL_BIN:-apfel}" >/dev/null 2>&1; then
    return 0
  fi

  printf '%s\n' "Error: apfel not found. Install with: brew install Arthur-Ficial/tap/apfel" >&2
  return 127
}

apfeller_count_bytes() {
  LC_ALL=C printf '%s' "$1" | wc -c | awk '{print $1}'
}

apfeller_require_context_budget() {
  app_name=$1
  max_context_tokens=$2
  max_input_bytes=$3
  max_output_tokens=$4
  user_prompt=$5

  prompt_bytes=$(apfeller_count_bytes "$user_prompt")
  effective_limit=$((max_context_tokens - max_output_tokens - 256))
  if [ "$max_input_bytes" -lt "$effective_limit" ]; then
    effective_limit=$max_input_bytes
  fi

  if [ "$prompt_bytes" -gt "$effective_limit" ]; then
    printf '%s\n' "Input too large for $app_name; keep it under $effective_limit bytes so it fits apfel's ${max_context_tokens}-token window." >&2
    return 1
  fi
}

apfeller_query() {
  max_tokens=$1
  system_prompt=$2
  user_prompt=$3

  apfeller_require_apfel || return $?

  "${APFELLER_APFEL_BIN:-apfel}" \
    -q \
    --no-color \
    --temperature 0 \
    --seed 1 \
    --max-tokens "$max_tokens" \
    -s "$system_prompt" \
    "$user_prompt"
}

apfeller_clean_command() {
  cleaned=$(
    printf '%s\n' "$1" | awk '
      {
        gsub(/^[[:space:]]+/, "", $0)
        gsub(/[[:space:]]+$/, "", $0)
        if ($0 == "" || $0 ~ /^```/ || $0 ~ /^#/) {
          next
        }
        sub(/^\$[[:space:]]*/, "", $0)
        print
        exit
      }
    '
  )

  [ -n "$cleaned" ] || return 1
  printf '%s\n' "$cleaned"
}

apfeller_copy() {
  if ! command -v pbcopy >/dev/null 2>&1; then
    printf '%s\n' "Error: pbcopy not found." >&2
    return 127
  fi

  printf '%s' "$1" | pbcopy
}

apfeller_confirm() {
  prompt=$1
  printf '%s' "$prompt"
  IFS= read -r response || return 1

  case "$response" in
    y|Y)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

apfeller_emit_command() {
  max_tokens=$1
  system_prompt=$2
  request=$3
  should_copy=$4
  should_execute=$5

  response=$(apfeller_query "$max_tokens" "$system_prompt" "$request") || return $?
  command=$(apfeller_clean_command "$response") || {
    printf '%s\n' "Error: apfel did not return a usable command." >&2
    return 1
  }

  printf '$ %s\n' "$command"

  if [ "$should_copy" = "1" ]; then
    apfeller_copy "$command" || return $?
    printf '%s\n' "(copied)"
  fi

  if [ "$should_execute" = "1" ] && apfeller_confirm "Run this? [y/N] "; then
    /bin/sh -c "$command"
  fi
}
