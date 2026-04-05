#!/bin/sh

set -eu

port_number=${APFELLER_INPUT:-}
show_all=${APFELLER_ARG_ALL:-0}

case "$port_number" in
  ''|*[!0-9]*)
    printf '%s\n' "Error: port must be a number between 1 and 65535." >&2
    exit 1
    ;;
esac

if [ "$port_number" -lt 1 ] || [ "$port_number" -gt 65535 ]; then
  printf '%s\n' "Error: port must be a number between 1 and 65535." >&2
  exit 1
fi

if [ "$show_all" = "1" ]; then
  output=$(lsof -nP -i :"$port_number" 2>/dev/null || true)
else
  output=$(lsof -nP -iTCP:"$port_number" -sTCP:LISTEN 2>/dev/null || true)
  if [ -z "$output" ]; then
    output=$(lsof -nP -i :"$port_number" 2>/dev/null || true)
  fi
fi

if [ -z "$output" ]; then
  printf 'Port %s is not in use.\n' "$port_number"
  exit 0
fi

printf '%s\n' "$output"
