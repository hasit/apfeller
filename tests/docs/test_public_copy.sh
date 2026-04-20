#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

readme=$(cat "$ROOT_DIR/README.md")
layout=$(cat "$ROOT_DIR/docs/_layouts/default.html")
site_css=$(cat "$ROOT_DIR/docs/assets/site.css")
site_js=$(cat "$ROOT_DIR/docs/assets/site.js")
home_page=$(cat "$ROOT_DIR/docs/home.md")
install_page=$(cat "$ROOT_DIR/docs/install.md")
usage_page=$(cat "$ROOT_DIR/docs/usage.md")
catalog_page=$(cat "$ROOT_DIR/docs/catalog.md")
catalog_js=$(cat "$ROOT_DIR/docs/assets/catalog.js")
write_page=$(cat "$ROOT_DIR/docs/write-an-app.md")

assert_contains "$readme" 'https://apfel.franzai.com/' "README should link to apfel"
assert_contains "$readme" 'fully local' "README should mention the local execution story"
assert_contains "$readme" 'zero API cost' "README should mention the zero API cost story"
assert_contains "$readme" 'https://hasit.github.io/apfeller/' "README should point users to the public docs site"
assert_contains "$readme" 'https://hasit.github.io/apfeller/write-an-app/' "README should point app authors to the public authoring guide"
assert_contains "$readme" 'scripts/package_release.sh' "README should document manager packaging"
assert_contains "$readme" 'scripts/package_catalog.sh' "README should document fixture packaging"
assert_contains "$readme" 'apfeller-apps' "README should describe the separate app repo"
assert_not_contains "$readme" 'https://github.com/Arthur-Ficial/apfel' "README should not link to the apfel source repo"

assert_contains "$layout" "/assets/site.css" "docs layout should load the shared stylesheet"
assert_contains "$layout" "/assets/site.js" "docs layout should load the shared script"
assert_contains "$layout" ">home<" "docs layout should include the home nav link"
assert_contains "$layout" ">catalog<" "docs layout should include the catalog nav link"
assert_contains "$layout" ">install<" "docs layout should include the install nav link"
assert_contains "$layout" ">write an app<" "docs layout should include the write-an-app nav link"
assert_contains "$layout" ">github<" "docs layout should include the GitHub nav link"
assert_contains "$layout" 'made by <a href="https://github.com/hasit">Hasit Mistry</a>' "docs layout should render the personal footer credit"
assert_contains "$layout" 'https://github.com/hasit/apfeller-apps' "docs layout should link to the published app repo"

assert_contains "$site_css" '.command-rail' "shared docs stylesheet should style command rails"
assert_contains "$site_css" '.copy-button' "shared docs stylesheet should style copy buttons"
assert_contains "$site_css" '.page-section-nav' "shared docs stylesheet should style the anchored section nav"
assert_contains "$site_css" '.site-footer' "shared docs stylesheet should style the shared footer"

assert_contains "$site_js" 'navigator.clipboard' "shared docs script should use the Clipboard API when available"
assert_contains "$site_js" 'execCommand("copy")' "shared docs script should fall back to execCommand copy"
assert_contains "$site_js" 'ApfellerSite' "shared docs script should expose a site helper namespace"
assert_contains "$site_js" '.command-rail[data-copy-text], .catalog-copyable[data-copy-text]' "shared docs script should enhance page and catalog copyable code"
assert_contains "$site_js" 'language-(sh|shell|bash|zsh|fish)' "shared docs script should target tagged shell code blocks"
assert_contains "$site_js" 'isSingleRunnableCommand' "shared docs script should only copy single runnable commands"

assert_contains "$home_page" 'layout: default' "home page should use the shared docs layout"
assert_contains "$home_page" 'https://apfel.franzai.com/' "home page should link to apfel"
assert_contains "$home_page" 'fully local' "home page should mention the local execution story"
assert_contains "$home_page" 'zero API cost' "home page should mention the zero API cost story"
assert_contains "$home_page" 'data-copy-text="curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh"' "home page should expose a copyable install rail"
assert_contains "$home_page" 'apfeller info <app>' "home page should show the inspect flow"
assert_contains "$home_page" '[Install apfeller](install/)' "home page should link to install"
assert_contains "$home_page" '[Browse the catalog](catalog/)' "home page should link to the catalog"
assert_contains "$home_page" '[Write an app](write-an-app/)' "home page should link to the app-authoring guide"
assert_not_contains "$home_page" '## AI Apps' "home page should not hardcode an AI apps section anymore"
assert_not_contains "$home_page" '## Start Here' "home page should not repeat a separate start-here section"
assert_not_contains "$home_page" 'https://github.com/Arthur-Ficial/apfel' "home page should not link to the apfel source repo"
assert_not_contains "$home_page" '`cmd`' "home page should not hardcode published app ids"
assert_not_contains "$home_page" '`define`' "home page should not hardcode published app ids"
assert_not_contains "$home_page" '`oneliner`' "home page should not hardcode published app ids"

