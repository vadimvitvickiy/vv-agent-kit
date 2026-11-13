---
name: vvkit-choosing-subagent-models
description: "Use when choosing a model or context strategy for an authorized subagent."
---

# Choosing subagent models

Use models exposed by the active Codex session. Claude model aliases and environment
variables do not apply. Honor a user-specified model and session restrictions first.
Inherit the parent model unless an explicit user or applicable instruction authorizes
an override. A full-history fork inherits its model; an authorized override requires
a fresh-context agent when the tool contract says so.

For gathering, keep the brief narrow and return evidence with paths or sources.
For judgment, preserve the context needed to assess correctness. Avoid inventing a
fixed equivalence between Claude tiers and OpenAI models. When a task fails repeatedly,
change its scope or supply missing context before dispatching it again. Two failed
rounds end identical re-dispatching; take the task back or narrow it.
