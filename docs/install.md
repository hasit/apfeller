# Install

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

Supported shells in v1:

- Fish
- zsh
