#!/usr/bin/env bash
# SessionStart — inject the repo state that changes between sessions. Static
# facts belong in CLAUDE.md; this covers only what a script has to compute.
#
# Optional: KIT_TICKET_PATTERN, an extended regex matching a ticket id in the
# branch name (e.g. '[A-Z]+-[0-9]+'). Unset means no ticket extraction.
#
# Fail-open: emits nothing rather than failing the session.
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
status="$(git status --porcelain 2>/dev/null | head -25)"
changed_count="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

context="Branch: ${branch:-unknown}"

if [ -n "${KIT_TICKET_PATTERN:-}" ]; then
  ticket="$(printf '%s' "$branch" | grep -oiE "$KIT_TICKET_PATTERN" | head -1 | tr '[:lower:]' '[:upper:]')"
  [ -n "$ticket" ] && context="$context (ticket $ticket)"
fi

context="$context
Working tree: ${changed_count:-0} changed path(s)"

if [ -n "$status" ]; then
  context="$context
$status"
  [ "${changed_count:-0}" -gt 25 ] && context="$context
  … truncated at 25"
fi

jq -n --arg ctx "$context" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
