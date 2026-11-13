---
name: vvkit-writing-skills
description: "Use when authoring or updating Codex skills, role instructions, or hooks for this kit."
---

# Writing skills for Codex

Read the bundled `skill-creator` skill for authoring and validation. Keep portable
workflows in user skills and project facts in AGENTS.md. Use name and description
frontmatter; keep detailed conditional guidance in references. Verify local links.

Use actual Codex tools and documented configuration. Do not copy Claude tool
allowlists, model aliases, plugin installation commands, hook payloads or context
budget claims into Codex instructions. A role skill is guidance; it does not enforce
a sandbox or register an agent type. Use Codex's native mechanisms when enforcement
is needed and verify the current schema first.

Keep source provenance and document adaptations. Test changed executable helpers
and realistic behavior where appropriate. Preserve user authorization and existing
invocation preferences. Avoid extra approval gates for work already requested.
