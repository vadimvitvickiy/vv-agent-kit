# Changelog

All notable changes to this plugin are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[semantic versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-08-25

First public release.

### Added

- `debugging-systematically` — root-cause discipline: reproduce before theorizing, trace to the layer
  that should have rejected the value, and the band-aid table with what each one costs later.
- `reviewing-code` — the neutral review discipline: diff-not-repo scope, severity by consequence,
  `file:line` citation, and why a padded review is paid for on the next review.
- `writing-skills` — the authoring contract, with `references/frontmatter.md` for the field and rule
  tables. Explains the skill-listing budget: on overflow, descriptions are dropped starting with the
  least-invoked skills, so a marginal skill can stop a useful one from triggering.
- History-as-evidence in `exploring-a-codebase` — `log -S`, `log -L`, and the traps in `blame`
  and `bisect`.
- `LICENSE` (MIT), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue and pull request templates.
- CI: every push runs the structural gate, asserts the gate still rejects the fixtures, shellchecks
  every shipped script, and proves each hook exits 0 on garbage and on empty stdin.
- Validator rules: install commands must be literal, every `SKILL.md` needs an H1, reference files
  must be linked by plain path rather than force-loaded with `@`. Cross-reference checking now covers
  `templates/` and `packs/`.

### Changed

- **Renamed.** The plugin is `vvkit` and the marketplace is `vv-agent-kit`. Every invocation is now
  `/vvkit:…` and every cross-reference `vvkit:…`.
- `agents/swift-reviewer.md` and `commands/review.md` no longer restate the review rules; both
  declare `vvkit:reviewing-code` as required background. The agent drops from 71 to 43 lines.
- `swift-style` defers to a project's established convention where one exists, rather than asserting
  one member order as universal.
- Plugin and marketplace manifests carry `displayName`, `license`, `homepage`, `repository`,
  `category` and `keywords`; `claude plugin validate . --strict` now passes.

### Fixed

- The README shipped `claude plugin marketplace add <owner>/…` — the first command any reader copies
  was the one nothing validated. A validator rule now covers it.
- `CLAUDE.md` claimed the test gate activates only on `KIT_TEST_COMMAND`; an executable
  `scripts/test.sh` also activates it.

### Removed

- The internal design spec, and its contents from git history — it named private repositories.

## [0.1.0]

Initial private version: 12 skills, the Swift pack, four commands, three hooks, and the structural
validator.
