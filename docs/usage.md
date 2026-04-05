---
title: Use apfeller
permalink: /usage/
---

# Use apfeller

Once `apfeller` is installed, you can browse the catalog, install the apps you
want, remove them, and keep everything updated from the command line.

## Choose an App

Use the [Catalog](../catalog/) page to find the app id you want to install, see
what command it provides, and check any required tools.

## Browse Apps

List everything currently available in the catalog:

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

Install one or more apps:

```sh
apfeller install <app>
```

Remove apps you no longer want:

```sh
apfeller uninstall <app>
```

## Keep Things Updated

Update the manager itself:

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

Run a quick health check when something is missing or not working as expected:

```sh
apfeller doctor
```

This reports whether `apfeller` can see the tools and shell integration it
needs, including `curl`, `tar`, `shasum`, and any older state files worth
cleaning up.

## Guides

- [Install](../install/)
- [Catalog](../catalog/)
- [Use apfeller](../usage/)
- [Write an app](../write-an-app/)
