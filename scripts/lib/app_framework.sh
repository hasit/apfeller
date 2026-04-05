#!/bin/sh

APPFW_TAB=$(printf '\t')

appfw_fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

appfw_trim() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

appfw_contains_csv() {
  csv=$1
  item=$2

  case ",$csv," in
    *,"$item",*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

appfw_validate_single_line() {
  field_name=$1
  value=$2

  case "$value" in
    *"$APPFW_TAB"*)
      appfw_fail "Field $field_name contains a tab"
      ;;
  esac

  case "$value" in
    *'
'*)
      appfw_fail "Field $field_name contains a newline"
      ;;
  esac
}

appfw_decode_string() {
  raw=$(appfw_trim "$1")

  case "$raw" in
    \"*\")
      content=${raw#\"}
      content=${content%\"}
      printf '%s' "$content" | sed 's/\\"/"/g; s/\\\\/\\/g'
      ;;
    \'*\')
      content=${raw#\'}
      content=${content%\'}
      printf '%s' "$content"
      ;;
    *)
      appfw_fail "Expected TOML string, got: $raw"
      ;;
  esac
}

appfw_parse_string_array() {
  raw=$(appfw_trim "$1")

  case "$raw" in
    '[]')
      printf '%s\n' ""
      return 0
      ;;
    \[*\])
      inner=${raw#\[}
      inner=${inner%\]}
      ;;
    *)
      appfw_fail "Expected TOML string array, got: $raw"
      ;;
  esac

  old_ifs=$IFS
  IFS=,
  # shellcheck disable=SC2086
  set -- $inner
  IFS=$old_ifs

  joined=""
  for item in "$@"; do
    decoded=$(appfw_decode_string "$item")
    appfw_validate_single_line "array item" "$decoded"
    if [ -z "$joined" ]; then
      joined=$decoded
    else
      joined=$joined,$decoded
    fi
  done

  printf '%s\n' "$joined"
}

appfw_parse_boolean() {
  raw=$(appfw_trim "$1")

  case "$raw" in
    true)
      printf '1\n'
      ;;
    false)
      printf '0\n'
      ;;
    *)
      appfw_fail "Expected boolean, got: $raw"
      ;;
  esac
}

appfw_parse_integer() {
  raw=$(appfw_trim "$1")

  case "$raw" in
    ''|*[!0-9]*)
      appfw_fail "Expected integer, got: $raw"
      ;;
    *)
      printf '%s\n' "$raw"
      ;;
  esac
}

appfw_sanitize_name() {
  printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_' | tr -cd 'A-Z0-9_'
}

appfw_require_known_section() {
  case "$1" in
    ''|help|input|prompt|output|hooks|args)
      return 0
      ;;
    *)
      appfw_fail "Unsupported section [$1]"
      ;;
  esac
}

appfw_reset_definition() {
  APP_ID=
  APP_VERSION=
  APP_SUMMARY=
  APP_DESCRIPTION=
  APP_COMMAND=
  APP_KIND=
  APP_REQUIRES=
  APP_SUPPORTED_SHELLS=

  APP_HELP_USAGE=
  APP_INPUT_MODE=
  APP_INPUT_NAME=
  APP_INPUT_REQUIRED=

  APP_PROMPT_SYSTEM=
  APP_PROMPT_TEMPLATE=
  APP_PROMPT_MAX_CONTEXT_TOKENS=
  APP_PROMPT_MAX_INPUT_BYTES=
  APP_PROMPT_MAX_OUTPUT_TOKENS=

  APP_OUTPUT_MODE=
  APP_OUTPUT_FIELDS=

  APP_HOOK_BUILD_PROMPT=
  APP_HOOK_PRE_RUN=

  APP_SECTION=
  APP_SEEN_LONGS=
  APP_SEEN_SHORTS=
  APP_SEEN_ARG_NAMES=
  APP_IN_ARG=0
  APP_ARG_COUNT=0

  APP_ARG_NAME=
  APP_ARG_TYPE=
  APP_ARG_LONG=
  APP_ARG_SHORT=
  APP_ARG_DESCRIPTION=
  APP_ARG_DEFAULT=
  APP_ARG_CHOICES=
}

