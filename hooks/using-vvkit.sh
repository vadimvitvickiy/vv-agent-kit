#!/usr/bin/env bash
# SessionStart — tell the model when to load which vvkit skill. The skill listing
# carries only one-line descriptions, and measured against it alone, debugging,
# design and review requests loaded their skill in 1 of 9 runs. Registered in the
# plugin's manifest, so it is active wherever the plugin is installed.
#
# Fail-open: emits nothing rather than failing the session.
set -uo pipefail

guide="$(dirname "$0")/using-vvkit.md"
[ -r "$guide" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

jq -n --rawfile ctx "$guide" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
