#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"
. "$ROOT_DIR/tests/helpers/framework_env.sh"

BASE_PATH=/usr/bin:/bin:/usr/sbin:/sbin

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

sanitize_pty_output() {
  perl -pe 's/\e\[[0-9;]*[A-Za-z]//g; s/\r/\n/g; s/[\x04\x08]//g; s/\^D//g'
}

run_pty_script() {
  script_path=$1
  /usr/bin/script -q /dev/null /bin/sh "$script_path" 2>/dev/null | sanitize_pty_output
}

setup_framework_env "$ROOT_DIR" "$tmp_dir"
catalog_path="$TEST_CATALOG_PATH"
fixture_cmd_revision=$(awk -F '\t' 'NR > 1 && $1 == "fixture-cmd" { print $2; exit }' "$catalog_path")
fixture_define_revision=$(awk -F '\t' 'NR > 1 && $1 == "fixture-define" { print $2; exit }' "$catalog_path")
fixture_oneliner_revision=$(awk -F '\t' 'NR > 1 && $1 == "fixture-oneliner" { print $2; exit }' "$catalog_path")
fixture_cmd_bundle_url=$(awk -F '\t' 'NR > 1 && $1 == "fixture-cmd" { print $9; exit }' "$catalog_path")

list_output=$(framework_run_manager list)
assert_contains "$list_output" "fixture-cmd	$fixture_cmd_revision	available" "catalog listing should include fixture-cmd with its revision"
assert_contains "$list_output" "fixture-define	$fixture_define_revision	available" "catalog listing should include fixture-define with its revision"
assert_contains "$list_output" "fixture-oneliner	$fixture_oneliner_revision	available" "catalog listing should include fixture-oneliner with its revision"
assert_not_contains "$list_output" 'port' "catalog listing should not include removed non-apfel apps"

info_output=$(framework_run_manager info fixture-cmd)
assert_contains "$info_output" 'id: fixture-cmd' "info should show the requested app"
assert_contains "$info_output" "revision: $fixture_cmd_revision" "info should expose the generated revision"
assert_contains "$info_output" 'command: fixture-cmd' "info should expose the generated command name"
assert_contains "$info_output" 'kind: ai-command' "info should expose the app kind"
assert_contains "$info_output" "bundle_url: $fixture_cmd_bundle_url" "info should show the bundle URL"

install_output=$(framework_run_manager install fixture-cmd fixture-define fixture-oneliner)
assert_contains "$install_output" 'Updated apfeller' "install should self-update the manager before app installs when using a direct archive override"
assert_contains "$install_output" "Installed fixture-cmd $fixture_cmd_revision" "install should report fixture-cmd success"
assert_contains "$install_output" "Installed fixture-define $fixture_define_revision" "install should report fixture-define success"
assert_contains "$install_output" "Installed fixture-oneliner $fixture_oneliner_revision" "install should report fixture-oneliner success"
install_update_count=$(printf '%s\n' "$install_output" | grep -c 'Updated apfeller')
assert_eq "1" "$install_update_count" "auto self-update during install should only happen once"

assert_file_exists "$TEST_HOME_DIR/.local/bin/fixture-cmd"
assert_file_exists "$TEST_HOME_DIR/.local/bin/fixture-define"
assert_file_exists "$TEST_HOME_DIR/.local/bin/fixture-oneliner"
assert_file_exists "$TEST_HOME_DIR/.local/share/apfeller/state.tsv"
assert_file_exists "$TEST_HOME_DIR/.config/fish/completions/fixture-cmd.fish"
assert_file_exists "$TEST_HOME_DIR/.config/apfeller/completions/zsh/_fixture-define"

cmd_output=$(APFELLER_STUB_OUTPUT='ls -la' framework_run_app fixture-cmd "list files")
assert_contains "$cmd_output" '$ ls -la' "installed ai-command apps should run through generated wrappers"

define_output=$(APFELLER_STUB_OUTPUT='word: hola lang: es meaning: hello example: hola amiga (hello friend)' framework_run_app fixture-define hola)
assert_contains "$define_output" 'meaning: hello' "installed ai-text apps should format structured output"

oneliner_output=$(APFELLER_STUB_OUTPUT='awk "{print \$1}" file.txt' framework_run_app fixture-oneliner "print first column")
assert_contains "$oneliner_output" '$ awk "{print \$1}" file.txt' "installed ai-command apps should support multiple command-style apps"