appfw_begin_args_file() {
  APP_ARGS_FILE=$1
  APP_EXAMPLES_FILE=$2
  printf 'name\ttype\tlong\tshort\tdescription\tdefault\tchoices\n' >"$APP_ARGS_FILE"
  : >"$APP_EXAMPLES_FILE"
}

appfw_start_arg_block() {
  appfw_finish_arg_block
  APP_SECTION=args
  APP_IN_ARG=1
  APP_ARG_NAME=
  APP_ARG_TYPE=
  APP_ARG_LONG=
  APP_ARG_SHORT=
  APP_ARG_DESCRIPTION=
  APP_ARG_DEFAULT=
  APP_ARG_CHOICES=
}

appfw_finish_arg_block() {
  [ "$APP_IN_ARG" = "1" ] || return 0

  [ -n "$APP_ARG_NAME" ] || appfw_fail "Missing args.name"
  [ -n "$APP_ARG_TYPE" ] || appfw_fail "Missing args.type"
  [ -n "$APP_ARG_LONG" ] || appfw_fail "Missing args.long"
  [ -n "$APP_ARG_DESCRIPTION" ] || appfw_fail "Missing args.description"

  case "$APP_ARG_NAME" in
    ''|*[!A-Za-z0-9_-]*)
      appfw_fail "Invalid arg name: $APP_ARG_NAME"
      ;;
  esac

  case "$APP_ARG_LONG" in
    ''|*[!A-Za-z0-9-]*)
      appfw_fail "Invalid long option: $APP_ARG_LONG"
      ;;
  esac

  if appfw_contains_csv "help,copy,execute" "$APP_ARG_NAME"; then
    appfw_fail "Reserved arg name: $APP_ARG_NAME"
  fi

  if appfw_contains_csv "help,copy,execute" "$APP_ARG_LONG"; then
    appfw_fail "Reserved long option: $APP_ARG_LONG"
  fi

  if appfw_contains_csv "$APP_SEEN_ARG_NAMES" "$APP_ARG_NAME"; then
    appfw_fail "Duplicate arg name: $APP_ARG_NAME"
  fi

  if appfw_contains_csv "$APP_SEEN_LONGS" "$APP_ARG_LONG"; then
    appfw_fail "Duplicate long option: $APP_ARG_LONG"
  fi

  case "$APP_ARG_TYPE" in
    flag|string|integer|enum)
      ;;
    *)
      appfw_fail "Unsupported arg type: $APP_ARG_TYPE"
      ;;
  esac

  case "$APP_ARG_SHORT" in
    '')
      ;;
    [A-Za-z0-9])
      if appfw_contains_csv "h,c,x" "$APP_ARG_SHORT"; then
        appfw_fail "Reserved short option: $APP_ARG_SHORT"
      fi
      if appfw_contains_csv "$APP_SEEN_SHORTS" "$APP_ARG_SHORT"; then
        appfw_fail "Duplicate short option: $APP_ARG_SHORT"
      fi
      ;;
    *)
      appfw_fail "Short option must be a single character: $APP_ARG_SHORT"
      ;;
  esac

  case "$APP_ARG_TYPE" in
    enum)
      [ -n "$APP_ARG_CHOICES" ] || appfw_fail "Enum arg $APP_ARG_NAME must declare choices"
      if [ -n "$APP_ARG_DEFAULT" ] && ! appfw_contains_csv "$APP_ARG_CHOICES" "$APP_ARG_DEFAULT"; then
        appfw_fail "Enum arg $APP_ARG_NAME has default outside choices"
      fi
      ;;
    integer)
      if [ -n "$APP_ARG_DEFAULT" ]; then
        appfw_parse_integer "$APP_ARG_DEFAULT" >/dev/null
      fi
      ;;
    flag)
      if [ -n "$APP_ARG_CHOICES" ]; then
        appfw_fail "Flag arg $APP_ARG_NAME cannot declare choices"
      fi
      if [ -z "$APP_ARG_DEFAULT" ]; then
        APP_ARG_DEFAULT=0
      fi
      case "$APP_ARG_DEFAULT" in
        0|1)
          ;;
        *)
          appfw_fail "Flag arg $APP_ARG_NAME default must be 0 or 1"
          ;;
      esac
      ;;
  esac

  APP_SEEN_ARG_NAMES=${APP_SEEN_ARG_NAMES:+$APP_SEEN_ARG_NAMES,}$APP_ARG_NAME
  APP_SEEN_LONGS=${APP_SEEN_LONGS:+$APP_SEEN_LONGS,}$APP_ARG_LONG
  if [ -n "$APP_ARG_SHORT" ]; then
    APP_SEEN_SHORTS=${APP_SEEN_SHORTS:+$APP_SEEN_SHORTS,}$APP_ARG_SHORT
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$APP_ARG_NAME" \
    "$APP_ARG_TYPE" \
    "$APP_ARG_LONG" \
    "$APP_ARG_SHORT" \
    "$APP_ARG_DESCRIPTION" \
    "$APP_ARG_DEFAULT" \
    "$APP_ARG_CHOICES" >>"$APP_ARGS_FILE"

  APP_ARG_COUNT=$((APP_ARG_COUNT + 1))
  APP_IN_ARG=0
}

