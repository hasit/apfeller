#!/bin/sh

set -eu

assert_eq() {
  expected=$1
  actual=$2
  message=${3:-}

  if [ "$expected" != "$actual" ]; then
    printf 'assert_eq failed\nexpected: %s\nactual: %s\n%s\n' "$expected" "$actual" "$message" >&2
    exit 1
  fi
}

assert_contains() {
  haystack=$1
  needle=$2
  message=${3:-}

  case "$haystack" in
    *"$needle"*)
      ;;
    *)
      printf 'assert_contains failed\nneedle: %s\n%s\n' "$needle" "$message" >&2
      exit 1
      ;;
  esac
}

assert_file_exists() {
  path=$1
  if [ ! -e "$path" ]; then
    printf 'Expected file to exist: %s\n' "$path" >&2
    exit 1
  fi
}

assert_file_not_exists() {
  path=$1
  if [ -e "$path" ]; then
    printf 'Expected file to be absent: %s\n' "$path" >&2
    exit 1
  fi
}
