#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

output=$("$ROOT_DIR/apps/port/bin/port" 65535)
assert_contains "$output" 'Port 65535 is not in use.' "port should report unused ports cleanly"
