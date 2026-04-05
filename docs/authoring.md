# Authoring Apps

Each app lives under `apps/<id>/` and is declared once in `app.toml`.
Optional executable hooks live under `apps/<id>/hooks/`.

`apfeller` does not ship handwritten per-app entrypoint scripts or handwritten
per-app completions anymore. Release packaging compiles each `app.toml` into a
shell-friendly runtime manifest, and install time generates the wrapper script
and fish/zsh completions.

## Layout

- `apps/<id>/app.toml`: the single source of truth for the app definition.
- `apps/<id>/hooks/*.sh`: optional executable hooks used for validation or
  prompt building.

## Required Top-Level Fields

- `id`: stable app identifier used in the catalog and `apfeller install <id>`.
- `version`: app release version used for packaging and store paths.
- `summary`: short one-line description shown in listings.
- `description`: fuller description shown in help and `apfeller info`.
- `command`: installed command name users run from the shell.
- `kind`: framework behavior family for the app.
- `requires_commands`: external commands the app depends on, such as `apfel`
  or `pbcopy`.
- `supported_shells`: shells that should receive generated completions.

Supported `kind` values:

- `ai-command`: asks apfel for one shell command and supports `--copy` and
  `--execute`.
- `ai-text`: asks apfel for plain text or structured text and supports
  `--copy`.

## Required Sections

`[help]`

- `usage`: one-line usage string shown in generated `--help`.
- `examples`: example invocations shown in generated `--help`.

`[input]`

- `mode = "none" | "single" | "rest"`: how positional input is consumed.
  `none` means no positional input, `single` means exactly one value,
  `rest` means all remaining words joined together.
- `name`: human label for the positional input concept.
- `required = true | false`: whether positional input must be present.

`[output]`

- `mode = "shell_command" | "text" | "structured_text"`:
  how the framework should run and format the result.
- `fields = [...]`: ordered field names expected from the model when
  `mode = "structured_text"`.

`[prompt]` for AI apps

- `system`: system prompt sent to apfel.
- `template`: user prompt template after placeholder substitution.
- `max_context_tokens`: total model window budget, normally `4096`.
- `max_input_bytes`: maximum rendered prompt size accepted before calling
  apfel.
- `max_output_tokens`: maximum number of tokens requested from apfel.

`[hooks]` for hook-backed apps

- `build_prompt` optional: executable that prints the final prompt instead of
  using `prompt.template`.
- `pre_run` optional: executable that validates or prepares before the main
  run.

`[[args]]` blocks are optional and support:

- `name`: stable internal arg name used in templates and hook env vars.
- `type = "flag" | "string" | "integer" | "enum"`: how the framework parses
  the value.
- `long`: long option name without the leading `--`.
- `short` optional: one-letter short option without the leading `-`.
- `description`: help and completion text for the option.
- `default` optional: value used when the user does not pass the option.
- `choices` optional and required for `enum`: allowed values for enum args.

## Valid Kind / Output Pairs

- `ai-command` + `shell_command`
- `ai-text` + `text`
- `ai-text` + `structured_text`

## Prompt Templates

Prompt templates use simple placeholder substitution only:

- `{{input}}`: replaced with the parsed positional input.
- `{{arg.<name>}}`: replaced with the parsed value of a declared arg.

There are no loops, nested expressions, or conditionals in v1.

## Hook Contract

Hooks are executed, not sourced. `apfeller` passes:

- `APFELLER_APP_DIR`: absolute path to the unpacked app bundle.
- `APFELLER_INPUT`: parsed positional input after framework validation.
- `APFELLER_ARG_<UPPER_SNAKE_NAME>`: parsed value for each declared arg.

Hook behavior:

- `build_prompt` writes the final user prompt to stdout.
- `pre_run` validates or prepares and exits non-zero on failure.

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
