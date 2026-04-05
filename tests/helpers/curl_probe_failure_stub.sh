#!/bin/sh

set -eu

case " $* " in
  *" %{url_effective} "*)
    exit 56
    ;;
esac

exec /usr/bin/curl "$@"
