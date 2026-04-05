# apfeller

`apfeller` is the manager + runtime repo for small shell apps built around
[apfel](https://apfel.franzai.com/).
The apps run fully local on your Mac with zero API cost: no API bill, no API
keys, and no cloud round-trip.

End-user docs live at [hasit.github.io/apfeller](https://hasit.github.io/apfeller/).
App authors can start at [hasit.github.io/apfeller/write-an-app/](https://hasit.github.io/apfeller/write-an-app/).

## Repo Split

- `apfeller`: manager/runtime, installer, shell integration, packaging helpers,
  fixture apps, and tests.
- `apfeller-apps`: published app definitions, catalog generation, and app bundle
  releases.

The manager fetches its app catalog from:

`https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv`

by default, then downloads the exact bundle URLs listed in that catalog.

## What This Repo Contains

- A POSIX `sh`-based `apfeller` manager
- Shell integration for fish and zsh
- Shared `app.toml` validation and packaging tooling
- Compiled runtime manifests plus generated wrappers and completions
- Fixture apps under `fixtures/apps` for local testing
- A one-line installer for the manager

## Development

Prerequisites:

- macOS
- `curl`, `tar`, `shasum`

Validate locally:

- `tests/apps/test_cmd.sh`
- `tests/apps/test_oneliner.sh`
- `tests/apps/test_define.sh`
- `tests/apps/test_context_budget.sh`
- `tests/docs/test_public_copy.sh`
- `tests/install/test_install.sh`
- `tests/release/test_package_release.sh`
- `tests/release/test_app_schema.sh`
- `tests/e2e/test_manager.sh`
- `tests/e2e/test_checksum_mismatch.sh`

## Packaging

Package the manager release asset:

```sh
scripts/package_release.sh --output-dir dist
```

That produces:

- `dist/apfeller.tar.gz`

Package a local fixture catalog and fixture bundles for testing:

```sh
scripts/package_catalog.sh --output-dir dist --app-dir fixtures/apps --bundle-base-url "file://$PWD/dist"
```

That produces:

- `dist/apfeller-catalog.tsv`
- `dist/<app>-<revision>.tar.gz` for fixture app bundles

Each app bundle now contains its `app.toml`, a compiled runtime manifest, args
metadata, examples metadata, and any declared hooks. Installed commands are
framework-generated wrappers that call `apfeller __run-app`.

Real published apps no longer live in this repo. Use `apfeller-apps` for app
catalog and bundle publication work.

## Releases

Manager releases are published automatically by
[release.yml](/Users/hasit/github/apfeller/.github/workflows/release.yml)
after CI succeeds on `main`, as long as the current [VERSION](/Users/hasit/github/apfeller/VERSION)
does not already have a matching GitHub release.

To cut a new manager release:

1. Update [VERSION](/Users/hasit/github/apfeller/VERSION).
2. Merge that change to `main`.
3. Let the workflow publish `v<VERSION>` with `dist/apfeller.tar.gz`.
