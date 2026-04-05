---
title: apfeller
permalink: /
---

# apfeller

`apfeller` is a framework + manager for small AI-powered shell apps built on
[apfel](https://apfel.franzai.com/)
([source repo](https://github.com/Arthur-Ficial/apfel)).
The AI apps run fully local on your Mac with zero API cost: no API bill, no API
keys, and no cloud round-trip.

It installs a lightweight manager first, then lets users opt into focused apps.
The AI apps are intentionally designed for small inputs, small outputs, and
instant single-turn results so they fit apfel's fixed 4,096-token combined
context window.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh
```

Then install the apps you want:

```sh
apfeller list
apfeller install cmd oneliner
```

By default the manager reads its published app catalog from
`hasit/apfeller-apps`.

## AI Apps

- `cmd`: natural language to a single shell command via `apfel`
- `oneliner`: natural language to a compact UNIX pipeline via `apfel`
- `define`: tiny multilingual dictionary lookup via `apfel`

## Docs

- [Install](install)
- [Authoring](authoring)
- [Releasing](releasing)
