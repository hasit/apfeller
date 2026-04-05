#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

BASE_PATH=/usr/bin:/bin:/usr/sbin:/sbin

make_asset() {
  asset_dir=$1
  mkdir -p "$asset_dir/bin" "$asset_dir/completions/fish" "$asset_dir/completions/zsh"
  cp "$ROOT_DIR/tests/helpers/install_asset_apfeller" "$asset_dir/bin/apfeller"
  cp "$ROOT_DIR/shell/completions/fish/apfeller.fish" "$asset_dir/completions/fish/apfeller.fish"
  cp "$ROOT_DIR/shell/completions/zsh/_apfeller" "$asset_dir/completions/zsh/_apfeller"
  chmod +x "$asset_dir/bin/apfeller"
}

test_fish_install() {
  tmp_dir=$(mktemp -d)
  asset_stage="$tmp_dir/asset"
  make_asset "$asset_stage"
  tar -czf "$tmp_dir/apfeller.tar.gz" -C "$asset_stage" .

  output=$(
    HOME="$tmp_dir/home" \
    PATH="$BASE_PATH" \
    APFELLER_SHELL=fish \
    APFELLER_INSTALL_URL="file://$tmp_dir/apfeller.tar.gz" \
    sh "$ROOT_DIR/install.sh"
  )

  assert_file_exists "$tmp_dir/home/.local/bin/apfeller"
  assert_file_exists "$tmp_dir/home/.config/fish/conf.d/apfeller.fish"
  assert_file_exists "$tmp_dir/home/.config/fish/completions/apfeller.fish"
  assert_contains "$output" 'apfel is not installed yet.' "install should warn when apfel is missing"
  assert_not_contains "$output" 'Downloading apfeller...' "non-interactive install output should stay free of progress lines"
  assert_not_contains "$output" 'Installing apfeller...' "non-interactive install output should stay free of spinner lines"

  HOME="$tmp_dir/home" \
  PATH="$BASE_PATH" \
  APFELLER_SHELL=fish \
  APFELLER_INSTALL_URL="file://$tmp_dir/apfeller.tar.gz" \
  sh "$ROOT_DIR/install.sh"

  assert_file_exists "$tmp_dir/home/.local/bin/apfeller"
}

test_zsh_install() {
  tmp_dir=$(mktemp -d)
  asset_stage="$tmp_dir/asset"
  stub_dir="$tmp_dir/bin"
  make_asset "$asset_stage"
  tar -czf "$tmp_dir/apfeller.tar.gz" -C "$asset_stage" .
  mkdir -p "$stub_dir"
  cp "$ROOT_DIR/tests/helpers/apfel_stub.sh" "$stub_dir/apfel"
  chmod +x "$stub_dir/apfel"

  output=$(
    HOME="$tmp_dir/home" \
    PATH="$stub_dir:$BASE_PATH" \
    APFELLER_SHELL=zsh \
    APFELLER_INSTALL_URL="file://$tmp_dir/apfeller.tar.gz" \
    sh "$ROOT_DIR/install.sh"
  )

  assert_file_exists "$tmp_dir/home/.local/bin/apfeller"
  assert_file_exists "$tmp_dir/home/.config/apfeller/init.zsh"
  assert_file_exists "$tmp_dir/home/.config/apfeller/completions/zsh/_apfeller"
  assert_file_exists "$tmp_dir/home/.zshrc"
  assert_not_contains "$output" 'apfel is not installed yet.' "install should stay quiet when apfel is already present"
  assert_not_contains "$output" 'Downloading apfeller...' "non-interactive install output should not show progress bars"
  assert_not_contains "$output" 'Installing apfeller...' "non-interactive install output should not show spinners"

  zshrc_contents=$(cat "$tmp_dir/home/.zshrc")
  assert_contains "$zshrc_contents" '# >>> apfeller >>>' "zsh install should add a managed block"

  HOME="$tmp_dir/home" \
  PATH="$stub_dir:$BASE_PATH" \
  APFELLER_SHELL=zsh \
  APFELLER_INSTALL_URL="file://$tmp_dir/apfeller.tar.gz" \
  sh "$ROOT_DIR/install.sh"

  second_contents=$(cat "$tmp_dir/home/.zshrc")
  count=$(printf '%s' "$second_contents" | grep -c '# >>> apfeller >>>')
  assert_eq "1" "$count" "managed zsh block should remain idempotent"
}

test_missing_release_asset_message() {
  tmp_dir=$(mktemp -d)
  stub_dir="$tmp_dir/bin"
  mkdir -p "$stub_dir"
  cp "$ROOT_DIR/tests/helpers/curl_404_stub.sh" "$stub_dir/curl"
  chmod +x "$stub_dir/curl"

  set +e
  output=$(
    HOME="$tmp_dir/home" \
    PATH="$stub_dir:$BASE_PATH" \
    APFELLER_INSTALL_URL="https://github.com/hasit/apfeller/releases/latest/download/apfeller.tar.gz" \
    sh "$ROOT_DIR/install.sh" 2>&1
  )
  status=$?
  set -e

  if [ "$status" -eq 0 ]; then
    printf '%s\n' "expected install.sh to fail when the manager release asset is missing" >&2
    exit 1
  fi

  assert_contains "$output" 'apfeller could not download the installer right now.' "install should use a user-facing download error"
  assert_contains "$output" 'Check your internet connection and try again.' "install should tell the user what to do next"
  assert_not_contains "$output" 'Publish a release' "install should not mention maintainer actions"
  assert_not_contains "$output" 'APFELLER_INSTALL_URL' "install should not expose maintainer override variables"
  assert_not_contains "$output" 'Downloading apfeller...' "non-interactive failures should not render progress bars"
}

test_fish_install
test_zsh_install
test_missing_release_asset_message
