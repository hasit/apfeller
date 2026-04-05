#!/bin/sh

set -eu

if [ -n "${APFELLER_STUB_MARKER:-}" ]; then
  : >"$APFELLER_STUB_MARKER"
fi

if [ "${APFELLER_STUB_FAIL_IF_CALLED:-0}" = "1" ]; then
  printf '%s\n' "apfel stub should not have been called" >&2
  exit 97
fi

if [ -n "${APFELLER_STUB_ARGS_FILE:-}" ]; then
  : >"$APFELLER_STUB_ARGS_FILE"
  for arg in "$@"; do
    printf '%s\n' "$arg" >>"$APFELLER_STUB_ARGS_FILE"
  done
fi

printf '%s\n' "${APFELLER_STUB_OUTPUT:-echo hello}"
