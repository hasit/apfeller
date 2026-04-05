#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

stub_dir="$tmp_dir/stubs"
dist_dir="$tmp_dir/dist"
mkdir -p "$stub_dir"

cat >"$stub_dir/python3" <<'EOF'
#!/bin/sh
printf '%s\n' "python3 should not be called during packaging" >&2
exit 99
EOF

cat >"$stub_dir/zig" <<'EOF'
#!/bin/sh
printf '%s\n' "zig should not be called during packaging" >&2
exit 99
EOF

chmod +x "$stub_dir/python3" "$stub_dir/zig"

PATH="$stub_dir:$PATH" sh "$ROOT_DIR/scripts/package_release.sh" --output-dir "$dist_dir"
PATH="$stub_dir:$PATH" sh "$ROOT_DIR/scripts/package_catalog.sh" --output-dir "$dist_dir" --app-dir "$ROOT_DIR/fixtures/apps" --bundle-base-url "file://$dist_dir"

assert_file_exists "$dist_dir/apfeller.tar.gz"
assert_file_exists "$dist_dir/apfeller-catalog.tsv"

manager_version=$(tr -d '\n' <"$ROOT_DIR/VERSION")
source_version_output=$(sh "$ROOT_DIR/shell/bin/apfeller" --version)
assert_contains "$source_version_output" "apfeller $manager_version" "repo version output should match VERSION"

packaged_manager="$tmp_dir/apfeller"
tar -xOf "$dist_dir/apfeller.tar.gz" ./bin/apfeller >"$packaged_manager"
chmod +x "$packaged_manager"
packaged_version_output=$(sh "$packaged_manager" --version)
assert_contains "$packaged_version_output" "apfeller $manager_version" "packaged manager version should match VERSION"

packaged_manager_contents=$(cat "$packaged_manager")
assert_not_contains "$packaged_manager_contents" '__APFELLER_MANAGER_VERSION__' "packaged manager should not keep the version placeholder"

cmd_bundle=$(find "$dist_dir" -maxdepth 1 -name 'fixture-cmd-*.tar.gz' | head -n 1)
define_bundle=$(find "$dist_dir" -maxdepth 1 -name 'fixture-define-*.tar.gz' | head -n 1)
oneliner_bundle=$(find "$dist_dir" -maxdepth 1 -name 'fixture-oneliner-*.tar.gz' | head -n 1)

assert_file_exists "$cmd_bundle"
assert_file_exists "$define_bundle"
assert_file_exists "$oneliner_bundle"

catalog_header=$(head -n 1 "$dist_dir/apfeller-catalog.tsv")
assert_contains "$catalog_header" 'revision' "catalog should expose generated revisions"
assert_contains "$catalog_header" 'bundle_url' "catalog should expose full bundle URLs"

if ! awk -F '\t' '
  NR > 1 && ($2 == "" || $9 == "" || $10 == "") {
    empty = 1
  }
  END {
    exit empty ? 1 : 0
  }
' "$dist_dir/apfeller-catalog.tsv"; then
  printf '%s\n' "expected catalog revisions, bundle URLs, and checksums to be populated" >&2
  exit 1
fi

cmd_contents=$(tar -tzf "$cmd_bundle")
assert_contains "$cmd_contents" './app.toml' "app bundles should include the source app definition"
assert_contains "$cmd_contents" './runtime/manifest.env' "app bundles should include the compiled runtime manifest"
assert_contains "$cmd_contents" './runtime/args.tsv' "app bundles should include declared args metadata"
assert_contains "$cmd_contents" './runtime/examples.txt' "app bundles should include generated examples metadata"
assert_not_contains "$cmd_contents" './bin/' "framework app bundles should not ship handwritten entrypoints"
assert_not_contains "$cmd_contents" './completions/' "framework app bundles should not ship handwritten completions"

cmd_manifest=$(tar -xOf "$cmd_bundle" ./runtime/manifest.env)
assert_contains "$cmd_manifest" 'APFELLER_APP_REVISION=' "compiled manifests should include the generated revision"
assert_not_contains "$cmd_manifest" 'APFELLER_APP_VERSION=' "compiled manifests should not include manual app versions"
assert_not_contains "$cmd_manifest" 'APFELLER_HOOK_LOCAL_RUN=' "compiled manifests should not include local-run hooks"

if awk -F '\t' 'NR > 1 && $1 == "cmd" { found = 1 } END { exit found ? 0 : 1 }' "$dist_dir/apfeller-catalog.tsv"; then
  printf '%s\n' "fixture catalog should not include published app ids" >&2
  exit 1
fi

original_revision=$(awk -F '\t' 'NR > 1 && $1 == "fixture-cmd" { print $2; exit }' "$dist_dir/apfeller-catalog.tsv")

modified_repo="$tmp_dir/repo-modified"
cp -R "$ROOT_DIR" "$modified_repo"

