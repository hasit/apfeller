---
title: apfeller
permalink: /
---

# apfeller

`apfeller` is a small app manager for local shell apps built around
[apfel](https://apfel.franzai.com/).
The apps run fully local on your Mac with zero API cost: no API bill, no API
keys, and no cloud round-trip.

Install the manager once, browse the published catalog, and install only the
apps you want.

Many current apps use `apfel`. Each app's requirements are listed on the
[Catalog](catalog/) page.

## Quick Start

```sh
curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh
apfeller list
apfeller install <app>
```

Use the [Catalog](catalog/) page to choose an app id before you install it.

## Guides

- [Install apfeller](install/)
- [Browse the catalog](catalog/)
- [Use apfeller](usage/)
- [Write an app](write-an-app/)
