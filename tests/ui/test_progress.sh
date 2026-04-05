#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"
. "$ROOT_DIR/tests/helpers/framework_env.sh"

BASE_PATH=/usr/bin:/bin:/usr/sbin:/sbin

make_install_asset() {
  asset_dir=$1
  mkdir -p "$asset_dir/bin" "$asset_dir/completions/fish" "$asset_dir/completions/zsh"
  cp "$ROOT_DIR/tests/helpers/install_asset_apfeller" "$asset_dir/bin/apfeller"
  cp "$ROOT_DIR/shell/completions/fish/apfeller.fish" "$asset_dir/completions/fish/apfeller.fish"
  cp "$ROOT_DIR/shell/completions/zsh/_apfeller" "$asset_dir/completions/zsh/_apfeller"
  chmod +x "$asset_dir/bin/apfeller"
}

sanitize_pty_output() {
  perl -pe 's/\e\[[0-9;]*[A-Za-z]//g; s/\r/\n/g; s/[\x04\x08]//g; s/\^D//g'
}

run_pty_script() {
  script_path=$1
  /usr/bin/script -q /dev/null /bin/sh "$script_path" 2>/dev/null | sanitize_pty_output
}

write_runner() {
  runner_path=$1
  body=$2

  cat >"$runner_path" <<EOF
#!/bin/sh
set -eu
$body
EOF
  chmod +x "$runner_path"
}

assert_not_old_spinner() {
  output=$1
  assert_not_contains "$output" '[-]' "progress output should not use the old hyphen spinner"
  assert_not_contains "$output" '[\]' "progress output should not use the old backslash spinner"
  assert_not_contains "$output" '[|]' "progress output should not use the old pipe spinner"
  assert_not_contains "$output" '[/]' "progress output should not use the old slash spinner"
}

test_unicode_installer_bar() {
  tmp_dir=$(mktemp -d)
  asset_stage="$tmp_dir/asset"
  stub_dir="$tmp_dir/bin"
  runner="$tmp_dir/install-unicode.sh"

  make_install_asset "$asset_stage"
  tar -czf "$tmp_dir/apfeller.tar.gz" -C "$asset_stage" .

  mkdir -p "$stub_dir"
  cp "$ROOT_DIR/tests/helpers/curl_slow_stub.sh" "$stub_dir/curl"
  chmod +x "$stub_dir/curl"

  write_runner "$runner" "
HOME=$tmp_dir/home
PATH=$stub_dir:$BASE_PATH
LANG=en_US.UTF-8
TERM=xterm-256color
APFELLER_SHELL=fish
APFELLER_INSTALL_URL=file://$tmp_dir/apfeller.tar.gz
export HOME PATH LANG TERM APFELLER_SHELL APFELLER_INSTALL_URL
sh \"$ROOT_DIR/install.sh\"
"

  output=$(run_pty_script "$runner")

  assert_contains "$output" 'Downloading apfeller... [' "installer should render a progress bar in a tty"
  assert_contains "$output" '███' "installer should prefer the unicode progress bar on UTF-8 terminals"
  assert_contains "$output" 'Installed apfeller to' "installer should still finish with the success message"
  assert_not_old_spinner "$output"
}

test_ascii_installer_bar_fallback() {
  tmp_dir=$(mktemp -d)
  asset_stage="$tmp_dir/asset"
  stub_dir="$tmp_dir/bin"
  runner="$tmp_dir/install-ascii.sh"

  make_install_asset "$asset_stage"
  tar -czf "$tmp_dir/apfeller.tar.gz" -C "$asset_stage" .

  mkdir -p "$stub_dir"
  cp "$ROOT_DIR/tests/helpers/curl_slow_stub.sh" "$stub_dir/curl"
  chmod +x "$stub_dir/curl"

  write_runner "$runner" "
HOME=$tmp_dir/home
PATH=$stub_dir:$BASE_PATH
LC_ALL=C
TERM=xterm-256color
APFELLER_SHELL=fish
APFELLER_INSTALL_URL=file://$tmp_dir/apfeller.tar.gz
export HOME PATH LC_ALL TERM APFELLER_SHELL APFELLER_INSTALL_URL
sh \"$ROOT_DIR/install.sh\"
"

  output=$(run_pty_script "$runner")

  assert_contains "$output" 'Downloading apfeller... [###' "installer should fall back to an ASCII progress bar outside UTF-8 locales"
  assert_not_contains "$output" '███' "ASCII fallback should avoid unicode bar frames"
  assert_not_contains "$output" '⠋' "ASCII fallback should avoid unicode spinner frames"
  assert_not_old_spinner "$output"
}

test_unicode_runtime_spinner() {
  tmp_dir=$(mktemp -d)
  runner="$tmp_dir/runtime-unicode.sh"

  setup_framework_env "$ROOT_DIR" "$tmp_dir"
  framework_run_manager install fixture-cmd >/dev/null

  write_runner "$runner" "
HOME=$TEST_HOME_DIR
PATH=$TEST_HOME_DIR/.local/bin:$TEST_STUB_DIR:$BASE_PATH
LANG=en_US.UTF-8
TERM=xterm-256color
APFELLER_STUB_SLEEP=0.45
APFELLER_STUB_OUTPUT='echo hello'
export HOME PATH LANG TERM APFELLER_STUB_SLEEP APFELLER_STUB_OUTPUT
fixture-cmd \"say hello\"
"

  output=$(run_pty_script "$runner")

  assert_contains "$output" 'Running fixture-cmd... ⠋' "runtime queries should render the unicode spinner in a tty"
  assert_contains "$output" '$ echo hello' "the app should still print its final output"
  assert_not_contains "$output" 'Running fixture-cmd... [' "spinner output should not use the bar renderer"
  assert_not_old_spinner "$output"
}

test_unicode_installer_bar
test_ascii_installer_bar_fallback
test_unicode_runtime_spinner
