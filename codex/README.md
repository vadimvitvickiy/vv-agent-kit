# Codex plugins

Install from the same Git repository as the Claude plugins:

```sh
codex plugin marketplace add vadimvitvickiy/vv-agent-kit
codex plugin add vvkit@vv-agent-kit-codex
codex plugin list --marketplace vv-agent-kit-codex --json
```

Start a new Codex session after installation. Codex manages its plugin cache and
enabled state. The core plugin contains 30 skills: 19 disciplines, eight command
workflows and three role instructions. Existing manually copied `vvkit-*` skills
should be archived after confirming plugin installation, to avoid duplicate entries.
Hunk and research are separate user skills, not part of this kit.

## Swift projects

The separate `vvkit-swift` plugin contains six skills, a reviewer role and project
templates. It requires core vvkit. Install it normally:

```sh
codex plugin add vvkit-swift@vv-agent-kit-codex
```

To keep Swift project-scoped, set the plugin's user-level enabled value to false in
`~/.codex/config.toml`:

```toml
[plugins."vvkit-swift@vv-agent-kit-codex"]
enabled = false
```

Enable it in each Swift project's trusted `.codex/config.toml`:

```toml
[plugins."vvkit-swift@vv-agent-kit-codex"]
enabled = true
```

Merge these entries with existing tables rather than duplicating tables. Existing
project build variables, such as KIT_TEST_SCHEME, belong in project configuration.

## Development and updates

Shared skills, commands and role instructions remain in the original source trees.
`scripts/build-codex.py` translates names and runtime assumptions. Small
platform-specific rewrites live in `codex/overrides/` and `codex/references/`.
`codex/plugins/` is generated and committed so Git marketplace installation works
without running build scripts on the user's machine. Do not edit generated files.

After changing source or overrides:

```sh
python3 scripts/build-codex.py
python3 scripts/build-codex.py --check
./scripts/validate.sh
```

The compatibility manifests inherit each source plugin's version. Bump that source
version when its shipped content changes, regenerate, and commit the generated
packages. CI checks that generated content matches source. To refresh an installed
Git marketplace after a release:

```sh
codex plugin marketplace upgrade vv-agent-kit-codex
codex plugin add vvkit@vv-agent-kit-codex
```

For local authoring, register this checkout instead of the Git source:

```sh
codex plugin marketplace add /absolute/path/to/vv-agent-kit
```

## Runtime adaptations

- Claude command workflows become named skills. Explicit-only commands preserve
  that setting in `agents/openai.yaml`. The disabled worktree command is excluded;
  ordinary Git worktree operations remain available when requested.
- Role instructions are skills usable inline or passed to a generic subagent. They
  do not register custom agent types or enforce tool restrictions.
- Models, history forks, delegation and permission decisions follow the active
  Codex session. No Anthropic model aliases or environment settings are installed.
- Existing user authorization takes precedence over imported workflow approval
  gates. Platform-specific authoring and onboarding workflows have native rewrites.
- Claude hooks are not registered. Startup routing, Stop test enforcement,
  subagent model enforcement and Swift's edit-time lint require separate tested
  Codex hooks. Packaging as a plugin does not imply those hooks were ported.
- Figma, Supabase, Warp, LSP services, credentials and conversation histories are
  not bundled.

See the [Codex plugin packaging guide](https://developers.openai.com/plugins/build/plugins)
for marketplace and manifest formats.
