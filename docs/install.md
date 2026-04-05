---
title: Install apfeller
permalink: /install/
---

# Install apfeller

`apfeller` installs the manager first. After that, you can browse the catalog
and install only the apps you want.

## Before You Start

- `apfeller` is for macOS.
- Fish and zsh get automatic shell integration.
- The current AI apps depend on
  [apfel](https://apfel.franzai.com/), so install that first if you plan to use
  `cmd`, `oneliner`, or `define`.

## Install the Manager

The public install path is:

```sh
curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh
```

What it does:

- Downloads the latest `apfeller.tar.gz` release asset
- Installs `apfeller` into `~/.local/bin`
- Installs manager completions
- Writes Fish or zsh shell setup for the detected shell
- If the shell cannot be detected, installs the binary anyway and prints one
  manual `PATH` command instead of guessing

## Check the Install

Verify that the manager is available:

```sh
apfeller --version
apfeller doctor
```

Then browse the catalog and install your first app:

```sh
apfeller list
apfeller install cmd
```

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

If you need to point at a different catalog, set `APFELLER_CATALOG_URL` before
running `apfeller`.
