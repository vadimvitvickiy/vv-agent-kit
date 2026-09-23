#!/usr/bin/env bash
# PostToolUse(Edit|Write) — format the edited Go file.
#
# goimports when it is installed, because it also adds and removes imports and
# gofmt's output is a subset of its own; gofmt otherwise, which ships with every
# Go toolchain. Same shape as the community format hooks for Claude Code
# (ryanlewis/claude-format-hook): check the binary, format in place, stay quiet.
#
# Silent on a file that does not parse. An agent mid-way through a multi-step
# edit leaves transient syntax errors, and the build reports real ones with more
# context than gofmt does.
#
# Fail-open: a missing binary, unreadable payload, or non-Go file exits 0.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

file="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)" || exit 0
[ -n "$file" ] || exit 0
case "$file" in
  *.go) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

if command -v goimports >/dev/null 2>&1; then
  goimports -w "$file" >/dev/null 2>&1
elif command -v gofmt >/dev/null 2>&1; then
  gofmt -w "$file" >/dev/null 2>&1
fi
exit 0
