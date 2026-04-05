#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

readme=$(cat "$ROOT_DIR/README.md")
home_page=$(cat "$ROOT_DIR/docs/home.md")
install_page=$(cat "$ROOT_DIR/docs/install.md")
usage_page=$(cat "$ROOT_DIR/docs/usage.md")

assert_contains "$readme" 'https://apfel.franzai.com/' "README should link to apfel"
assert_contains "$readme" 'https://github.com/Arthur-Ficial/apfel' "README should link to the apfel source repo"
assert_contains "$readme" 'fully local' "README should mention the local execution story"
assert_contains "$readme" 'zero API cost' "README should mention the zero API cost story"
assert_contains "$readme" 'https://hasit.github.io/apfeller/' "README should point users to the public docs site"
assert_contains "$readme" 'scripts/package_release.sh' "README should document manager packaging"
assert_contains "$readme" 'scripts/package_catalog.sh' "README should document fixture packaging"
assert_contains "$readme" 'apfeller-apps' "README should describe the separate app repo"

assert_contains "$home_page" 'https://apfel.franzai.com/' "home page should link to apfel"
assert_contains "$home_page" 'fully local' "home page should mention the local execution story"
assert_contains "$home_page" 'zero API cost' "home page should mention the zero API cost story"
assert_contains "$home_page" '## AI Apps' "home page should have an AI apps section"
assert_contains "$home_page" '[Use apfeller](usage)' "home page should link to the usage guide"
assert_not_contains "$home_page" '[Releasing](releasing)' "home page should not link to maintainer docs"

home_ai_section=$(awk '
  /^## AI Apps$/ { in_section = 1; next }
  /^## / && in_section { exit }
  in_section { print }
' "$ROOT_DIR/docs/home.md")

assert_contains "$home_ai_section" '`cmd`' "home page AI section should include cmd"
assert_contains "$home_ai_section" '`oneliner`' "home page AI section should include oneliner"
assert_contains "$home_ai_section" '`define`' "home page AI section should include define"
assert_not_contains "$home_ai_section" '`port`' "home page should not label port as an AI app"
assert_not_contains "$home_page" '`port`' "home page should not mention port anymore"

assert_contains "$install_page" 'curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh' "install page should show the public install command"
assert_contains "$install_page" 'apfeller doctor' "install page should tell users how to verify their setup"
assert_contains "$install_page" 'apfeller install cmd' "install page should show a first app install"
assert_not_contains "$install_page" 'scripts/package_release.sh' "install page should not include maintainer packaging commands"
assert_not_contains "$install_page" 'scripts/package_catalog.sh' "install page should not include fixture packaging commands"
assert_not_contains "$install_page" 'fixtures/apps' "install page should not mention fixture app sources"

assert_contains "$usage_page" 'apfeller list' "usage page should explain catalog browsing"
assert_contains "$usage_page" 'apfeller info cmd' "usage page should explain app inspection"
assert_contains "$usage_page" 'apfeller update --all' "usage page should explain updating apps"
assert_contains "$usage_page" 'apfeller doctor' "usage page should explain troubleshooting"
assert_not_contains "$usage_page" 'scripts/package_release.sh' "usage page should not include maintainer packaging commands"
assert_not_contains "$usage_page" 'scripts/package_catalog.sh' "usage page should not include fixture packaging commands"
assert_not_contains "$usage_page" 'GitHub Actions' "usage page should not mention CI internals"
