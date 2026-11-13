---
name: vvkit-scripts
description: "Use when explicitly asked to scaffold build, test, lint, or code-map scripts for a project."
---

# Project scripts

Inspect the build system, CI and existing scripts first. Preserve existing interfaces.
Create only the requested wrappers, using commands verified for this repository.
For Swift use the project-scoped $vvkit-swift-xcode-builds skill and its installed
helper resources where available. Do not invent schemes or simulator identifiers.

Tests must propagate failures and detect a zero-test run. Use appropriate result
summaries rather than dumping full logs. Keep machine-specific cache paths out of
committed files. Do not clean caches routinely. Verify generated scripts by running
the appropriate safe commands, then record the interface in AGENTS.md. Do not add
Git hooks or install tools unless that is part of the authorized request.
