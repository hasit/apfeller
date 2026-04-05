#!/bin/sh

set -eu

sleep "${APFELLER_CURL_STUB_SLEEP:-0.45}"
exec /usr/bin/curl "$@"