assert_contains "$install_page" 'layout: default' "install page should use the shared docs layout"
assert_contains "$install_page" 'curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh' "install page should show the public install command"
assert_contains "$install_page" 'apfeller doctor' "install page should tell users how to verify their setup"
assert_contains "$install_page" 'apfeller install <app>' "install page should show a generic first app install"
assert_contains "$install_page" '[Install apfeller](../install/)' "install page should use explicit guide labels"
assert_contains "$install_page" '[Browse the catalog](../catalog/)' "install page should use explicit guide labels"
assert_not_contains "$install_page" 'scripts/package_release.sh' "install page should not include maintainer packaging commands"
assert_not_contains "$install_page" 'scripts/package_catalog.sh' "install page should not include fixture packaging commands"
assert_not_contains "$install_page" 'fixtures/apps' "install page should not mention fixture app sources"
assert_not_contains "$install_page" 'https://github.com/Arthur-Ficial/apfel' "install page should not link to the apfel source repo"
assert_not_contains "$install_page" '`cmd`' "install page should not hardcode published app ids"
assert_not_contains "$install_page" '`define`' "install page should not hardcode published app ids"
assert_not_contains "$install_page" '`oneliner`' "install page should not hardcode published app ids"

assert_contains "$usage_page" 'layout: default' "usage page should use the shared docs layout"
assert_contains "$usage_page" 'apfeller list' "usage page should explain catalog browsing"
assert_contains "$usage_page" 'apfeller info <app>' "usage page should explain app inspection"
assert_contains "$usage_page" 'apfeller update --all' "usage page should explain updating apps"
assert_contains "$usage_page" 'apfeller doctor' "usage page should explain troubleshooting"
assert_contains "$usage_page" '[Install apfeller](../install/)' "usage page should use explicit guide labels"
assert_contains "$usage_page" '[Browse the catalog](../catalog/)' "usage page should use explicit guide labels"
assert_not_contains "$usage_page" 'scripts/package_release.sh' "usage page should not include maintainer packaging commands"
assert_not_contains "$usage_page" 'scripts/package_catalog.sh' "usage page should not include fixture packaging commands"
assert_not_contains "$usage_page" 'GitHub Actions' "usage page should not mention CI internals"
assert_not_contains "$usage_page" '`cmd`' "usage page should not hardcode published app ids"
assert_not_contains "$usage_page" '`define`' "usage page should not hardcode published app ids"
assert_not_contains "$usage_page" '`oneliner`' "usage page should not hardcode published app ids"

assert_contains "$catalog_page" 'layout: default' "catalog page should use the shared docs layout"
assert_contains "$catalog_page" '../assets/catalog.css' "catalog page should load its stylesheet asset"
assert_contains "$catalog_page" '../assets/catalog.js' "catalog page should load its script asset"
assert_contains "$catalog_page" 'https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv' "catalog page should point users to the published raw catalog"
assert_contains "$catalog_page" 'Select an app row' "catalog page should explain that rows drive the detail pane"
assert_not_contains "$catalog_page" 'Click any app card' "catalog page should no longer describe the catalog as cards"
assert_contains "$catalog_page" '[Install apfeller](../install/)' "catalog page should use explicit guide labels"
assert_not_contains "$catalog_page" '`cmd`' "catalog page should not hardcode current app ids in markdown"
assert_not_contains "$catalog_page" '`define`' "catalog page should not hardcode current app ids in markdown"
assert_not_contains "$catalog_page" '`oneliner`' "catalog page should not hardcode current app ids in markdown"

