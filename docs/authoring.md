# Authoring Apps

Each app lives under `apps/<id>/` and is declared once in `app.toml`.
Optional executable hooks live under `apps/<id>/hooks/`.

`apfeller` does not ship handwritten per-app entrypoint scripts or handwritten
per-app completions anymore. Release packaging compiles each `app.toml` into a
shell-friendly runtime manifest, and install time generates the wrapper script
and fish/zsh completions.

## Layout

- `apps/<id>/app.toml`
- `apps/<id>/hooks/*.sh` when the app needs hooks

## Required Top-Level Fields

- `id`
- `version`
- `summary`
- `description`
- `command`
- `kind`
- `requires_commands`
- `supported_shells`

Supported `kind` values:

- `ai-command`
- `ai-text`
- `local-command`

## Required Sections

`[help]`

- `usage`
- `examples`

`[input]`

- `mode = "none" | "single" | "rest"`
- `name`
- `required = true | false`

`[output]`

- `mode = "shell_command" | "text" | "structured_text" | "local_passthrough"`
- `fields = [...]` is required only for `structured_text`

`[prompt]` for AI apps

- `system`
- `template`
- `max_context_tokens`
- `max_input_bytes`
- `max_output_tokens`

`[hooks]` for hook-backed apps

- `build_prompt` optional
- `pre_run` optional
- `local_run` required for `local-command`

`[[args]]` blocks are optional and support:

- `name`
- `type = "flag" | "string" | "integer" | "enum"`
- `long`
- `short` optional
- `description`
- `default` optional
- `choices` optional and required for `enum`

## Valid Kind / Output Pairs

- `ai-command` + `shell_command`
- `ai-text` + `text`
- `ai-text` + `structured_text`
- `local-command` + `local_passthrough`

## Prompt Templates

Prompt templates use simple placeholder substitution only:

- `{{input}}`
- `{{arg.<name>}}`

There are no loops, nested expressions, or conditionals in v1.

## Hook Contract

Hooks are executed, not sourced. `apfeller` passes:

- `APFELLER_APP_DIR`
- `APFELLER_INPUT`
- `APFELLER_ARG_<UPPER_SNAKE_NAME>` for each declared arg

Hook behavior:

- `build_prompt` writes the final user prompt to stdout
- `pre_run` validates or prepares and exits non-zero on failure
- `local_run` performs the local command execution and owns stdout/stderr

## 4096-Token Guard

AI apps declare their apfel window in `[prompt]`. CI checks the compiled
runtime config with:

```text
system_prompt_bytes + max_input_bytes + max_output_tokens + 256 <= 4096
```

Runtime also rejects oversized requests before calling apfel.

## Current Seed Apps

- `cmd`: `ai-command`
- `oneliner`: `ai-command`
- `define`: `ai-text`
- `port`: `local-command`

## Release Packaging

```sh
scripts/package_release.sh --output-dir dist
```

That produces:

- `dist/apfeller.tar.gz`
- `dist/apfeller-catalog.tsv`
- `dist/<app>-<version>.tar.gz`

Each app archive contains:

- `app.toml`
- `runtime/manifest.env`
- `runtime/args.tsv`
- `runtime/examples.txt`
- declared hook files, when present