appfw_set_value() {
  section=$1
  key=$2
  raw_value=$3

  case "$section:$key" in
    :id)
      APP_ID=$(appfw_decode_string "$raw_value")
      ;;
    :version)
      APP_VERSION=$(appfw_decode_string "$raw_value")
      ;;
    :summary)
      APP_SUMMARY=$(appfw_decode_string "$raw_value")
      ;;
    :description)
      APP_DESCRIPTION=$(appfw_decode_string "$raw_value")
      ;;
    :command)
      APP_COMMAND=$(appfw_decode_string "$raw_value")
      ;;
    :kind)
      APP_KIND=$(appfw_decode_string "$raw_value")
      ;;
    :requires_commands)
      APP_REQUIRES=$(appfw_parse_string_array "$raw_value")
      ;;
    :supported_shells)
      APP_SUPPORTED_SHELLS=$(appfw_parse_string_array "$raw_value")
      ;;
    help:usage)
      APP_HELP_USAGE=$(appfw_decode_string "$raw_value")
      ;;
    help:examples)
      examples_csv=$(appfw_parse_string_array "$raw_value")
      old_ifs=$IFS
      IFS=,
      # shellcheck disable=SC2086
      set -- $examples_csv
      IFS=$old_ifs
      for example in "$@"; do
        [ -n "$example" ] || continue
        printf '%s\n' "$example" >>"$APP_EXAMPLES_FILE"
      done
      ;;
    input:mode)
      APP_INPUT_MODE=$(appfw_decode_string "$raw_value")
      ;;
    input:name)
      APP_INPUT_NAME=$(appfw_decode_string "$raw_value")
      ;;
    input:required)
      APP_INPUT_REQUIRED=$(appfw_parse_boolean "$raw_value")
      ;;
    prompt:system)
      APP_PROMPT_SYSTEM=$(appfw_decode_string "$raw_value")
      ;;
    prompt:template)
      APP_PROMPT_TEMPLATE=$(appfw_decode_string "$raw_value")
      ;;
    prompt:max_context_tokens)
      APP_PROMPT_MAX_CONTEXT_TOKENS=$(appfw_parse_integer "$raw_value")
      ;;
    prompt:max_input_bytes)
      APP_PROMPT_MAX_INPUT_BYTES=$(appfw_parse_integer "$raw_value")
      ;;
    prompt:max_output_tokens)
      APP_PROMPT_MAX_OUTPUT_TOKENS=$(appfw_parse_integer "$raw_value")
      ;;
    output:mode)
      APP_OUTPUT_MODE=$(appfw_decode_string "$raw_value")
      ;;
    output:fields)
      APP_OUTPUT_FIELDS=$(appfw_parse_string_array "$raw_value")
      ;;
    hooks:build_prompt)
      APP_HOOK_BUILD_PROMPT=$(appfw_decode_string "$raw_value")
      ;;
    hooks:pre_run)
      APP_HOOK_PRE_RUN=$(appfw_decode_string "$raw_value")
      ;;
    args:name)
      APP_ARG_NAME=$(appfw_decode_string "$raw_value")
      ;;
    args:type)
      APP_ARG_TYPE=$(appfw_decode_string "$raw_value")
      ;;
    args:long)
      APP_ARG_LONG=$(appfw_decode_string "$raw_value")
      ;;
    args:short)
      APP_ARG_SHORT=$(appfw_decode_string "$raw_value")
      ;;
    args:description)
      APP_ARG_DESCRIPTION=$(appfw_decode_string "$raw_value")
      ;;
    args:default)
      case "$APP_ARG_TYPE" in
        flag|integer)
          APP_ARG_DEFAULT=$(appfw_trim "$raw_value")
          ;;
        *)
          APP_ARG_DEFAULT=$(appfw_decode_string "$raw_value")
          ;;
      esac
      ;;
    args:choices)
      APP_ARG_CHOICES=$(appfw_parse_string_array "$raw_value")
      ;;
    *)
      appfw_fail "Unsupported key ${section:+$section.}$key"
      ;;
  esac
}

