#!/usr/bin/env python3
"""Exercise rendered hooks with a fake network installer and a temporary HOME."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
AGENTS = ['claude-code', 'codex', 'opencode', 'cursor', 'droid', 'gemini-cli', 'pi']
PATHS = ['.claude/skills', '.codex/skills', '.config/opencode/skills', '.cursor/skills',
         '.factory/skills', '.gemini/skills', '.pi/agent/skills']

# Models canonical copies, per-agent links, and source-based update records. This
# deliberately does not invoke npm or claim to integration-test skills.sh itself.
STUB = r'''#!/usr/bin/env python3
import json, os, pathlib, shutil, sys
home = pathlib.Path(os.environ['HOME'])
args = sys.argv[1:]
assert args[:3] == ['-y', 'skills@latest', 'add'], args
assert args[4:6] == ['-g', '-y'], args
agents = args[args.index('-a') + 1:args.index('-s')]
assert agents == json.loads(os.environ['TEST_AGENTS'])
source = args[3]
selected = args[args.index('-s') + 1:]
state_file = home / 'sources.json'
state = json.loads(state_file.read_text()) if state_file.exists() else {}
with (home / 'calls.jsonl').open('a') as log:
    log.write(json.dumps([source, selected]) + '\n')
if selected == ['*']:
    assert source == 'Mezzle/skills'
    manifest = json.loads((pathlib.Path(os.environ['MEZZLE_SKILLS_SOURCE']) / '.claude-plugin/plugin.json').read_text())
    selected = [pathlib.Path(p).name for p in manifest['skills']]
for name in selected:
    canonical = home / '.agents/skills' / name
    canonical.mkdir(parents=True, exist_ok=True)
    (canonical / 'SKILL.md').write_text(source)
    state[name] = source
    for directory in json.loads(os.environ['TEST_PATHS']):
        target = home / directory / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.is_symlink():
            target.unlink()
        elif target.exists():
            shutil.rmtree(target)
        target.symlink_to(canonical)
state_file.write_text(json.dumps(state))
'''


def run(*args, **kwargs):
    return subprocess.run(args, check=True, text=True, capture_output=True, **kwargs).stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--skills-source', required=True, type=Path)
    args = parser.parse_args()
    source = args.skills_source.resolve()
    manifest = json.loads((source / '.claude-plugin/plugin.json').read_text())
    wayfinder = 'skills/engineering/wayfinder'
    assert any(Path(p).as_posix().removeprefix('./') == wayfinder for p in manifest['skills'])
    text = (source / wayfinder / 'SKILL.md').read_text()
    for phrase in ['ready-for-agent', 'ready-for-human', 'agent brief',
                   'blocked ticket', 'neither ready role', 'unblocked, and unclaimed']:
        assert phrase in text, phrase
    with tempfile.TemporaryDirectory(prefix='dotfiles-skills-') as tmp:
        base = Path(tmp).resolve()
        home = base / 'home'
        home.mkdir()
        editable = base / 'editable'
        # Copy only installer inputs; no writes to the supplied source checkout.
        for relative in ['scripts/install_skills.py', '.claude-plugin/plugin.json']:
            target = editable / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source / relative, target)
        for relative in [*manifest['skills'], 'skills/in-progress/security-review']:
            shutil.copytree(source / relative, editable / relative)
        bin_dir = base / 'bin'
        bin_dir.mkdir()
        (bin_dir / 'npx').write_text(STUB)
        (bin_dir / 'npx').chmod(0o755)
        # Fail if a hook unexpectedly attempts a clone/network fetch.
        (bin_dir / 'git').write_text('#!/bin/sh\nexit 99\n')
        (bin_dir / 'git').chmod(0o755)
        config = base / 'chezmoi.toml'
        config.write_text('[data]\ndevMachine = true\n')
        env = {**os.environ, 'HOME': str(home), 'MEZZLE_SKILLS_SOURCE': str(editable),
               'PATH': str(bin_dir) + os.pathsep + os.environ['PATH'],
               'TEST_AGENTS': json.dumps(AGENTS), 'TEST_PATHS': json.dumps(PATHS)}
        hooks = []
        for number in ['04', '05']:
            template = next((ROOT / '.chezmoiscripts').glob(f'*_{number}-*.tmpl'))
            rendered = run('chezmoi', '--source', str(ROOT), '--config', str(config),
                           'execute-template', input=template.read_text(), env=env)
            script = base / f'{number}.sh'
            script.write_text(rendered)
            run('bash', '-n', str(script))
            hooks.append(script)
            disabled = run('chezmoi', '--source', str(ROOT), '--config', str(config),
                           '--override-data', '{"devMachine":false}', 'execute-template',
                           input=template.read_text(), env=env)
            assert not disabled.strip()

        def check():
            state = json.loads((home / 'sources.json').read_text())
            assert state['wayfinder'] == 'Mezzle/skills'
            assert state['triage'] == state['setup-matt-pocock-skills'] == 'mattpocock/skills'
            for directory in PATHS:
                target = home / directory / 'wayfinder'
                if directory in PATHS[:2]:
                    assert target.resolve() == editable / wayfinder, (target, target.resolve(), editable / wayfinder)
                else:
                    assert target.resolve() == home / '.agents/skills/wayfinder'
                    assert (target / 'SKILL.md').read_text() == 'Mezzle/skills'
            calls = [json.loads(line) for line in (home / 'calls.jsonl').read_text().splitlines()]
            for remote, selection in calls:
                if remote == 'mattpocock/skills':
                    assert 'wayfinder' not in selection
                    assert 'triage' in selection and 'setup-matt-pocock-skills' in selection

        # Start with stale upstream ownership, then exercise initial order and reruns.
        (home / 'sources.json').write_text(json.dumps({'wayfinder': 'mattpocock/skills'}))
        for hook in [*hooks, *hooks, hooks[1], hooks[0]]:
            run('bash', str(hook), env=env)
            if (home / 'calls.jsonl').exists():
                check()
        # Simulated update reinstalls from recorded sources, as the CLI does.
        state = json.loads((home / 'sources.json').read_text())
        for remote in sorted(set(state.values())):
            names = [name for name, owner in state.items() if owner == remote]
            run('npx', '-y', 'skills@latest', 'add', remote, '-g', '-y', '-a', *AGENTS,
                '-s', *names, env=env)
        assert json.loads((home / 'sources.json').read_text())['wayfinder'] == 'Mezzle/skills'
        # Refresh can replace editable links; the documented final hook restores them.
        run('bash', str(hooks[1]), env=env)
        check()
    print('PASS: rendering, syntax, readiness, stale-owner migration, seven harnesses, '
          'hook ordering/reruns, editable links, and simulated source-based refresh')


if __name__ == '__main__':
    main()
