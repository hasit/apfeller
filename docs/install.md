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

<p class="small-note">This public install path downloads the latest manager release asset and wires in completions plus shell setup where it can do so safely.</p>

## Before You Start

- `apfeller` is for macOS.
- Fish and zsh get automatic shell integration.
- Some apps require extra commands such as [apfel](https://apfel.franzai.com/). Check the requirements for each app on the [Catalog](../catalog/) page.

## First Five Minutes

Use this flow to verify the manager and install your first app:

```sh
curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh
apfeller --version
apfeller doctor
apfeller list
apfeller install <app>
```

## What the Installer Does

<div class="feature-grid">
  <section class="feature-card">
    <h3>Install the manager</h3>
    <p>Downloads the latest <code>apfeller.tar.gz</code> release asset and installs <code>apfeller</code> into <code>~/.local/bin</code>.</p>
  </section>
  <section class="feature-card">
    <h3>Set up completions</h3>
    <p>Installs manager completions for the supported shells so the base command is ready immediately after install.</p>
  </section>
  <section class="feature-card">
    <h3>Configure your shell carefully</h3>
    <p>Writes Fish or zsh shell setup when the shell can be detected, and falls back to one manual <code>PATH</code> command when it cannot.</p>
  </section>
  <section class="feature-card">
    <h3>Stay manager-focused</h3>
    <p>The installer only sets up the manager itself. Individual apps remain opt-in and are installed later from the published catalog.</p>
  </section>
</div>

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

## Guides

- [Install apfeller](../install/)
- [Browse the catalog](../catalog/)
- [Use apfeller](../usage/)
- [Write an app](../write-an-app/)
