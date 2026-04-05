#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

readme=$(cat "$ROOT_DIR/README.md")
home_page=$(cat "$ROOT_DIR/docs/home.md")

assert_contains "$readme" 'https://apfel.franzai.com/' "README should link to apfel"
assert_contains "$readme" 'https://github.com/Arthur-Ficial/apfel' "README should link to the apfel source repo"
assert_contains "$readme" 'fully local' "README should mention the local execution story"
assert_contains "$readme" 'zero API cost' "README should mention the zero API cost story"
assert_contains "$readme" '## AI Apps' "README should separate AI apps from utilities"
assert_contains "$readme" '## Local Utility' "README should separate the local utility section"

readme_ai_section=$(awk '
  /^## AI Apps$/ { in_section = 1; next }
  /^## / && in_section { exit }
  in_section { print }
' "$ROOT_DIR/README.md")

readme_local_section=$(awk '
  /^## Local Utility$/ { in_section = 1; next }
  /^## / && in_section { exit }
  in_section { print }
' "$ROOT_DIR/README.md")

assert_contains "$readme_ai_section" '`cmd`' "README AI section should include cmd"
assert_contains "$readme_ai_section" '`oneliner`' "README AI section should include oneliner"
assert_contains "$readme_ai_section" '`define`' "README AI section should include define"
assert_not_contains "$readme_ai_section" '`port`' "README should not label port as an AI app"
assert_contains "$readme_local_section" '`port`' "README local utility section should include port"

assert_contains "$home_page" 'https://apfel.franzai.com/' "home page should link to apfel"
assert_contains "$home_page" 'fully local' "home page should mention the local execution story"
assert_contains "$home_page" 'zero API cost' "home page should mention the zero API cost story"
assert_contains "$home_page" '## AI Apps' "home page should have an AI apps section"
assert_contains "$home_page" '## Local Utility' "home page should have a local utility section"

home_ai_section=$(awk '
  /^## AI Apps$/ { in_section = 1; next }
  /^## / && in_section { exit }
  in_section { print }
' "$ROOT_DIR/docs/home.md")

home_local_section=$(awk '
  /^## Local Utility$/ { in_section = 1; next }
  /^## / && in_section { exit }
  in_section { print }
' "$ROOT_DIR/docs/home.md")

assert_contains "$home_ai_section" '`cmd`' "home page AI section should include cmd"
assert_contains "$home_ai_section" '`oneliner`' "home page AI section should include oneliner"
assert_contains "$home_ai_section" '`define`' "home page AI section should include define"
assert_not_contains "$home_ai_section" '`port`' "home page should not label port as an AI app"
assert_contains "$home_local_section" '`port`' "home page local utility section should include port"
