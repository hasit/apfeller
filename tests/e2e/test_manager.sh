#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"
. "$ROOT_DIR/tests/helpers/framework_env.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

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
assert_contains "$install_output" "Installed fixture-cmd $fixture_cmd_revision" "install should report fixture-cmd success"
assert_contains "$install_output" "Installed fixture-define $fixture_define_revision" "install should report fixture-define success"
assert_contains "$install_output" "Installed fixture-oneliner $fixture_oneliner_revision" "install should report fixture-oneliner success"

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

installed_output=$(framework_run_manager list --installed)
assert_contains "$installed_output" "fixture-cmd	$fixture_cmd_revision	installed" "installed listing should include fixture-cmd"
assert_contains "$installed_output" "fixture-define	$fixture_define_revision	installed" "installed listing should include fixture-define"
assert_contains "$installed_output" "fixture-oneliner	$fixture_oneliner_revision	installed" "installed listing should include fixture-oneliner"

update_output=$(framework_run_manager update --all)
assert_contains "$update_output" "Installed fixture-cmd $fixture_cmd_revision" "update --all should reinstall ai-command apps"
assert_contains "$update_output" "Installed fixture-define $fixture_define_revision" "update --all should reinstall ai-text apps"
assert_contains "$update_output" "Installed fixture-oneliner $fixture_oneliner_revision" "update --all should reinstall the second ai-command app"

self_update_output=$(framework_run_manager update --self)
assert_contains "$self_update_output" 'Updated apfeller' "update --self should refresh the manager asset"
assert_file_exists "$TEST_HOME_DIR/.local/bin/apfeller"

doctor_output=$(framework_run_manager doctor)
assert_contains "$doctor_output" 'manager_path' "doctor should report manager path"
assert_contains "$doctor_output" 'legacy_state_json' "doctor should report legacy JSON status"

uninstall_output=$(framework_run_manager uninstall fixture-cmd fixture-define fixture-oneliner)
assert_contains "$uninstall_output" 'Removed fixture-cmd' "uninstall should report fixture-cmd removal"
assert_contains "$uninstall_output" 'Removed fixture-define' "uninstall should report fixture-define removal"
assert_contains "$uninstall_output" 'Removed fixture-oneliner' "uninstall should report fixture-oneliner removal"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/fixture-cmd"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/fixture-define"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/fixture-oneliner"