appfw_validate_definition() {
  [ -n "$APP_ID" ] || appfw_fail "Missing id"
  [ -n "$APP_VERSION" ] || appfw_fail "Missing version"
  [ -n "$APP_SUMMARY" ] || appfw_fail "Missing summary"
  [ -n "$APP_DESCRIPTION" ] || appfw_fail "Missing description"
  [ -n "$APP_COMMAND" ] || appfw_fail "Missing command"
  [ -n "$APP_KIND" ] || appfw_fail "Missing kind"
  [ -n "$APP_HELP_USAGE" ] || appfw_fail "Missing help.usage"
  [ -s "$APP_EXAMPLES_FILE" ] || appfw_fail "Missing help.examples"
  [ -n "$APP_INPUT_MODE" ] || appfw_fail "Missing input.mode"
  [ -n "$APP_INPUT_NAME" ] || appfw_fail "Missing input.name"
  [ -n "$APP_INPUT_REQUIRED" ] || appfw_fail "Missing input.required"
  [ -n "$APP_OUTPUT_MODE" ] || appfw_fail "Missing output.mode"

  case "$APP_COMMAND" in
    ''|*/*|*[!A-Za-z0-9_-]*)
      appfw_fail "Invalid command name: $APP_COMMAND"
      ;;
  esac

  case "$APP_KIND" in
    ai-command|ai-text)
      ;;
    *)
      appfw_fail "Unsupported kind: $APP_KIND"
      ;;
  esac

  case "$APP_INPUT_MODE" in
    none|single|rest)
      ;;
    *)
      appfw_fail "Unsupported input mode: $APP_INPUT_MODE"
      ;;
  esac

  case "$APP_OUTPUT_MODE" in
    shell_command|text|structured_text)
      ;;
    *)
      appfw_fail "Unsupported output mode: $APP_OUTPUT_MODE"
      ;;
  esac

  case "$APP_KIND:$APP_OUTPUT_MODE" in
    ai-command:shell_command|ai-text:text|ai-text:structured_text)
      ;;
    *)
      appfw_fail "Invalid kind/output combination: $APP_KIND + $APP_OUTPUT_MODE"
      ;;
  esac

  case "$APP_KIND" in
    ai-command|ai-text)
      [ -n "$APP_PROMPT_SYSTEM" ] || appfw_fail "AI apps must define prompt.system"
      [ -n "$APP_PROMPT_TEMPLATE" ] || appfw_fail "AI apps must define prompt.template"
      [ -n "$APP_PROMPT_MAX_CONTEXT_TOKENS" ] || appfw_fail "AI apps must define prompt.max_context_tokens"
      [ -n "$APP_PROMPT_MAX_INPUT_BYTES" ] || appfw_fail "AI apps must define prompt.max_input_bytes"
      [ -n "$APP_PROMPT_MAX_OUTPUT_TOKENS" ] || appfw_fail "AI apps must define prompt.max_output_tokens"
      ;;
  esac

  if [ "$APP_OUTPUT_MODE" = "structured_text" ] && [ -z "$APP_OUTPUT_FIELDS" ]; then
    appfw_fail "structured_text output requires output.fields"
  fi

  if [ -n "$APP_REQUIRES" ]; then
    old_ifs=$IFS
    IFS=,
    # shellcheck disable=SC2086
    set -- $APP_REQUIRES
    IFS=$old_ifs
    for required_command in "$@"; do
      case "$required_command" in
        ''|*[!A-Za-z0-9._+-]*)
          appfw_fail "Invalid required command: $required_command"
          ;;
      esac
    done
  fi

  if [ -n "$APP_SUPPORTED_SHELLS" ]; then
    old_ifs=$IFS
    IFS=,
    # shellcheck disable=SC2086
    set -- $APP_SUPPORTED_SHELLS
    IFS=$old_ifs
    for shell_name in "$@"; do
      case "$shell_name" in
        fish|zsh)
          ;;
        *)
          appfw_fail "Unsupported shell: $shell_name"
          ;;
      esac
    done
  fi

  appfw_validate_single_line "id" "$APP_ID"
  appfw_validate_single_line "version" "$APP_VERSION"
  appfw_validate_single_line "summary" "$APP_SUMMARY"
  appfw_validate_single_line "description" "$APP_DESCRIPTION"
  appfw_validate_single_line "command" "$APP_COMMAND"
  appfw_validate_single_line "kind" "$APP_KIND"
  appfw_validate_single_line "requires_commands" "$APP_REQUIRES"
  appfw_validate_single_line "supported_shells" "$APP_SUPPORTED_SHELLS"
  appfw_validate_single_line "help.usage" "$APP_HELP_USAGE"
  appfw_validate_single_line "input.mode" "$APP_INPUT_MODE"
  appfw_validate_single_line "input.name" "$APP_INPUT_NAME"
  appfw_validate_single_line "output.mode" "$APP_OUTPUT_MODE"
  appfw_validate_single_line "output.fields" "$APP_OUTPUT_FIELDS"
  appfw_validate_single_line "hooks.build_prompt" "$APP_HOOK_BUILD_PROMPT"
  appfw_validate_single_line "hooks.pre_run" "$APP_HOOK_PRE_RUN"
}

appfw_load_definition() {
  manifest_path=$1
  appfw_reset_definition
  appfw_begin_args_file "$2" "$3"

  while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    line=$(appfw_trim "$raw_line")
    [ -n "$line" ] || continue

    case "$line" in
      \#*)
        continue
        ;;
      \[\[*\]\])
        section_name=${line#\[\[}
        section_name=${section_name%\]\]}
        [ "$section_name" = "args" ] || appfw_fail "Unsupported array-of-table section: $line"
        appfw_start_arg_block
        continue
        ;;
      \[*\])
        appfw_finish_arg_block
        section_name=${line#\[}
        section_name=${section_name%\]}
        case "$section_name" in
          *.*|*[*|*]*)
            appfw_fail "Unsupported section syntax: $line"
            ;;
        esac
        appfw_require_known_section "$section_name"
        APP_SECTION=$section_name
        continue
        ;;
      *=*)
        key=$(appfw_trim "${line%%=*}")
        value=${line#*=}
        value=$(appfw_trim "$value")
        appfw_set_value "$APP_SECTION" "$key" "$value"
        ;;
      *)
        appfw_fail "Unsupported TOML line: $line"
        ;;
    esac
  done <"$manifest_path"

  appfw_finish_arg_block
  appfw_validate_definition
}
