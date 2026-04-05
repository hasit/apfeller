#!/bin/sh

set -eu

REPO=${APFELLER_REPO:-hasit/apfeller}
HOME_DIR=${HOME:?HOME is required}
LOCAL_BIN_DIR=${APFELLER_LOCAL_BIN_DIR:-"$HOME_DIR/.local/bin"}
CONFIG_DIR=${APFELLER_CONFIG_DIR:-"$HOME_DIR/.config/apfeller"}
ZSHRC_PATH=${APFELLER_ZSHRC_PATH:-"$HOME_DIR/.zshrc"}
FISH_CONF_PATH=${APFELLER_FISH_CONF_PATH:-"$HOME_DIR/.config/fish/conf.d/apfeller.fish"}
FISH_COMPLETION_DIR=${APFELLER_FISH_COMPLETION_DIR:-"$HOME_DIR/.config/fish/completions"}
ZSH_COMPLETION_DIR=${APFELLER_ZSH_COMPLETION_DIR:-"$CONFIG_DIR/completions/zsh"}
ZSH_INIT_PATH=${APFELLER_ZSH_INIT_PATH:-"$CONFIG_DIR/init.zsh"}
ASSET_NAME=${APFELLER_MANAGER_ASSET_NAME:-apfeller.tar.gz}

ensure_dir() {
  mkdir -p "$1"
}

print_missing_release_asset_hint() {
  url=$1
  asset_name=$2
  override_var=$3

  case "$url" in
    https://github.com/*/releases/latest/download/*|http://github.com/*/releases/latest/download/*)
      printf '%s\n' "No published GitHub release asset was found for $asset_name." >&2
      printf '%s\n' "Publish a release containing $asset_name, or set $override_var to a direct URL." >&2
      ;;
  esac
}

download_to_path() {
  url=$1
  output_path=$2
  label=$3
  asset_name=$4
  override_var=$5

  curl -fsSL "$url" -o "$output_path" && return 0
  status=$?

  printf '%s\n' "Failed to download $label from $url" >&2
  print_missing_release_asset_hint "$url" "$asset_name" "$override_var"
  return "$status"
}

write_fish_conf() {
  ensure_dir "$(dirname "$FISH_CONF_PATH")"
  cat >"$FISH_CONF_PATH" <<EOF
set -gx APFELLER_HOME "\$HOME/.config/apfeller"
if not contains -- "$LOCAL_BIN_DIR" \$PATH
    set -gx PATH "$LOCAL_BIN_DIR" \$PATH
end
EOF
}

write_zsh_init() {
  ensure_dir "$(dirname "$ZSH_INIT_PATH")"
  cat >"$ZSH_INIT_PATH" <<EOF
export APFELLER_HOME="\$HOME/.config/apfeller"
if [[ ":\$PATH:" != *":$LOCAL_BIN_DIR:"* ]]; then
  export PATH="$LOCAL_BIN_DIR:\$PATH"
fi
APFELLER_ZSH_COMPLETIONS="$ZSH_COMPLETION_DIR"
if [[ -d "\$APFELLER_ZSH_COMPLETIONS" ]]; then
  fpath=("\$APFELLER_ZSH_COMPLETIONS" \$fpath)
fi
autoload -Uz compinit
if ! whence compdef >/dev/null 2>&1; then
  compinit -i
fi
EOF
}

ensure_zsh_source_block() {
  block=$(cat <<EOF
# >>> apfeller >>>
[ -f "$ZSH_INIT_PATH" ] && source "$ZSH_INIT_PATH"
# <<< apfeller <<<
EOF
)
  block_file=$(mktemp "$tmp_dir/block.XXXXXX")
  printf '%s\n' "$block" >"$block_file"

  if [ ! -f "$ZSHRC_PATH" ]; then
    printf '%s\n' "$block" >"$ZSHRC_PATH"
    rm -f "$block_file"
    return
  fi

  tmp_output=$(mktemp "$tmp_dir/zshrc.XXXXXX")
  awk -v start='# >>> apfeller >>>' -v end='# <<< apfeller <<<' -v block_file="$block_file" '
    function emit_block(    line) {
      while ((getline line < block_file) > 0) {
        print line
      }
      close(block_file)
    }
    $0 == start {
      emit_block()
      skipping = 1
      replaced = 1
      next
    }
    $0 == end {
      skipping = 0
      next
    }
    skipping {
      next
    }
    {
      print
    }
    END {
      if (!replaced) {
        if (NR > 0) {
          print ""
        }
        emit_block()
      }
    }
  ' "$ZSHRC_PATH" >"$tmp_output"

  mv "$tmp_output" "$ZSHRC_PATH"
  rm -f "$block_file"
}

install_manager_completions() {
  extracted_root=$1

  if [ -f "$extracted_root/completions/fish/apfeller.fish" ]; then
    ensure_dir "$FISH_COMPLETION_DIR"
    cp "$extracted_root/completions/fish/apfeller.fish" "$FISH_COMPLETION_DIR/apfeller.fish"
  fi

  if [ -f "$extracted_root/completions/zsh/_apfeller" ]; then
    ensure_dir "$ZSH_COMPLETION_DIR"
    cp "$extracted_root/completions/zsh/_apfeller" "$ZSH_COMPLETION_DIR/_apfeller"
  fi
}

if ! command -v curl >/dev/null 2>&1; then
  printf '%s\n' "Missing required tool: curl" >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  printf '%s\n' "Missing required tool: tar" >&2
  exit 1
fi

asset_url=${APFELLER_INSTALL_URL:-"https://github.com/$REPO/releases/latest/download/$ASSET_NAME"}
shell_name=${APFELLER_SHELL:-${SHELL:-}}
shell_name=${shell_name##*/}

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

archive_path="$tmp_dir/$ASSET_NAME"
extract_dir="$tmp_dir/extracted"

ensure_dir "$LOCAL_BIN_DIR"
ensure_dir "$CONFIG_DIR"
ensure_dir "$extract_dir"

download_to_path "$asset_url" "$archive_path" "manager archive" "$ASSET_NAME" "APFELLER_INSTALL_URL"
tar -xzf "$archive_path" -C "$extract_dir"

cp "$extract_dir/bin/apfeller" "$LOCAL_BIN_DIR/apfeller"
chmod +x "$LOCAL_BIN_DIR/apfeller"
install_manager_completions "$extract_dir"

case "$shell_name" in
  fish)
    write_fish_conf
    ;;
  zsh)
    write_zsh_init
    ensure_zsh_source_block
    ;;
  *)
    printf '%s\n' "Installed apfeller to $LOCAL_BIN_DIR/apfeller"
    printf '%s\n' "Run this once for the current shell: export PATH=\"$LOCAL_BIN_DIR:\$PATH\""
    exit 0
    ;;
esac

printf '%s\n' "Installed apfeller to $LOCAL_BIN_DIR/apfeller"
