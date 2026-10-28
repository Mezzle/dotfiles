# dotfiles

My dotfiles repository, managed with [chezmoi](https://chezmoi.io/).

## Optional settings

`tldrawOffline` in chezmoi's local `data` controls the tldraw agent definitions
and Claude's context hook. It defaults to whether `tldraw offline.app` exists
in `/Applications` or `~/Applications` when generating the local config.
Enable it only after installing the app and its companion skill/helper files.
The app owns those helpers; this repo does not install the app.

Neovim uses the [NvChad starter](https://github.com/NvChad/starter) configuration,
tracked here without its Git
checkout. Lazy installs NvChad and its plugins on first launch. Use Space-ch
for the mapping cheatsheet and `:Lazy` for plugin management.

## 1Password

1Password and its CLI are installed through the Brewfile. Enable desktop app
integration for the CLI. To generate a private `~/.npmrc`, add your real secret
references to the local chezmoi config's `data` mapping:

```yaml
npmGithubTokenRef: op://YOUR-VAULT/YOUR-GITHUB-ITEM/YOUR-TOKEN-FIELD
npmjsTokenRef: op://YOUR-VAULT/YOUR-NPM-ITEM/YOUR-TOKEN-FIELD
```

Either reference is optional. With neither set, chezmoi leaves `.npmrc` alone.
Tokens are retrieved with `onepasswordRead` during apply; the generated file is
private but contains plaintext tokens, as npm expects. Source control contains
only references. Avoid sharing rendered diffs for secret-bearing files.

Use individual secret references for other CLI configuration when needed.
Raycast's session tokens and agent OAuth state remain owned by their apps.

## Agent configuration

Personal Claude instructions, documentation rules, status line, and preferences
are tracked. Deja hooks and commands are deliberately excluded. Project-derived
Claude auto-mode environment assumptions are excluded from global settings.
Skills are installed by the manifest in `.chezmoiscripts`; external writing uses
`unslop`.
