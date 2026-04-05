# apfeller

`apfeller` is a small shell app manager for shell-native utilities built on top
of [apfel](https://github.com/Arthur-Ficial/apfel).

It installs a lightweight manager first, then lets users opt into focused apps
like `cmd`, `oneliner`, `define`, and `port`.

## What v1 includes

- A POSIX `sh`-based `apfeller` manager
- First-party shell-native app manifests under `apps/`
- Portable POSIX shell app bundles
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

The manager fetches its app catalog from the latest release catalog asset
`apfeller-catalog.tsv`, then downloads matching app bundle tarballs from the
same release.

## Commands

```text
apfeller list [--installed]
apfeller info <app>
apfeller install <app>...
apfeller uninstall <app>...
apfeller update --self | --all | <app>...
apfeller doctor
```

## Seed Apps

- `cmd`: natural language to a single shell command via `apfel`
- `oneliner`: natural language to a compact UNIX pipeline via `apfel`
- `define`: tiny multilingual dictionary lookup via `apfel`
- `port`: show which process is using a local port

## Development

Prerequisites:

- macOS
- `curl`, `tar`, `shasum`

Validate locally:

```sh
tests/apps/test_cmd.sh
tests/apps/test_oneliner.sh
tests/apps/test_define.sh
tests/apps/test_port.sh
tests/install/test_install.sh
tests/release/test_package_release.sh
tests/e2e/test_manager.sh
tests/e2e/test_checksum_mismatch.sh
```

Package local release assets:

```sh
scripts/package_release.sh --output-dir dist
```

That produces:

- `dist/apfeller.tar.gz`
- `dist/apfeller-catalog.tsv`
- `dist/*.tar.gz` for app bundles

More detail lives in [docs/install.md](/Users/hasit/github/apfeller/docs/install.md),
[docs/authoring.md](/Users/hasit/github/apfeller/docs/authoring.md), and
[docs/releasing.md](/Users/hasit/github/apfeller/docs/releasing.md).
