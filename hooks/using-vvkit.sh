#!/usr/bin/env bash
# SessionStart — tell the model when to load which vvkit skill.
# Registered in the plugin manifest so it is active wherever the plugin is installed.
#
# Fail-open: emits nothing rather than failing the session.
set -uo pipefail

guide="$(dirname "$0")/using-vvkit.md"
[ -r "$guide" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

jq -n --rawfile ctx "$guide" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