assert_contains "$catalog_js" 'https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv' "catalog script should fetch the published raw catalog"
assert_contains "$catalog_js" 'https://github.com/hasit/apfeller-apps/tree/main/apps/' "catalog script should link each entry back to its source directory"
assert_contains "$catalog_js" 'https://raw.githubusercontent.com/hasit/apfeller-apps/main/apps/' "catalog script should fetch app manifests for expanded details"
assert_contains "$catalog_js" 'https://api.github.com/repos/hasit/apfeller-apps/releases?per_page=100' "catalog script should fetch release stats from the published app repo"
assert_contains "$catalog_js" 'download_count' "catalog script should read download counts from release assets"
assert_contains "$catalog_js" 'downloads' "catalog script should render per-app download stats"
assert_contains "$catalog_js" 'aria-pressed' "catalog script should render accessible row-selection controls"
assert_contains "$catalog_js" 'catalog-table' "catalog script should render the catalog as a table"
assert_contains "$catalog_js" 'catalog-detail-host' "catalog script should render a dedicated detail pane host"
assert_contains "$catalog_js" 'catalog-detail-shell' "catalog script should render selected app details below the table"
assert_contains "$catalog_js" 'TABLE_COLUMN_COUNT' "catalog script should track the compact table column count"
assert_contains "$catalog_js" 'renderDetailPaneMarkup' "catalog script should build the selected app detail pane"
assert_contains "$catalog_js" 'catalog-tablist' "catalog script should render accessible detail tabs"
assert_contains "$catalog_js" 'catalog-tabpanel' "catalog script should render accessible tab panels"
assert_contains "$catalog_js" 'stopPropagation' "catalog script should keep row-button clicks from double-triggering selection"
assert_contains "$catalog_js" 'usage' "catalog script should render usage from app manifests"
assert_contains "$catalog_js" 'examples' "catalog script should render examples from app manifests"
assert_contains "$catalog_js" '[[args]]' "catalog script should parse app-specific args"
assert_contains "$catalog_js" 'Loading current catalog' "catalog script should support a loading state"
assert_contains "$catalog_js" 'No apps are currently published.' "catalog script should support an empty state"
assert_contains "$catalog_js" 'Could not load the published catalog.' "catalog script should support a fetch failure state"
assert_contains "$catalog_js" 'catalog-copyable' "catalog script should render copyable install and example code"
assert_contains "$catalog_js" 'data-copy-text' "catalog script should expose copy text for sitewide enhancement"
assert_contains "$catalog_js" 'ApfellerSite.enhanceCopyables' "catalog script should re-run copy enhancements after detail rerenders"
assert_not_contains "$catalog_js" 'loaded.' "catalog script should not show a top-level app count after loading"
assert_not_contains "$catalog_js" 'catalog-card' "catalog script should no longer render expandable cards"
assert_not_contains "$catalog_js" 'catalog-detail-row' "catalog script should no longer render inline detail rows"
assert_not_contains "$catalog_js" '/contents/' "catalog script should not use the GitHub directory listing API"

assert_contains "$write_page" 'layout: default' "authoring page should use the shared docs layout"
assert_contains "$write_page" 'apps/<id>/app.toml' "authoring page should explain where app manifests live"
assert_contains "$write_page" 'hooks/' "authoring page should explain optional hook locations"
assert_contains "$write_page" '[[args]]' "authoring page should document optional args blocks"
assert_contains "$write_page" 'kind = "ai-text"' "authoring page should include a complete minimal example"
assert_contains "$write_page" 'APFELLER_CATALOG_URL="file://$PWD/dist/apfeller-catalog.tsv"' "authoring page should explain local catalog testing"
assert_contains "$write_page" 'sh scripts/package_catalog.sh --output-dir dist --bundle-base-url "file://$PWD/dist"' "authoring page should explain local packaging"
assert_contains "$write_page" '[Browse the catalog](../catalog/)' "authoring page should use explicit guide labels"
assert_not_contains "$write_page" 'workflow_dispatch' "authoring page should not document the release workflow"
assert_not_contains "$write_page" 'Publish' "authoring page should stay focused on writing and testing"

find "$ROOT_DIR/docs" -name '*.md' -print | while IFS= read -r markdown_path; do
  if ! grep -q '^layout: default$' "$markdown_path"; then
    printf '%s\n' "docs page does not use the shared default layout: $markdown_path" >&2
    exit 1
  fi
done

find "$ROOT_DIR/docs" -name '*.md' -print | while IFS= read -r markdown_path; do
  if awk '
    /^```/ {
      if (in_block) {
        if (shell_block && command_lines != 1) {
          exit 1
        }
        in_block = 0
        shell_block = 0
        command_lines = 0
        next
      }

      if ($0 !~ /^```[A-Za-z0-9_-]+[[:space:]]*$/) {
        exit 2
      }

      in_block = 1
      shell_block = ($0 ~ /^```(sh|shell|bash|zsh|fish)[[:space:]]*$/)
      command_lines = 0
      next
    }
    in_block && shell_block && $0 ~ /[^[:space:]]/ {
      command_lines++
    }
    END {
      if (in_block && shell_block && command_lines != 1) {
        exit 1
      }
    }
  ' "$markdown_path"; then
    :
  else
    status=$?
    if [ "$status" -eq 2 ]; then
      printf '%s\n' "docs page contains an untagged fenced code block: $markdown_path" >&2
    else
      printf '%s\n' "docs page contains a multi-command shell code block: $markdown_path" >&2
    fi
    exit 1
  fi
done

find "$ROOT_DIR/docs" -name '*.md' -print | while IFS= read -r markdown_path; do
  if ! awk '
    /^## Guides$/ {
      saw_guides = 1
      next
    }
    /^## / && saw_guides {
      exit 1
    }
    END {
      exit saw_guides ? 0 : 1
    }
  ' "$markdown_path"; then
    printf '%s\n' "docs page does not keep Guides as the final section: $markdown_path" >&2
    exit 1
  fi
done