cat >"$modified_repo/fixtures/apps/fixture-cmd/app.toml" <<'EOF'
id = "fixture-cmd"
summary = "Fixture app that turns natural language into a shell command, with an updated fixture summary."
description = "Generate a single macOS shell command from a natural language request. Supports copy to clipboard and optional execution after confirmation."
command = "fixture-cmd"
kind = "ai-command"
requires_commands = ["apfel", "pbcopy"]
supported_shells = ["fish", "zsh"]

[help]
usage = 'fixture-cmd [OPTIONS] "what you want to do"'
examples = ['fixture-cmd "find all .log files modified today"', 'fixture-cmd -x "what process is using port 3000"', 'fixture-cmd -c "list merged git branches"']

[input]
mode = "rest"
name = "request"
required = true

[prompt]
system = "You convert natural language into a single macOS shell command. Output ONLY the command. No markdown. No code fences. No comments. No prose. One line only. Use standard terminal tools. Prefer safe read-only commands unless the user explicitly asks to modify delete or execute something. If the user mentions a filename path port branch or pattern preserve it verbatim instead of inventing alternatives. If multiple answers are possible pick the most direct command."
template = "{{input}}"
max_context_tokens = 4096
max_input_bytes = 1024
max_output_tokens = 96

[output]
mode = "shell_command"
EOF

PATH="$stub_dir:$PATH" APFELLER_ROOT_DIR="$modified_repo" sh "$ROOT_DIR/scripts/package_catalog.sh" --output-dir "$tmp_dir/dist-modified" --app-dir "$modified_repo/fixtures/apps" --bundle-base-url "file://$tmp_dir/dist-modified"
modified_revision=$(awk -F '\t' 'NR > 1 && $1 == "fixture-cmd" { print $2; exit }' "$tmp_dir/dist-modified/apfeller-catalog.tsv")

if [ "$original_revision" = "$modified_revision" ]; then
  printf '%s\n' "expected fixture-cmd revision to change when app.toml changes" >&2
  exit 1
fi

hook_repo="$tmp_dir/repo-hook"
cp -R "$ROOT_DIR" "$hook_repo"
mkdir -p "$hook_repo/fixtures/apps/fixture-cmd/hooks"

cat >"$hook_repo/fixtures/apps/fixture-cmd/app.toml" <<'EOF'
id = "fixture-cmd"
summary = "Fixture app that turns natural language into a shell command."
description = "Generate a single macOS shell command from a natural language request. Supports copy to clipboard and optional execution after confirmation."
command = "fixture-cmd"
kind = "ai-command"
requires_commands = ["apfel", "pbcopy"]
supported_shells = ["fish", "zsh"]

[help]
usage = 'fixture-cmd [OPTIONS] "what you want to do"'
examples = ['fixture-cmd "find all .log files modified today"', 'fixture-cmd -x "what process is using port 3000"', 'fixture-cmd -c "list merged git branches"']

[input]
mode = "rest"
name = "request"
required = true

[prompt]
system = "You convert natural language into a single macOS shell command. Output ONLY the command. No markdown. No code fences. No comments. No prose. One line only. Use standard terminal tools. Prefer safe read-only commands unless the user explicitly asks to modify delete or execute something. If the user mentions a filename path port branch or pattern preserve it verbatim instead of inventing alternatives. If multiple answers are possible pick the most direct command."
template = "{{input}}"
max_context_tokens = 4096
max_input_bytes = 1024
max_output_tokens = 96

[output]
mode = "shell_command"

[hooks]
pre_run = "hooks/pre_run.sh"
EOF

cat >"$hook_repo/fixtures/apps/fixture-cmd/hooks/pre_run.sh" <<'EOF'
#!/bin/sh
exit 0
EOF

PATH="$stub_dir:$PATH" APFELLER_ROOT_DIR="$hook_repo" sh "$ROOT_DIR/scripts/package_catalog.sh" --output-dir "$tmp_dir/dist-hook-one" --app-dir "$hook_repo/fixtures/apps" --bundle-base-url "file://$tmp_dir/dist-hook-one"
hook_revision_one=$(awk -F '\t' 'NR > 1 && $1 == "fixture-cmd" { print $2; exit }' "$tmp_dir/dist-hook-one/apfeller-catalog.tsv")

cat >"$hook_repo/fixtures/apps/fixture-cmd/hooks/pre_run.sh" <<'EOF'
#!/bin/sh
printf '%s\n' "fixture hook changed" >/dev/null
exit 0
EOF

PATH="$stub_dir:$PATH" APFELLER_ROOT_DIR="$hook_repo" sh "$ROOT_DIR/scripts/package_catalog.sh" --output-dir "$tmp_dir/dist-hook-two" --app-dir "$hook_repo/fixtures/apps" --bundle-base-url "file://$tmp_dir/dist-hook-two"
hook_revision_two=$(awk -F '\t' 'NR > 1 && $1 == "fixture-cmd" { print $2; exit }' "$tmp_dir/dist-hook-two/apfeller-catalog.tsv")

if [ "$hook_revision_one" = "$hook_revision_two" ]; then
  printf '%s\n' "expected fixture-cmd revision to change when hook content changes" >&2
  exit 1
fi
