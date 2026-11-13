#!/usr/bin/env python3
"""Build Codex plugins from the shared kit sources and small platform overrides."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import tempfile

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'codex/plugins'
OVERRIDES = ROOT / 'codex/overrides'

ADAPTATION = '''## Codex runtime

Load referenced skills by reading their SKILL.md. Surveyor, reviewer and runner
skills are role instructions, not registered agent types or enforced tool allowlists.
Use a generic subagent only when delegation is available and permitted; otherwise
perform the role inline. Follow the active session's model, context and permission
rules. User authorization takes precedence over imported workflow approval gates.
Claude hooks and plugin commands are not active in this package. Existing
`.claude/context/` paths refer to project documents, not Codex configuration.

'''


def translate(text):
    text = re.sub(r'/?vvkit-swift:([a-z-]+)', r'$vvkit-swift-\1', text)
    text = re.sub(r'/?vvkit:([a-z-]+)', r'$vvkit-\1', text)
    text = text.replace('`$vvkit-worktree`', 'the ordinary git worktree workflow')
    text = text.replace('CLAUDE.md is read on every turn of every session', 'AGENTS.md is loaded as project guidance')
    text = text.replace('CLAUDE.md', 'AGENTS.md')
    text = text.replace('a AGENTS.md or AGENTS.md', 'an AGENTS.md or legacy CLAUDE.md')
    text = text.replace('`tools` is set explicitly above:', 'Role guidance:')
    text = text.replace('A subagent gets no conversation history. Anything it needs is in the prompt.',
                        'Use the available history mode; fresh-context agents need all required context in their prompt.')
    text = text.replace('Subagents cannot spawn subagents; chain from the main conversation',
                        'Check session support and authorization before nesting agents')
    text = text.replace('**Arguments:** `$ARGUMENTS`', '**Arguments:** use the arguments in the user request.')
    return text


def emit(source, plugin, name):
    target = plugin / 'skills' / name
    override = OVERRIDES / name
    origin = override if override.exists() else source
    if origin.is_dir():
        shutil.copytree(origin, target, ignore=shutil.ignore_patterns(".DS_Store", "__pycache__"))
    else:
        target.mkdir(parents=True)
        shutil.copy2(origin, target / 'SKILL.md')
    entry = target / 'SKILL.md'
    original = entry.read_text()
    _, front, body = original.split('---', 2)
    description = re.search(r'^description:\s*(.*)$', front, re.M).group(1)
    if description.startswith('"'):
        description = json.loads(description)
    if not description.startswith('Use when'):
        descriptions = {
            'vvkit-architecture-surveyor': 'Use when surveying the architecture around a planned change.',
            'vvkit-commit-reviewer': 'Use when reviewing existing commits or a commit range.',
            'vvkit-test-runner': 'Use when a known test, build or lint command needs to run and report its exact result.',
            'vvkit-swift-swift-reviewer': 'Use when reviewing changed Swift code.',
            'vvkit-explore': 'Use when refreshing a generated code map or checking architecture constraints.',
            'vvkit-merge': 'Use when explicitly asked to merge a finished branch and clean up its worktree.',
            'vvkit-open-pr': 'Use when explicitly asked to prepare and open a pull request.',
            'vvkit-rebase': 'Use when explicitly asked to rebase the current branch.',
            'vvkit-review': 'Use when reviewing the local diff or a branch against the kit standards.',
        }
        description = descriptions[name]
    body = translate(body.lstrip())
    # Keep the title and principal rule first; runtime differences follow them.
    split = body.find('\n\n', body.find('\n') + 1)
    if split == -1:
        split = len(body)
    if not override.exists():
        body = body[:split] + '\n\n' + ADAPTATION + body[split:].lstrip()
    entry.write_text('---\nname: ' + name + '\ndescription: ' + json.dumps(translate(description)) + '\n---\n\n' + body)
    for file in target.rglob('*.md'):
        if file != entry:
            file.write_text(translate(file.read_text()))
    if 'disable-model-invocation: true' in front:
        metadata = target / 'agents/openai.yaml'
        metadata.parent.mkdir(exist_ok=True)
        metadata.write_text('policy:\n  allow_implicit_invocation: false\n')


def build_plugin(source, name):
    plugin = OUTPUT / name
    plugin.mkdir(parents=True)
    manifest = json.loads((source / '.claude-plugin/plugin.json').read_text())
    manifest.pop('$schema', None)
    manifest.pop('displayName', None)
    manifest['skills'] = './skills/'
    manifest['interface'] = {'displayName': 'Agent Kit' if name == 'vvkit' else 'Agent Kit · Swift',
                             'shortDescription': 'Portable development workflows' if name == 'vvkit' else 'Swift and Xcode workflows'}
    path = plugin / '.codex-plugin/plugin.json'
    path.parent.mkdir()
    path.write_text(json.dumps(manifest, indent=2) + '\n')
    shutil.copy2(ROOT / 'LICENSE', plugin / 'LICENSE')
    for skill in sorted((source / 'skills').iterdir()):
        if (skill / 'SKILL.md').exists():
            emit(skill, plugin, name + '-' + skill.name)
    for role in sorted((source / 'agents').glob('*.md')):
        emit(role, plugin, name + '-' + role.stem)
    if name == 'vvkit':
        for command in sorted((source / 'commands').glob('*.md')):
            if command.stem != 'worktree':
                emit(command, plugin, name + '-' + command.stem)
        target = plugin / 'skills/vvkit-delegating-work/references/subagent-reference.md'
        shutil.copy2(ROOT / 'codex/references/subagent-reference.md', target)
    else:
        target = plugin / 'skills/vvkit-swift-xcode-builds'
        shutil.copytree(source / 'templates', target / 'assets/templates', ignore=shutil.ignore_patterns('.DS_Store', '__pycache__'))
        shutil.copy2(ROOT / 'codex/references/xcodebuildmcp.md', target / 'references/xcodebuildmcp.md')
        entry = target / 'SKILL.md'
        entry.write_text(entry.read_text() + '\nProject templates are in `assets/templates/`; adapt them to verified repository values.\n')
    return plugin


def build():
    if OUTPUT.exists():
        shutil.rmtree(OUTPUT)
    plugins = [build_plugin(ROOT, 'vvkit'), build_plugin(ROOT / 'plugins/swift', 'vvkit-swift')]
    known = {p.parent.name for p in OUTPUT.rglob('SKILL.md')}
    for path in OUTPUT.rglob('*.md'):
        for reference in re.findall(r'\$(vvkit-[a-z-]+)', path.read_text()):
            if reference not in known:
                raise ValueError(str(path) + ': unknown skill ' + reference)
    print('Built ' + str(len(plugins)) + ' Codex plugins with ' + str(len(known)) + ' skills.')


def fingerprints(root):
    return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in root.rglob('*') if p.is_file()}


def main():
    global OUTPUT
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Check committed packages without changing them')
    args = parser.parse_args()
    if not args.check:
        build()
        return
    committed = OUTPUT
    with tempfile.TemporaryDirectory(prefix='vvkit-build-') as temp:
        OUTPUT = Path(temp) / 'plugins'
        build()
        if fingerprints(OUTPUT) != fingerprints(committed):
            raise SystemExit('Codex packages are stale; run python3 scripts/build-codex.py')
    print('Committed Codex packages match their sources.')


if __name__ == '__main__':
    main()
