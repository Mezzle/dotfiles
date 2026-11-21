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

## Update check

Interactive shells check once a day, in the background, whether this repo has
new commits. If it has, the next new shell prints one line suggesting
`chezmoi update`, and starship shows 󰚰 in the prompt until an apply brings
those commits in. The check uses anonymous HTTPS, so it never prompts for SSH
keys. When it fails it prints nothing and waits a day before trying again. To
check sooner, delete `~/.cache/dotfiles-update/checked`.

The same check can count outdated Homebrew packages and mise tools, adding a
line for each to that notice. It never upgrades anything. Switch them in the
local chezmoi config's `data` mapping:

```yaml
brewUpdateCheck: false # default: on for macOS, off on work machines
miseUpdateCheck: true  # default: on for development machines
```

The brew check runs `brew update`, the same refresh brew does before its own
commands, so leave it off where Homebrew needs admin rights. Machines set up
before these keys existed have both checks off until `chezmoi init` writes the
defaults.

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

For the Environments MCP server, turn on Settings > Developer > Integrate with
MCP clients in the 1Password app, then run `chezmoi apply`. On development
machines this registers `1password-mcp` with Claude Code, Codex, OpenCode and pi.

## Agent configuration

Personal Claude instructions, documentation rules, status line, and preferences
are tracked. Deja hooks and commands are deliberately excluded. Project-derived
Claude auto-mode environment assumptions are excluded from global settings.
`cleanupPeriodDays` is 3650 so Claude Code keeps transcripts until the session
archive (`Mezzle/hansard`) collects them; the default sweep deletes them after 30 days.
Skills are installed by the manifest in `.chezmoiscripts`; external writing uses
`unslop`.

### Skill sources and updates

Mezzle/skills owns Wayfinder and file-pr. Matt Pocock's selected complementary
skills include setup-matt-pocock-skills and triage; Wayfinder is excluded from
that selection so its update record stays with Mezzle. Hook 04 links promoted
Mezzle skills and the security-review draft from `MEZZLE_SKILLS_SOURCE` (default
`~/dev/skills`) into Codex and Claude. Hook 05 installs the global manifest for
all seven configured harnesses, then restores those editable links using the
same template. Other harnesses retain the global Mezzle version.

Before rollout, publish the adapted Wayfinder and its plugin manifest entry to
Mezzle/skills, and update the editable checkout to that revision. The supplied
adaptation is uncommitted in a local working tree; remote availability has not
been verified. Configuring the remote source does not publish it. Verify its
readiness roles, agent briefs and dependency rules in both the published revision
and editable checkout before applying.

For upstream refreshes, run `npx skills update -g -y`, then rerun hook 05 (for
example with chezmoi's `--force` option on that script). Updates follow the
global installer lock record; the next manifest install migrates an older
Matt-owned Wayfinder record to Mezzle. Refreshes can replace Codex/Claude links,
so restoring the editable links is part of the refresh procedure. Do not
re-add Matt's Wayfinder independently. Validate configuration without touching
live skills with `python3 tests/skill-installation.py --skills-source PATH`.
