#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

stub_dir="$tmp_dir/stubs"
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

PATH="$stub_dir:$PATH" sh "$ROOT_DIR/scripts/package_release.sh" --output-dir "$tmp_dir/dist"

assert_file_exists "$tmp_dir/dist/cmd-0.1.0.tar.gz"
assert_file_exists "$tmp_dir/dist/define-0.1.0.tar.gz"
assert_file_exists "$tmp_dir/dist/oneliner-0.1.0.tar.gz"
assert_file_exists "$tmp_dir/dist/port-0.1.0.tar.gz"
assert_file_exists "$tmp_dir/dist/apfeller.tar.gz"
assert_file_exists "$tmp_dir/dist/apfeller-catalog.tsv"

if ! awk -F '\t' '
  NR > 1 && $10 == "" {
    empty = 1
  }
  END {
    exit empty ? 1 : 0
  }
' "$tmp_dir/dist/apfeller-catalog.tsv"; then
  printf '%s\n' "expected release catalog checksums to be populated" >&2
  exit 1
fi

cmd_contents=$(tar -tzf "$tmp_dir/dist/cmd-0.1.0.tar.gz")
assert_contains "$cmd_contents" './app.toml' "app bundles should include the source app definition"
assert_contains "$cmd_contents" './runtime/manifest.env' "app bundles should include the compiled runtime manifest"
assert_contains "$cmd_contents" './runtime/args.tsv' "app bundles should include declared args metadata"
assert_contains "$cmd_contents" './runtime/examples.txt' "app bundles should include generated examples metadata"
assert_not_contains "$cmd_contents" './bin/' "framework app bundles should not ship handwritten entrypoints"
assert_not_contains "$cmd_contents" './completions/' "framework app bundles should not ship handwritten completions"

port_contents=$(tar -tzf "$tmp_dir/dist/port-0.1.0.tar.gz")
assert_contains "$port_contents" './hooks/local_run.sh' "local-command bundles should include declared hooks"
