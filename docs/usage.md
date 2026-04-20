---
layout: default
title: Use apfeller
description: Browse apps, install or remove them, keep them updated, and diagnose your local setup.
permalink: /usage/
page_id: usage
---

# Use apfeller

Once `apfeller` is installed, you can browse the catalog, inspect one app at a time, install what you want, and keep everything updated from the command line.

## Browse Apps

Use the [Catalog](../catalog/) page when you want the published app list in the browser, then use the manager when you want to inspect or act from the terminal.

```sh
apfeller list
```

Show only the apps you already installed:

```sh
apfeller list --installed
```

See details for one app before you install it:

```sh
apfeller info <app>
```

## Install and Remove Apps

Install one or more apps from the published catalog, then remove the ones you no longer need.

```sh
apfeller install <app>
```

Remove apps you no longer want:

```sh
apfeller uninstall <app>
```

Use `apfeller info <app>` if you want to inspect the command name, requirements, and packaging details before you install.

## Keep Things Updated

Use explicit update commands depending on whether you want the manager, every installed app, or one app refreshed.

```sh
apfeller update --self
```

Update every installed app:

```sh
apfeller update --all
```

Update just one app:

```sh
apfeller update <app>
```

## Check Your Setup

Run a quick health check whenever something is missing or not working as expected:

```sh
apfeller doctor
```

This reports whether `apfeller` can see the tools and shell integration it needs, including `curl`, `tar`, `shasum`, and any older state files worth cleaning up.

## Guides

- [Install apfeller](../install/)
- [Browse the catalog](../catalog/)
- [Use apfeller](../usage/)
- [Write an app](../write-an-app/)
