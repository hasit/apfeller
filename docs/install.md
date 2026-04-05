# Install

`apfeller` packages small shell apps built on
[apfel](https://apfel.franzai.com/). The AI apps run fully local on your Mac
with zero API cost: no API bill, no API keys, and no cloud round-trip. They are
intentionally designed for small inputs, small outputs, and instant single-turn
results inside apfel's fixed 4,096-token combined window. `port` is the one
simple non-AI local utility.

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

Installed paths:

- `~/.local/bin/apfeller`
- `~/.config/apfeller/init.zsh`
- `~/.config/apfeller/completions/zsh/`
- `~/.config/fish/conf.d/apfeller.fish`
- `~/.config/fish/completions/`

App payload paths:

- `~/.local/share/apfeller/store/<app>/<version>/`
- `~/.local/share/apfeller/state.tsv`

Installed app bundles contain compiled framework metadata. `apfeller` generates
the command wrapper and fish/zsh completions during install, so app archives do
not need to ship handwritten entrypoint scripts.

Supported shells in v1:

- Fish
- zsh
