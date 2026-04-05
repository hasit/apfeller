#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

dist_dir="$tmp_dir/dist"
home_dir="$tmp_dir/home"
stub_dir="$tmp_dir/bin"
manager_stage="$tmp_dir/manager"

mkdir -p "$stub_dir"
cp "$ROOT_DIR/tests/helpers/apfel_stub.sh" "$stub_dir/apfel"
chmod +x "$stub_dir/apfel"

(cd "$ROOT_DIR" && scripts/package_release.sh --output-dir "$dist_dir")

mkdir -p "$manager_stage" "$home_dir"
tar -xzf "$dist_dir/apfeller.tar.gz" -C "$manager_stage"

mkdir -p "$home_dir/.local/bin"
cp "$manager_stage/bin/apfeller" "$home_dir/.local/bin/apfeller"
chmod +x "$home_dir/.local/bin/apfeller"

catalog_url="file://$dist_dir/apfeller-catalog.tsv"
release_base_url="file://$dist_dir"

run_manager() {
  HOME="$home_dir" \
  PATH="$home_dir/.local/bin:$stub_dir:$PATH" \
  APFELLER_CATALOG_URL="$catalog_url" \
  APFELLER_RELEASE_BASE_URL="$release_base_url" \
  "$@"
}

list_output=$(run_manager apfeller list)
assert_contains "$list_output" 'cmd' "catalog listing should include cmd"

info_output=$(run_manager apfeller info cmd)
assert_contains "$info_output" 'id: cmd' "info should show the requested app"
assert_contains "$info_output" 'bundle_archive: cmd-0.1.0.tar.gz' "info should show the bundle archive"

install_output=$(run_manager apfeller install cmd)
assert_contains "$install_output" 'Installed cmd 0.1.0' "install should report success"
assert_file_exists "$home_dir/.local/bin/cmd"
assert_file_exists "$home_dir/.local/share/apfeller/state.tsv"

app_output=$(HOME="$home_dir" PATH="$home_dir/.local/bin:$stub_dir:$PATH" APFELLER_STUB_OUTPUT='ls -la' cmd "list files")
assert_contains "$app_output" '$ ls -la' "installed command should resolve on PATH"

installed_output=$(run_manager apfeller list --installed)
assert_contains "$installed_output" 'cmd' "installed listing should include cmd"

update_output=$(run_manager apfeller update --all)
assert_contains "$update_output" 'Installed cmd 0.1.0' "update --all should reinstall installed apps from state"

self_update_output=$(run_manager apfeller update --self)
assert_contains "$self_update_output" 'Updated apfeller' "update --self should refresh the manager asset"
assert_file_exists "$home_dir/.local/bin/apfeller"

doctor_output=$(run_manager apfeller doctor)
assert_contains "$doctor_output" 'manager_path' "doctor should report manager path"
assert_contains "$doctor_output" 'legacy_state_json' "doctor should report legacy JSON status"

uninstall_output=$(run_manager apfeller uninstall cmd)
assert_contains "$uninstall_output" 'Removed cmd' "uninstall should report success"
assert_file_not_exists "$home_dir/.local/bin/cmd"