installed_catalog_output=$(framework_run_manager list)
assert_contains "$installed_catalog_output" "fixture-cmd	$fixture_cmd_revision	installed" "catalog listing should show installed apps as installed"
assert_contains "$installed_catalog_output" "fixture-define	$fixture_define_revision	installed" "catalog listing should show installed apps as installed"

installed_output=$(framework_run_manager list --installed)
assert_contains "$installed_output" "fixture-cmd	$fixture_cmd_revision	installed	$fixture_cmd_revision" "installed listing should include fixture-cmd and the catalog revision"
assert_contains "$installed_output" "fixture-define	$fixture_define_revision	installed	$fixture_define_revision" "installed listing should include fixture-define and the catalog revision"
assert_contains "$installed_output" "fixture-oneliner	$fixture_oneliner_revision	installed	$fixture_oneliner_revision" "installed listing should include fixture-oneliner and the catalog revision"

tty_list_runner="$tmp_dir/list-tty.sh"
cat >"$tty_list_runner" <<EOF
#!/bin/sh
set -eu
HOME=$TEST_HOME_DIR
PATH=$TEST_HOME_DIR/.local/bin:$TEST_STUB_DIR:$BASE_PATH
TERM=xterm-256color
APFELLER_SHELL=zsh
APFELLER_CATALOG_URL=file://$TEST_CATALOG_PATH
APFELLER_INSTALL_URL=file://$TEST_DIST_DIR/apfeller.tar.gz
export HOME PATH TERM APFELLER_SHELL APFELLER_CATALOG_URL APFELLER_INSTALL_URL
apfeller list
printf '\n'
apfeller list --installed
EOF
chmod +x "$tty_list_runner"

tty_list_output=$(run_pty_script "$tty_list_runner")
printf '%s\n' "$tty_list_output" | grep -Eq '^APP[[:space:]]+REVISION[[:space:]]+STATUS[[:space:]]+SUMMARY$' || {
  printf '%s\n' "expected tty list output to render column headers" >&2
  exit 1
}
printf '%s\n' "$tty_list_output" | grep -Eq '^APP[[:space:]]+INSTALLED[[:space:]]+STATUS[[:space:]]+PUBLISHED$' || {
  printf '%s\n' "expected tty installed list output to render column headers" >&2
  exit 1
}
assert_contains "$tty_list_output" 'fixture-cmd' "tty list output should include installed apps"
assert_not_contains "$tty_list_output" "$(printf 'fixture-cmd\t')" "tty list output should render aligned columns instead of raw tabs"

repeat_install_output=$(APFELLER_SKIP_AUTO_SELF_UPDATE=1 framework_run_manager install fixture-cmd)
assert_contains "$repeat_install_output" "Already installed fixture-cmd $fixture_cmd_revision" "install should skip apps that are already current"
assert_not_contains "$repeat_install_output" "Installed fixture-cmd $fixture_cmd_revision" "install should not reinstall an unchanged app"

update_single_output=$(framework_run_manager update fixture-cmd)
assert_contains "$update_single_output" "Already up to date fixture-cmd $fixture_cmd_revision" "update should skip apps that are already current"

tmp_state="$tmp_dir/state.tsv"
awk -F '\t' -v OFS='\t' '
  NR == 1 {
    print
    next
  }
  $1 == "fixture-cmd" {
    $2 = "fixture-cmd-old"
  }
  {
    print
  }
' "$TEST_HOME_DIR/.local/share/apfeller/state.tsv" >"$tmp_state"
mv "$tmp_state" "$TEST_HOME_DIR/.local/share/apfeller/state.tsv"

outdated_catalog_output=$(framework_run_manager list)
assert_contains "$outdated_catalog_output" "fixture-cmd	$fixture_cmd_revision	update-available" "catalog listing should show when an installed app is behind"

outdated_installed_output=$(framework_run_manager list --installed)
assert_contains "$outdated_installed_output" "fixture-cmd	fixture-cmd-old	update-available	$fixture_cmd_revision" "installed listing should show the installed and catalog revisions when an update is available"

update_output=$(framework_run_manager update fixture-cmd)
assert_contains "$update_output" "Updated fixture-cmd fixture-cmd-old -> $fixture_cmd_revision" "update should replace older installed revisions"

update_all_output=$(framework_run_manager update --all)
assert_contains "$update_all_output" "Already up to date fixture-cmd $fixture_cmd_revision" "update --all should skip current apps"
assert_contains "$update_all_output" "Already up to date fixture-define $fixture_define_revision" "update --all should skip current text apps"
assert_contains "$update_all_output" "Already up to date fixture-oneliner $fixture_oneliner_revision" "update --all should skip current command apps"
assert_not_contains "$update_all_output" "Installed fixture-cmd $fixture_cmd_revision" "update --all should not reinstall current apps"

