# apfeller

`apfeller` is a manager + runtime for small shell apps built on
[apfel](https://apfel.franzai.com/) ([source repo](https://github.com/Arthur-Ficial/apfel)).
The AI apps run fully local on your Mac with zero API cost: no API bill, no API
keys, and no cloud round-trip.

It installs a lightweight manager first, then lets users opt into focused apps.
The AI apps are intentionally designed for small inputs, small outputs, and
instant single-turn results so they fit apfel's fixed 4,096-token combined
context window.

## What v1 includes

- A POSIX `sh`-based `apfeller` manager
- A shell app framework with shared `app.toml` validation and packaging tooling
- Compiled runtime manifests plus generated wrappers and completions at install time
- Portable POSIX shell app bundles with optional prompt and validation hooks
- A default remote app catalog published from `hasit/apfeller-apps`
- Fish and zsh integration
- A one-line installer for the manager

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh
```

That installs only the manager. Apps are installed separately:

```sh
apfeller list
apfeller install cmd oneliner
```

The manager fetches its app catalog from the stable raw URL
`https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv`
by default, then downloads the exact bundle URLs listed in that catalog.

## Commands

```text
apfeller list [--installed]
apfeller info <app>
apfeller install <app>...
apfeller uninstall <app>...
apfeller update --self | --all | <app>...
apfeller doctor
```

## AI Apps

- `cmd`: natural language to a single shell command via `apfel`
- `oneliner`: natural language to a compact UNIX pipeline via `apfel`
- `define`: tiny multilingual dictionary lookup via `apfel`

## Development

Prerequisites:

- macOS
- `curl`, `tar`, `shasum`

Validate locally:

```sh
tests/apps/test_cmd.sh
tests/apps/test_oneliner.sh
tests/apps/test_define.sh
tests/apps/test_context_budget.sh
tests/docs/test_public_copy.sh
tests/install/test_install.sh
tests/release/test_package_release.sh
tests/release/test_app_schema.sh
tests/e2e/test_manager.sh
tests/e2e/test_checksum_mismatch.sh
```

Package local release assets:

```sh
scripts/package_release.sh --output-dir dist
scripts/package_catalog.sh --output-dir dist --app-dir fixtures/apps --bundle-base-url "file://$PWD/dist"
```

That produces:

- `dist/apfeller.tar.gz`
- `dist/apfeller-catalog.tsv`
- `dist/<app>-<revision>.tar.gz` for fixture app bundles

Each app bundle now contains its `app.toml`, a compiled runtime manifest, args
metadata, examples metadata, and any declared hooks. Installed commands are
framework-generated wrappers that call `apfeller __run-app`.

More detail lives in [docs/install.md](/Users/hasit/github/apfeller/docs/install.md),
[docs/authoring.md](/Users/hasit/github/apfeller/docs/authoring.md), and
[docs/releasing.md](/Users/hasit/github/apfeller/docs/releasing.md).
