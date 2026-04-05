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
PROGRESS_PID=
PROGRESS_MESSAGE=
PROGRESS_MODE=
PROGRESS_CHARSET=
PROGRESS_DELAY_SECONDS=0.18
PROGRESS_INTERVAL_SECONDS=0.10

ensure_dir() {
  mkdir -p "$1"
}

progress_can_render() {
  [ -t 2 ] || return 1
  [ "${TERM:-}" != "dumb" ] || return 1
}

progress_detect_charset() {
  locale=${LC_ALL:-${LC_CTYPE:-${LANG:-}}}
  locale=$(printf '%s' "$locale" | tr '[:lower:]' '[:upper:]')

  case "$locale" in
    *UTF-8*|*UTF8*)
      printf '%s\n' "unicode"
      ;;
    *)
      printf '%s\n' "ascii"
      ;;
  esac
}

progress_spin_frame() {
  charset=$1
  step=$2

  if [ "$charset" = "unicode" ]; then
    case $((step % 10)) in
      0) printf '%s' '⠋' ;;
      1) printf '%s' '⠙' ;;
      2) printf '%s' '⠹' ;;
      3) printf '%s' '⠸' ;;
      4) printf '%s' '⠼' ;;
      5) printf '%s' '⠴' ;;
      6) printf '%s' '⠦' ;;
      7) printf '%s' '⠧' ;;
      8) printf '%s' '⠇' ;;
      *) printf '%s' '⠏' ;;
    esac
    return 0
  fi

  case $((step % 5)) in
    0) printf '%s' '.  ' ;;
    1) printf '%s' '.. ' ;;
    2) printf '%s' '...' ;;
    3) printf '%s' '.. ' ;;
    *) printf '%s' '.  ' ;;
  esac
}

progress_bar_frame() {
  charset=$1
  step=$2

  if [ "$charset" = "unicode" ]; then
    case $((step % 10)) in
      0) segment='███     ' ;;
      1) segment=' ███    ' ;;
      2) segment='  ███   ' ;;
      3) segment='   ███  ' ;;
      4) segment='    ███ ' ;;
      5) segment='     ███' ;;
      6) segment='    ███ ' ;;
      7) segment='   ███  ' ;;
      8) segment='  ███   ' ;;
      *) segment=' ███    ' ;;
    esac
  else
    case $((step % 10)) in
      0) segment='###     ' ;;
      1) segment=' ###    ' ;;
      2) segment='  ###   ' ;;
      3) segment='   ###  ' ;;
      4) segment='    ### ' ;;
      5) segment='     ###' ;;
      6) segment='    ### ' ;;
      7) segment='   ###  ' ;;
      8) segment='  ###   ' ;;
      *) segment=' ###    ' ;;
    esac
  fi

  printf '[%s]' "$segment"
}

progress_frame() {
  mode=$1
  charset=$2
  step=$3

  case "$mode" in
    bar)
      progress_bar_frame "$charset" "$step"
      ;;
    *)
      progress_spin_frame "$charset" "$step"
      ;;
  esac
}

progress_start() {
  mode=$1
  message=$2

  progress_abort
  PROGRESS_MODE=$mode
  PROGRESS_MESSAGE=$message
  PROGRESS_CHARSET=$(progress_detect_charset)

  progress_can_render || return 0

  (
    trap 'exit 0' INT TERM
    sleep "$PROGRESS_DELAY_SECONDS"
    step=0
    while :; do
      frame=$(progress_frame "$PROGRESS_MODE" "$PROGRESS_CHARSET" "$step")
      printf '\r\033[2K%s %s' "$PROGRESS_MESSAGE" "$frame" >&2
      step=$((step + 1))
      sleep "$PROGRESS_INTERVAL_SECONDS"
    done
  ) &
  PROGRESS_PID=$!
}

progress_abort() {
  if [ -n "${PROGRESS_PID:-}" ]; then
    kill "$PROGRESS_PID" 2>/dev/null || true
    wait "$PROGRESS_PID" 2>/dev/null || true
    PROGRESS_PID=
  fi

  if progress_can_render; then
    printf '\r\033[2K' >&2
  fi

  PROGRESS_MESSAGE=
  PROGRESS_MODE=
  PROGRESS_CHARSET=
}

print_download_failure_help() {
  status=$1

  printf '%s\n' "apfeller could not download the installer right now." >&2

  case "$status" in
    6|7|28|35|56)
      printf '%s\n' "Check your internet connection and try again." >&2
      ;;
    22)
      printf '%s\n' "The download is not available right now. Please try again later." >&2
      ;;
    *)
      printf '%s\n' "Please try again in a moment." >&2
      ;;
  esac

  printf '%s\n' "See https://hasit.github.io/apfeller/install/ for help." >&2
}

download_to_path() {
  url=$1
  output_path=$2
  progress_message=$3
  curl_error_path=$(mktemp "${TMPDIR:-/tmp}/apfeller-curl.XXXXXX")

  progress_start bar "$progress_message"

  set +e
  curl -fsSL "$url" -o "$output_path" 2>"$curl_error_path"
  status=$?
  set -e

  progress_abort

  if [ "$status" -eq 0 ]; then
    rm -f "$curl_error_path"
    return 0
  fi

  rm -f "$curl_error_path"

  progress_abort
  print_download_failure_help "$status"
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

print_apfel_note_if_missing() {
  if command -v apfel >/dev/null 2>&1; then
    return 0
  fi

  printf '%s\n' "apfel is not installed yet. Some apps need it. Install it with: brew install Arthur-Ficial/tap/apfel"
}

if ! command -v curl >/dev/null 2>&1; then
  printf '%s\n' "apfeller needs curl to install. Install curl and try again." >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  printf '%s\n' "apfeller needs tar to install. Install tar and try again." >&2
  exit 1
fi

asset_url=${APFELLER_INSTALL_URL:-"https://github.com/$REPO/releases/latest/download/$ASSET_NAME"}
shell_name=${APFELLER_SHELL:-${SHELL:-}}
shell_name=${shell_name##*/}

tmp_dir=$(mktemp -d)
trap 'progress_abort; rm -rf "$tmp_dir"' EXIT INT TERM HUP

archive_path="$tmp_dir/$ASSET_NAME"
extract_dir="$tmp_dir/extracted"

ensure_dir "$LOCAL_BIN_DIR"
ensure_dir "$CONFIG_DIR"
ensure_dir "$extract_dir"

download_to_path "$asset_url" "$archive_path" "Downloading apfeller..."
progress_start spin "Installing apfeller..."
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
    progress_abort
    printf '%s\n' "Installed apfeller to $LOCAL_BIN_DIR/apfeller"
    print_apfel_note_if_missing
    printf '%s\n' "Run this once for the current shell: export PATH=\"$LOCAL_BIN_DIR:\$PATH\""
    exit 0
    ;;
esac

progress_abort
printf '%s\n' "Installed apfeller to $LOCAL_BIN_DIR/apfeller"
print_apfel_note_if_missing