filtered_catalog="$tmp_dir/catalog-without-define.tsv"
awk -F '\t' '
  NR == 1 || $1 != "fixture-define" {
    print
  }
' "$catalog_path" >"$filtered_catalog"

local_only_output=$(APFELLER_CATALOG_URL="file://$filtered_catalog" framework_run_manager list --installed)
assert_contains "$local_only_output" "fixture-define	$fixture_define_revision	local-only" "installed listing should show apps that are no longer in the catalog"

filtered_list_output=$(APFELLER_CATALOG_URL="file://$filtered_catalog" framework_run_manager list)
assert_not_contains "$filtered_list_output" 'fixture-define' "catalog listing should omit apps that are no longer published"

local_only_update_output=$(APFELLER_CATALOG_URL="file://$filtered_catalog" framework_run_manager update fixture-define 2>&1)
assert_contains "$local_only_update_output" 'fixture-define is installed locally, but it is no longer in the current catalog.' "update should warn when an installed app is no longer published"

doctor_output=$(framework_run_manager doctor)
assert_contains "$doctor_output" 'manager_path' "doctor should report manager path"
assert_contains "$doctor_output" 'apfel	ok' "doctor should report apfel readiness when apfel is present"
assert_contains "$doctor_output" 'legacy_state_json' "doctor should report legacy JSON status"

doctor_missing_apfel_output=$(
  HOME="$TEST_HOME_DIR" \
  PATH="$TEST_HOME_DIR/.local/bin:$BASE_PATH" \
  APFELLER_SHELL=zsh \
  APFELLER_CATALOG_URL="file://$TEST_CATALOG_PATH" \
  APFELLER_INSTALL_URL="file://$TEST_DIST_DIR/apfeller.tar.gz" \
  apfeller doctor
)
assert_contains "$doctor_missing_apfel_output" 'apfel	warn	Install with: brew install Arthur-Ficial/tap/apfel' "doctor should tell the user how to install apfel when it is missing"

probe_stub_dir="$tmp_dir/probe-stub"
mkdir -p "$probe_stub_dir"
cp "$ROOT_DIR/tests/helpers/curl_probe_failure_stub.sh" "$probe_stub_dir/curl"
chmod +x "$probe_stub_dir/curl"

probe_failure_install_output=$(
  HOME="$TEST_HOME_DIR" \
  PATH="$probe_stub_dir:$TEST_HOME_DIR/.local/bin:$TEST_STUB_DIR:$BASE_PATH" \
  APFELLER_SHELL=zsh \
  APFELLER_CATALOG_URL="file://$TEST_CATALOG_PATH" \
  APFELLER_INSTALL_URL="file://$TEST_DIST_DIR/apfeller.tar.gz" \
  apfeller install fixture-cmd 2>&1
)
assert_contains "$probe_failure_install_output" 'apfeller could not check for updates right now. Continuing with the installed version.' "install should continue when the manager update check fails"
assert_contains "$probe_failure_install_output" "Already installed fixture-cmd $fixture_cmd_revision" "install should still continue after a failed manager update check"

self_update_output=$(framework_run_manager update --self)
assert_contains "$self_update_output" 'Updated apfeller' "update --self should refresh the manager asset"
assert_file_exists "$TEST_HOME_DIR/.local/bin/apfeller"

uninstall_output=$(framework_run_manager uninstall fixture-cmd fixture-define fixture-oneliner)
assert_contains "$uninstall_output" 'Removed fixture-cmd' "uninstall should report fixture-cmd removal"
assert_contains "$uninstall_output" 'Removed fixture-define' "uninstall should report fixture-define removal"
assert_contains "$uninstall_output" 'Removed fixture-oneliner' "uninstall should report fixture-oneliner removal"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/fixture-cmd"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/fixture-define"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/fixture-oneliner"

set +e
update_missing_output=$(framework_run_manager update fixture-cmd 2>&1)
update_missing_status=$?
set -e

if [ "$update_missing_status" -eq 0 ]; then
  printf '%s\n' "expected update to fail when the app is not installed" >&2
  exit 1
fi

assert_contains "$update_missing_output" "fixture-cmd is not installed. Run 'apfeller install fixture-cmd' first." "update should point users at install when the app is available but not installed"
