---
title: apfeller
permalink: /
---

# apfeller

`apfeller` is a small app manager for shell-based AI tools built on
[apfel](https://apfel.franzai.com/)
([source repo](https://github.com/Arthur-Ficial/apfel)).
The apps run fully local on your Mac with zero API cost: no API bill, no API
keys, and no cloud round-trip.

It installs a lightweight manager first, then lets users opt into focused apps.
The current app set is intentionally designed for short prompts and instant
single-turn results.

## Quick Start

```sh
curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh
apfeller list
apfeller install cmd
cmd "show the ten largest files in Downloads"
```

For the current AI apps, install
[apfel](https://apfel.franzai.com/) first if it is not already on your Mac.

## AI Apps

- `cmd`: natural language to a single shell command via `apfel`
- `oneliner`: natural language to a compact UNIX pipeline via `apfel`
- `define`: tiny multilingual dictionary lookup via `apfel`

## Guides

- [Install](install)
- [Use apfeller](usage)
