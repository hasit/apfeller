#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

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

  HOME="$tmp_dir/home" \
  APFELLER_SHELL=fish \
  APFELLER_INSTALL_URL="file://$tmp_dir/apfeller.tar.gz" \
  sh "$ROOT_DIR/install.sh"

  assert_file_exists "$tmp_dir/home/.local/bin/apfeller"
  assert_file_exists "$tmp_dir/home/.config/fish/conf.d/apfeller.fish"
  assert_file_exists "$tmp_dir/home/.config/fish/completions/apfeller.fish"

  HOME="$tmp_dir/home" \
  APFELLER_SHELL=fish \
  APFELLER_INSTALL_URL="file://$tmp_dir/apfeller.tar.gz" \
  sh "$ROOT_DIR/install.sh"

  assert_file_exists "$tmp_dir/home/.local/bin/apfeller"
}

test_zsh_install() {
  tmp_dir=$(mktemp -d)
  asset_stage="$tmp_dir/asset"
  make_asset "$asset_stage"
  tar -czf "$tmp_dir/apfeller.tar.gz" -C "$asset_stage" .

  HOME="$tmp_dir/home" \
  APFELLER_SHELL=zsh \
  APFELLER_INSTALL_URL="file://$tmp_dir/apfeller.tar.gz" \
  sh "$ROOT_DIR/install.sh"

  assert_file_exists "$tmp_dir/home/.local/bin/apfeller"
  assert_file_exists "$tmp_dir/home/.config/apfeller/init.zsh"
  assert_file_exists "$tmp_dir/home/.config/apfeller/completions/zsh/_apfeller"
  assert_file_exists "$tmp_dir/home/.zshrc"

  zshrc_contents=$(cat "$tmp_dir/home/.zshrc")
  assert_contains "$zshrc_contents" '# >>> apfeller >>>' "zsh install should add a managed block"

  HOME="$tmp_dir/home" \
  APFELLER_SHELL=zsh \
  APFELLER_INSTALL_URL="file://$tmp_dir/apfeller.tar.gz" \
  sh "$ROOT_DIR/install.sh"

  second_contents=$(cat "$tmp_dir/home/.zshrc")
  count=$(printf '%s' "$second_contents" | grep -c '# >>> apfeller >>>')
  assert_eq "1" "$count" "managed zsh block should remain idempotent"
}

test_fish_install
test_zsh_install
