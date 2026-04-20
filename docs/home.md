---
layout: default
title: apfeller
description: apfeller is a small app manager for local shell apps built around apfel.
permalink: /
page_id: home
---

# apfeller

`apfeller` is a small app manager for local shell apps built around [apfel](https://apfel.franzai.com/). The apps run fully local on your Mac with zero API cost: no API bill, no API keys, and no cloud round-trip.

<div class="command-rail" data-copy-text="curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh">
  <code>curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh</code>
</div>

Install the manager once, browse the published [Catalog](catalog/), and install only the apps you want.

## Quick Start

Install the manager:

```sh
curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh
```

List the published catalog:

```sh
apfeller list
```

Install one app from the [Catalog](catalog/) page:

```sh
apfeller install <app>
```

Use `apfeller info <app>` when you want to inspect one app before you install it, and use `apfeller doctor` when you want to verify that your local setup is healthy.

## Why It Stays Small

- The manager is small and the catalog is live.
- Apps run fully local on your Mac.
- You install only the apps you want instead of one large bundle.
- Published app definitions live in [`hasit/apfeller-apps`](https://github.com/hasit/apfeller-apps), so the docs site can stay simple.

## Browse and Install

Use the [Catalog](catalog/) page to browse published apps, see required commands, and copy install or example commands. If you want the published source data, you can also open the raw catalog directly:

`https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv`

## Write Your Own

If you want to package your own app, start with the [authoring guide](write-an-app/). App source definitions live in the separate [`apfeller-apps`](https://github.com/hasit/apfeller-apps) repo.

## Guides

- [Install apfeller](install/)
- [Browse the catalog](catalog/)
- [Use apfeller](usage/)
- [Write an app](write-an-app/)
