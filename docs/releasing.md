# Releasing

`apfeller` releases publish:

- A portable manager asset: `apfeller.tar.gz`
- Versioned app bundle archives under `apps/`
- A generated `apfeller-catalog.tsv` asset with matching SHA-256 checksums

Local release packaging:

```sh
scripts/package_release.sh --output-dir dist
```

That script:

- Builds app bundle tarballs into `dist/`
- Generates `dist/apfeller-catalog.tsv`
- Packages the shell manager and completions into `dist/apfeller.tar.gz`

GitHub Actions validates the same shell packaging flow in CI.
