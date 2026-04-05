#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"
. "$ROOT_DIR/tests/helpers/framework_env.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

setup_framework_env "$ROOT_DIR" "$tmp_dir"

list_output=$(framework_run_manager list)
assert_contains "$list_output" 'cmd' "catalog listing should include cmd"
assert_contains "$list_output" 'define' "catalog listing should include define"
assert_contains "$list_output" 'port' "catalog listing should include port"

info_output=$(framework_run_manager info cmd)
assert_contains "$info_output" 'id: cmd' "info should show the requested app"
assert_contains "$info_output" 'command: cmd' "info should expose the generated command name"
assert_contains "$info_output" 'kind: ai-command' "info should expose the app kind"
assert_contains "$info_output" 'bundle_archive: cmd-0.1.0.tar.gz' "info should show the bundle archive"

install_output=$(framework_run_manager install cmd define port)
assert_contains "$install_output" 'Installed cmd 0.1.0' "install should report cmd success"
assert_contains "$install_output" 'Installed define 0.1.0' "install should report define success"
assert_contains "$install_output" 'Installed port 0.1.0' "install should report port success"

assert_file_exists "$TEST_HOME_DIR/.local/bin/cmd"
assert_file_exists "$TEST_HOME_DIR/.local/bin/define"
assert_file_exists "$TEST_HOME_DIR/.local/bin/port"
assert_file_exists "$TEST_HOME_DIR/.local/share/apfeller/state.tsv"
assert_file_exists "$TEST_HOME_DIR/.config/fish/completions/cmd.fish"
assert_file_exists "$TEST_HOME_DIR/.config/apfeller/completions/zsh/_define"

cmd_output=$(APFELLER_STUB_OUTPUT='ls -la' framework_run_app cmd "list files")
assert_contains "$cmd_output" '$ ls -la' "installed ai-command apps should run through generated wrappers"

define_output=$(APFELLER_STUB_OUTPUT='word: hola lang: es meaning: hello example: hola amiga (hello friend)' framework_run_app define hola)
assert_contains "$define_output" 'meaning: hello' "installed ai-text apps should format structured output"

port_output=$(framework_run_app port 65535)
assert_contains "$port_output" 'Port 65535 is not in use.' "installed local-command apps should run their hooks"

installed_output=$(framework_run_manager list --installed)
assert_contains "$installed_output" 'cmd' "installed listing should include cmd"
assert_contains "$installed_output" 'define' "installed listing should include define"
assert_contains "$installed_output" 'port' "installed listing should include port"

update_output=$(framework_run_manager update --all)
assert_contains "$update_output" 'Installed cmd 0.1.0' "update --all should reinstall ai-command apps"
assert_contains "$update_output" 'Installed define 0.1.0' "update --all should reinstall ai-text apps"
assert_contains "$update_output" 'Installed port 0.1.0' "update --all should reinstall local-command apps"

self_update_output=$(framework_run_manager update --self)
assert_contains "$self_update_output" 'Updated apfeller' "update --self should refresh the manager asset"
assert_file_exists "$TEST_HOME_DIR/.local/bin/apfeller"

doctor_output=$(framework_run_manager doctor)
assert_contains "$doctor_output" 'manager_path' "doctor should report manager path"
assert_contains "$doctor_output" 'legacy_state_json' "doctor should report legacy JSON status"

uninstall_output=$(framework_run_manager uninstall cmd define port)
assert_contains "$uninstall_output" 'Removed cmd' "uninstall should report cmd removal"
assert_contains "$uninstall_output" 'Removed define' "uninstall should report define removal"
assert_contains "$uninstall_output" 'Removed port' "uninstall should report port removal"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/cmd"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/define"
assert_file_not_exists "$TEST_HOME_DIR/.local/bin/port"
