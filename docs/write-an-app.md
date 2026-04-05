---
title: Write an app
permalink: /write-an-app/
---

# Write an app

This page focuses on writing and testing an `apfeller` app locally. It does not
cover the public release workflow.

`apfeller` app sources live in the separate
[`apfeller-apps`](https://github.com/hasit/apfeller-apps) repo. Each app lives
under `apps/<id>/app.toml`, with optional shell hooks under `apps/<id>/hooks/`.

## App Layout

- `apps/<id>/app.toml`: the app definition
- `apps/<id>/hooks/build_prompt.sh`: optional hook that prints the final prompt
- `apps/<id>/hooks/pre_run.sh`: optional hook that validates or prepares before
  the app runs

## Minimal Example

```toml
id = "folder-brief"
summary = "Turn a short topic into a two-sentence brief."
description = "Generate a short shell-friendly explanation for a topic or path."
command = "folder-brief"
kind = "ai-text"
requires_commands = ["apfel"]
supported_shells = ["fish", "zsh"]

[help]
usage = 'folder-brief "what to summarize"'
examples = ['folder-brief "Downloads"', 'folder-brief "launchd agents"']

[input]
mode = "rest"
name = "topic"
required = true

[prompt]
system = "You write a concise two-sentence brief for a macOS terminal user. No bullets. No markdown."
template = "Topic: {{input}}"
max_context_tokens = 4096
max_input_bytes = 512
max_output_tokens = 80

[output]
mode = "text"
```

## Required Fields and Sections

Required top-level fields:

- `id`
- `summary`
- `description`
- `command`
- `kind`
- `requires_commands`
- `supported_shells`

Required sections for the currently supported app kinds:

- `[help]` with `usage` and `examples`
- `[input]` with `mode`, `name`, and `required`
- `[output]` with `mode`
- `[prompt]` with `system`, `template`, `max_context_tokens`,
  `max_input_bytes`, and `max_output_tokens`

Supported `kind` values:

- `ai-command`
- `ai-text`

Valid `kind` and `output.mode` pairs:

- `ai-command` + `shell_command`
- `ai-text` + `text`
- `ai-text` + `structured_text`

## Optional Parts

Optional `[[args]]` blocks let you add flags and options. Supported arg types:

- `flag`
- `string`
- `integer`
- `enum`

Each `[[args]]` block uses:

- `name`
- `type`
- `long`
- `short` optional
- `description`
- `default` optional
- `choices` for `enum`

Optional hooks live under `[hooks]`:

- `build_prompt = "hooks/build_prompt.sh"`
- `pre_run = "hooks/pre_run.sh"`

Use `build_prompt` when the prompt should be assembled by a shell script rather
than a static template. Use `pre_run` for validation or setup that should stop
the app when it exits non-zero.

## Local Test Loop

1. Create your app under `apfeller-apps/apps/<id>/`.
2. Package a local catalog. This validates `app.toml`, checks hook paths, and
   builds local bundle archives:

```sh
sh scripts/package_catalog.sh --output-dir dist --bundle-base-url "file://$PWD/dist"
```

3. Point `apfeller` at that local catalog:

```sh
APFELLER_CATALOG_URL="file://$PWD/dist/apfeller-catalog.tsv" apfeller list
APFELLER_CATALOG_URL="file://$PWD/dist/apfeller-catalog.tsv" apfeller install folder-brief
```

4. Run the installed command:

```sh
folder-brief "Downloads"
```

If your app requires extra commands such as `apfel`, install those first so the
manager can run the app successfully.

## Guides

- [Install apfeller](../install/)
- [Browse the catalog](../catalog/)
- [Use apfeller](../usage/)
- [Write an app](../write-an-app/)
