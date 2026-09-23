#!/usr/bin/env bash
# PostToolUse(Edit|Write) — lint an edited Postgres migration with squawk.
#
# squawk checks mechanically what a migrations skill would otherwise have to
# remember: a non-concurrent index build, a column added with a default or NOT
# NULL that rewrites or scans the table, a constraint added without NOT VALID, a
# rename or type change in place, a missing lock_timeout. The same failure modes
# strong_migrations and Atlas lint check — the three agree on them.
#
# Only files under a migrations directory are linted, and down migrations are
# skipped: a down migration drops what its up created, and squawk would flag
# every one. Configure rules for the project in .squawk.toml.
#
# Exit 2 feeds the findings back to the model; the edit itself stands.
#
# Fail-open: a missing binary, unreadable payload, or non-migration file exits 0.
set -uo pipefail

command -v squawk >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

file="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)" || exit 0
[ -n "$file" ] || exit 0
case "$file" in
  *.down.sql|*_down.sql|*/down.sql) exit 0 ;;
  */migrations/*.sql|*/migrate/*.sql) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

out="$(squawk "$file" 2>&1)" && exit 0
[ -n "$out" ] || exit 0

printf 'squawk flagged %s — each finding is a lock or rewrite on a live table, or a\nbreaking change. Fix it, or record in the migration why it is safe here:\n\n%s\n' \
  "$file" "$(printf '%s\n' "$out" | head -40)" >&2
exit 2
