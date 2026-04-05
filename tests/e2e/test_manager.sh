#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"
. "$ROOT_DIR/tests/helpers/framework_env.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

setup_framework_env "$ROOT_DIR" "$tmp_dir"
catalog_path="$TEST_CATALOG_PATH"
cmd_revision=$(awk -F '\t' 'NR > 1 && $1 == "cmd" { print $2; exit }' "$catalog_path")
define_revision=$(awk -F '\t' 'NR > 1 && $1 == "define" { print $2; exit }' "$catalog_path")
oneliner_revision=$(awk -F '\t' 'NR > 1 && $1 == "oneliner" { print $2; exit }' "$catalog_path")
cmd_bundle_url=$(awk -F '\t' 'NR > 1 && $1 == "cmd" { print $9; exit }' "$catalog_path")

list_output=$(framework_run_manager list)
assert_contains "$list_output" "cmd	$cmd_revision	available" "catalog listing should include cmd with its revision"
assert_contains "$list_output" "define	$define_revision	available" "catalog listing should include define with its revision"
assert_contains "$list_output" "oneliner	$oneliner_revision	available" "catalog listing should include oneliner with its revision"
assert_not_contains "$list_output" 'port' "catalog listing should not include removed non-apfel apps"

info_output=$(framework_run_manager info cmd)
assert_contains "$info_output" 'id: cmd' "info should show the requested app"
assert_contains "$info_output" "revision: $cmd_revision" "info should expose the generated revision"
assert_contains "$info_output" 'command: cmd' "info should expose the generated command name"
assert_contains "$info_output" 'kind: ai-command' "info should expose the app kind"
assert_contains "$info_output" "bundle_url: $cmd_bundle_url" "info should show the bundle URL"

install_output=$(framework_run_manager install cmd define oneliner)
assert_contains "$install_output" "Installed cmd $cmd_revision" "install should report cmd success"
assert_contains "$install_output" "Installed define $define_revision" "install should report define success"
assert_contains "$install_output" "Installed oneliner $oneliner_revision" "install should report oneliner success"

assert_file_exists "$TEST_HOME_DIR/.local/bin/cmd"
assert_file_exists "$TEST_HOME_DIR/.local/bin/define"
assert_file_exists "$TEST_HOME_DIR/.local/bin/oneliner"
assert_file_exists "$TEST_HOME_DIR/.local/share/apfeller/state.tsv"
assert_file_exists "$TEST_HOME_DIR/.config/fish/completions/cmd.fish"
assert_file_exists "$TEST_HOME_DIR/.config/apfeller/completions/zsh/_define"

cmd_output=$(APFELLER_STUB_OUTPUT='ls -la' framework_run_app cmd "list files")
assert_contains "$cmd_output" '$ ls -la' "installed ai-command apps should run through generated wrappers"

define_output=$(APFELLER_STUB_OUTPUT='word: hola lang: es meaning: hello example: hola amiga (hello friend)' framework_run_app define hola)
assert_contains "$define_output" 'meaning: hello' "installed ai-text apps should format structured output"

oneliner_output=$(APFELLER_STUB_OUTPUT='awk "{print \$1}" file.txt' framework_run_app oneliner "print first column")
assert_contains "$oneliner_output" '$ awk "{print \$1}" file.txt' "installed ai-command apps should support multiple command-style apps"

installed_output=$(framework_run_manager list --installed)
assert_contains "$installed_output" "cmd	$cmd_revision	installed" "installed listing should include cmd"
assert_contains "$installed_output" "define	$define_revision	installed" "installed listing should include define"
assert_contains "$installed_output" "oneliner	$oneliner_revision	installed" "installed listing should include oneliner"

update_output=$(framework_run_manager update --all)
assert_contains "$update_output" "Installed cmd $cmd_revision" "update --all should reinstall ai-command apps"
assert_contains "$update_output" "Installed define $define_revision" "update --all should reinstall ai-text apps"
assert_contains "$update_output" "Installed oneliner $oneliner_revision" "update --all should reinstall the second ai-command app"

self_update_output=$(framework_run_manager update --self)
assert_contains "$self_update_output" 'Updated apfeller' "update --self should refresh the manager asset"
assert_file_exists "$TEST_HOME_DIR/.local/bin/apfeller"

doctor_output=$(framework_run_manager doctor)
assert_contains "$doctor_output" 'manager_path' "doctor should report manager path"
assert_contains "$doctor_output" 'legacy_state_json' "doctor should report legacy JSON status"

uninstall_output=$(framework_run_manager uninstall cmd define oneliner)
assert_contains "$uninstall_output" 'Removed cmd' "uninstall should report cmd removal"
assert_contains "$uninstall_output" 'Removed define' "uninstall should report define removal"
assert_contains "$uninstall_output" 'Removed oneliner' "uninstall should report oneliner removal"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/cmd"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/define"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/oneliner"
