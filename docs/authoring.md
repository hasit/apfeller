# Authoring Apps

Each app lives under `apps/<id>/` and includes:

- `app.env`
- `bin/<command>`
- `completions/fish/<command>.fish`
- `completions/zsh/_<command>`

Required `app.env` variables:

- `APFELLER_ID`
- `APFELLER_VERSION`
- `APFELLER_SUMMARY`
- `APFELLER_DESCRIPTION`
- `APFELLER_ENTRYPOINT`
- `APFELLER_REQUIRES`
- `APFELLER_SUPPORTED_SHELLS`
- `APFELLER_BUNDLE_FILES`
- `APFELLER_ARCHIVE`

Manifest rules for v1:

- Use single-line values only. Tabs and newlines are rejected during packaging.
- List-like values use comma-separated strings.
- Entrypoints must be POSIX `sh` scripts.
- Apps should be self-contained when bundled.
- If an app uses apfel, source [runtime/lib/apfel.sh](/Users/hasit/github/apfeller/runtime/lib/apfel.sh).
- Command names are public and unprefixed, so choose carefully.

AI-backed app scripts must also declare:

- `MAX_CONTEXT_TOKENS=4096`
- `MAX_INPUT_BYTES`
- `MAX_OUTPUT_TOKENS`

CI checks `system_prompt + MAX_INPUT_BYTES + MAX_OUTPUT_TOKENS + 256 <= 4096`
for every AI app to keep requests inside apfel's fixed combined window.

To package release bundles locally:

```sh
scripts/package_release.sh --output-dir dist
```

That will:

- Build each app tarball under `dist/`
- Generate `dist/apfeller-catalog.tsv`
- Build the portable manager asset at `dist/apfeller.tar.gz`
