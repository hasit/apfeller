---
title: Use apfeller
permalink: /usage/
---

# Use apfeller

Once `apfeller` is installed, you can browse the catalog, install the apps you
want, and keep them updated from the command line.

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
apfeller info cmd
```

## Install and Remove Apps

Install one or more apps:

```sh
apfeller install cmd define
```

Remove apps you no longer want:

```sh
apfeller uninstall define
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
apfeller update cmd
```

## Check Your Setup

Run a quick health check when something is missing or not working as expected:

```sh
apfeller doctor
```

This reports whether `apfeller` can see the tools and shell integration it
needs, including `curl`, `tar`, `shasum`, and any older state files worth
cleaning up.

## Included Apps

- `cmd`: turns a natural-language request into one shell command.
- `oneliner`: turns a natural-language request into a compact UNIX pipeline.
- `define`: looks up and explains a word or phrase.

Use `apfeller info <app>` to see the exact summary, requirements, and command
name for any app in the catalog.
