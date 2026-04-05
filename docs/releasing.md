# Releasing

`apfeller` releases publish:

- A portable manager asset: `apfeller.tar.gz`

Published app bundles and the catalog now belong to the separate
`apfeller-apps` repo. This repo keeps fixture apps and local packaging scripts
so CI can validate the manager against the same catalog format.

Manager release packaging:

```sh
scripts/package_release.sh --output-dir dist
```

That script packages only:

- `dist/apfeller.tar.gz`

Local fixture catalog packaging:

```sh
scripts/package_catalog.sh --output-dir dist --app-dir fixtures/apps --bundle-base-url "file://$PWD/dist"
```

That script:

- Validates constrained fixture `app.toml` definitions
- Computes a generated revision for each fixture app
- Compiles framework runtime manifests for each app
- Generates `dist/apfeller-catalog.tsv`
- Packages fixture app bundles into `dist/<app>-<revision>.tar.gz`

GitHub Actions validates the same shell packaging flow in CI.
