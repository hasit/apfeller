# Releasing

`apfeller` releases publish:

- A portable manager asset: `apfeller.tar.gz`
- Versioned app bundle archives under `apps/`
- A generated `apfeller-catalog.tsv` asset with matching SHA-256 checksums

Each app archive contains the author-facing `app.toml`, a compiled
`runtime/manifest.env`, `runtime/args.tsv`, `runtime/examples.txt`, and any
declared hooks. App archives no longer ship handwritten `bin/` entrypoints or
handwritten app completions.

Local release packaging:

```sh
scripts/package_release.sh --output-dir dist
```

That script:

- Builds app bundle tarballs into `dist/`
- Validates constrained `app.toml` definitions
- Compiles framework runtime manifests for each app
- Generates `dist/apfeller-catalog.tsv`
- Packages the shell manager and completions into `dist/apfeller.tar.gz`

GitHub Actions validates the same shell packaging flow in CI.
