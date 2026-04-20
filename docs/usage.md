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
apfeller list --installed
apfeller info <app>
```

## Install and Remove Apps

Install one or more apps from the published catalog, then remove the ones you no longer need.

```sh
apfeller install <app>
apfeller uninstall <app>
```

<div class="feature-grid">
  <section class="feature-card">
    <h3>Inspect before install</h3>
    <p><code>apfeller info &lt;app&gt;</code> gives you a quick read on the command name, requirements, and packaging details before you install.</p>
  </section>
  <section class="feature-card">
    <h3>Keep installs narrow</h3>
    <p>Only the apps you ask for land in your local store, so the manager stays useful even when the public catalog keeps growing.</p>
  </section>
</div>

## Keep Things Updated

Use explicit update commands depending on whether you want the manager, every installed app, or one app refreshed.

```sh
apfeller update --self
apfeller update --all
apfeller update <app>
```

## Check Your Setup

Run a quick health check whenever something is missing or not working as expected:

```sh
apfeller doctor
```

This reports whether `apfeller` can see the tools and shell integration it needs, including `curl`, `tar`, `shasum`, and any older state files worth cleaning up.

## A Typical Session

```sh
apfeller list
apfeller info <app>
apfeller install <app>
<app> --help
apfeller update --all
```

## Guides

- [Install apfeller](../install/)
- [Browse the catalog](../catalog/)
- [Use apfeller](../usage/)
- [Write an app](../write-an-app/)
