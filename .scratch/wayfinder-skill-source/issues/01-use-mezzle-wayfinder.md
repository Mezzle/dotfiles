# Use Mezzle's Wayfinder with human/agent readiness routing

Status: resolved
Readiness: none (resolved)
Blocked by: none

## Agent Brief

Update dotfiles' skill installation so the adapted Wayfinder from Mezzle/skills is the installed version, alongside Matt Pocock's setup and triage skills.

## Current behaviour

`.chezmoiscripts/run_onchange_after_04-install-mezzle-skills.sh.tmpl` links Mezzle skills from an editable checkout. The subsequent `05-agent-skills` hook installs Mezzle skills, then explicitly installs `wayfinder` from `mattpocock/skills`. This can replace the adapted skill and restore its prohibition on readiness labels.

The adaptation is currently in the skills working tree at `/Users/mez/dev/t3-worktrees/skills/t3-1b20d6c8/skills/engineering/wayfinder/SKILL.md`. It adds mapped `ready-for-agent` / `ready-for-human` roles, agent briefs, dependency-aware readiness, and local Markdown `Readiness:` metadata. Confirm its published availability before performing a real installation from the remote source.

## Desired behaviour

Wayfinder comes from Mezzle/skills. Keep Matt Pocock's complementary skills, including setup-matt-pocock-skills and triage. Ensure installation order and later upstream refreshes preserve this source choice across the configured agent harnesses and the editable checkout installation.

## Acceptance criteria

- [x] Remove Wayfinder from the Matt Pocock install selection; retain the other selected skills.
- [x] Ensure the Mezzle install selects its promoted Wayfinder and does not subsequently overwrite it with the upstream version.
- [x] Check the interaction between the editable-checkout hook and the global installer; preserve the intended editable links and source ownership.
- [x] Verify with an isolated installation or stubbed installer that the final Wayfinder source is Mezzle for the configured harnesses, and that rerunning the hooks preserves it.
- [x] Confirm the selected skill contains human/agent readiness routing and keeps blocked work out of the agent-ready queue.
- [x] Verify an upstream refresh does not restore Matt Pocock's Wayfinder ownership.

## Scope

Update installation configuration and relevant documentation. Do not build a task-pickup worker or change other upstream skills. Keep validation isolated from the user's live skill installation. A real rollout depends on the adapted Wayfinder being published in Mezzle/skills.

## Result

Dotfiles excludes Matt Pocock's Wayfinder while retaining all other selections.
Hooks 04 and 05 share the editable installer template; 05 restores Codex/Claude
links after global installs. Added an isolated stub-based regression check and
README refresh/rollout instructions. Validation passed for rendered templates,
shell syntax, seven harnesses, stale source migration, ordered/repeated hooks,
editable links, source-based refresh, and the supplied adaptation's readiness
rules. No live skills, remote publication or rollout were changed.

Rollout prerequisite: publish the adapted Wayfinder and plugin manifest to
Mezzle/skills, verify the remote content, and update the editable checkout.
The supplied adaptation is uncommitted; remote availability was not verified.
The network installer/update behavior is modeled by a stub, not a live CLI
integration test. Upstream refreshes must finish by rerunning hook 05 to restore
editable links, as documented.
