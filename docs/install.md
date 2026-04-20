---
layout: default
title: Install apfeller
description: Install apfeller, verify the manager, and point it at a different catalog when needed.
permalink: /install/
page_id: install
---

# Install apfeller

`apfeller` installs the manager first, then lets you browse the catalog and install only the apps you want.

<div class="command-rail" data-copy-text="curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh">
  <code>curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh</code>
</div>

## Before You Start

- `apfeller` is for macOS.
- Fish and zsh get automatic shell integration.
- Some apps require extra commands such as [apfel](https://apfel.franzai.com/). Check the requirements for each app on the [Catalog](../catalog/) page.

## First Five Minutes

Verify that the manager is available:

```sh
apfeller --version
```

Run a quick health check:

```sh
apfeller doctor
```

Browse the catalog:

```sh
apfeller list
```

Install your first app:

```sh
apfeller install <app>
```

## What the Installer Does

- Downloads the latest `apfeller.tar.gz` release asset.
- Installs `apfeller` into `~/.local/bin`.
- Installs manager completions.
- Writes Fish or zsh shell setup for the detected shell.
- If the shell cannot be detected, installs the binary anyway and prints one manual `PATH` command instead of guessing.

## Installed Locations

- `~/.local/bin/apfeller`
- `~/.config/apfeller/init.zsh`
- `~/.config/apfeller/completions/zsh/`
- `~/.config/fish/conf.d/apfeller.fish`
- `~/.config/fish/completions/`
- `~/.local/share/apfeller/store/<app>/<revision>/`
- `~/.local/share/apfeller/state.tsv`

## Advanced

By default `apfeller` reads its app catalog from:

`https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv`

If you need to point at a different catalog, set `APFELLER_CATALOG_URL` before running `apfeller`.

```sh
APFELLER_CATALOG_URL="file://$PWD/dist/apfeller-catalog.tsv" apfeller list
```

That is useful when you are testing a local catalog or a locally packaged app bundle.

## Guides

- [Install apfeller](../install/)
- [Browse the catalog](../catalog/)
- [Use apfeller](../usage/)
- [Write an app](../write-an-app/)
