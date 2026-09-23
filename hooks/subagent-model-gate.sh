#!/usr/bin/env bash
# PreToolUse(Agent) — refuse a subagent launch that does not name its model.
#
# An omitted `model` inherits the session's: a lookup from an Opus session runs at
# full price, and a review from a cheap session silently runs cheap. The gate never
# picks a model; it sends the agent to vvkit:choosing-subagent-models to choose.
#
# On by default, unlike test-gate: it refuses one tool call, never a turn, and the
# fix is the same call with one more field. KIT_SUBAGENT_MODEL_GATE=0 turns it off.
#
# Not gated: a fork (it ignores `model`), a plugin agent (`plugin:name`, whose
# definition decides), and a project or user agent whose definition sets `model`.
#
# Fail-open: anything unexpected exits 0 so a bug here can never wedge a session.
set -uo pipefail

[ "${KIT_SUBAGENT_MODEL_GATE:-1}" = "0" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
payload="$(cat)"

tool="$(jq -r '.tool_name // empty' <<<"$payload" 2>/dev/null)" || exit 0
case "$tool" in
  Agent|Task) ;;
  *) exit 0 ;;
esac

model="$(jq -r '.tool_input.model // empty' <<<"$payload" 2>/dev/null)" || exit 0
[ -n "$model" ] && exit 0

agent_type="$(jq -r '.tool_input.subagent_type // "general-purpose"' <<<"$payload" 2>/dev/null)" || exit 0
case "$agent_type" in
  fork|*:*) exit 0 ;;
esac

# True when the agent definition's frontmatter sets a model.
sets_model() {
  [ -f "$1" ] || return 1
  awk '/^---[[:space:]]*$/ { n++; next } n == 1 && /^model:[[:space:]]*[^[:space:]]/ { found = 1 } END { exit !found }' "$1"
}

cwd="$(jq -r '.cwd // empty' <<<"$payload" 2>/dev/null)" || exit 0
for dir in "${cwd:+$cwd/.claude/agents}" "${HOME:+$HOME/.claude/agents}"; do
  [ -n "$dir" ] || continue
  sets_model "$dir/$agent_type.md" && exit 0
done

{
  printf 'Subagent launch refused: no `model`, so it would inherit this session'\''s.\n'
  printf 'Load vvkit:choosing-subagent-models, choose haiku, sonnet or opus for this job,\n'
  printf 'and launch again with `model` set.\n'
} >&2
exit 2
