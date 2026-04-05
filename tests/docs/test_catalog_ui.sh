#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

if ! command -v node >/dev/null 2>&1; then
  printf '%s\n' "node is required to run catalog UI tests" >&2
  exit 1
fi

node "$ROOT_DIR/tests/docs/test_catalog_ui.js"
