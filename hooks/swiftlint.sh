#!/usr/bin/env bash
# PostToolUse(Edit|Write) — autocorrect the edited Swift file, then surface what
# SwiftLint could not fix.
#
# Exit 2 is the only exit code fed back to the model, so error-severity findings
# use it. Warnings stay silent: they are noise on every edit and would train the
# model to ignore the channel.
#
# --force-exclude makes SwiftLint honour `excluded:` in .swiftlint.yml even
# though we hand it an explicit path (generated sources live under excluded dirs).
#
# Fail-open: a missing binary, unreadable payload, or non-Swift file exits 0.
set -uo pipefail

command -v swiftlint >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

file="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)" || exit 0
[ -n "$file" ] || exit 0
case "$file" in
  *.swift) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

swiftlint --fix --force-exclude --quiet "$file" >/dev/null 2>&1

violations="$(swiftlint lint --force-exclude --quiet "$file" 2>/dev/null | grep ': error:' || true)"
[ -n "$violations" ] || exit 0

printf 'SwiftLint errors remain in %s after --fix — resolve them before continuing:\n%s\n' \
  "$file" "$violations" >&2
exit 2
