#!/usr/bin/env bash
# PreToolUse(Bash) — refuse a destructive database command until it has been
# deliberately confirmed.
#
# A tripwire against haste, not a security boundary. It reads the command text,
# so it cannot see SQL inside a file passed with -f, a script that runs psql for
# you, or a delete made through an API. The real boundary is a read-only role or
# replica for anything an agent touches in production; this catches the commands
# that actually caused the published incidents:
#
#   - ORM and migration-tool commands that drop or rebuild a schema. Claude Code
#     issue #27063: `drizzle-kit push --force` against a production database
#     wiped 60+ tables.
#   - DROP, TRUNCATE, and DELETE or UPDATE with no WHERE, sent through a
#     database client. The same rule set as the community guard hooks (the
#     yurukusa gist, klyvo), narrowed to commands that invoke a client so a
#     commit message mentioning "drop table" does not trip it.
#
# Explicitly local targets pass: a client command naming localhost, 127.0.0.1 or
# ::1, anything run through `docker compose exec`, and sqlite3. A command whose
# target comes from an environment variable is not local — the hook cannot see
# where $DATABASE_URL points, which is exactly the case that goes wrong.
#
# Confirming: prefix the command with KIT_DB_ACK=1 after the human has confirmed
# the target and the statement. KIT_DB_GUARD=0 in the environment turns the hook
# off entirely.
#
# Fail-open: anything unexpected exits 0 so a bug here can never wedge a session.
set -uo pipefail

[ "${KIT_DB_GUARD:-1}" = "0" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -n "$cmd" ] || exit 0

case "$cmd" in
  *KIT_DB_ACK=1*) exit 0 ;;
esac

lc="$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]' | tr '\n' ' ')"

matches() {
  printf '%s' "$lc" | grep -qE "$1"
}

refuse() {
  {
    printf 'Database guard: %s\n\n  %s\n\n' "$1" "$(printf '%s' "$cmd" | head -c 300)"
    printf 'Before running it: confirm with the human which database this reaches and that the\n'
    printf 'data loss is intended. Then re-run with KIT_DB_ACK=1 prefixed to the command.\n'
    printf 'For a local development database, name the host explicitly (localhost) or go through\n'
    printf '`docker compose exec`, which the guard lets through.\n'
  } >&2
  exit 2
}

# 1. Tools that drop or rebuild a schema. Their target comes from config or the
#    environment, so the guard cannot tell a local database from production.
tool_rules='drizzle-kit[[:space:]]+(drop|push.*--force)'
tool_rules="$tool_rules|prisma[[:space:]]+migrate[[:space:]]+reset"
tool_rules="$tool_rules|prisma[[:space:]]+db[[:space:]]+push.*--(force-reset|accept-data-loss)"
tool_rules="$tool_rules|(rails|rake)[[:space:]]+db:(drop|reset|purge|schema:load)"
tool_rules="$tool_rules|manage\\.py[[:space:]]+(flush|reset_db)"
tool_rules="$tool_rules|artisan[[:space:]]+(migrate:fresh|migrate:reset|db:wipe)"
tool_rules="$tool_rules|dbmate[[:space:]].*(^|[[:space:]])drop([[:space:]]|$)"
tool_rules="$tool_rules|(^|[[:space:]/])migrate[[:space:]].*[[:space:]](drop|down[[:space:]]+-all)([[:space:]]|$)"
tool_rules="$tool_rules|goose[[:space:]].*[[:space:]]reset([[:space:]]|$)"
tool_rules="$tool_rules|atlas[[:space:]]+schema[[:space:]]+clean"
tool_rules="$tool_rules|(^|[[:space:];&|])dropdb[[:space:]]"
if matches "$tool_rules"; then
  refuse "this command drops or rebuilds a database schema, and its target comes from configuration."
fi

# 2. Destructive SQL sent through a client. Only commands that invoke one are
#    inspected at all.
client='(^|[[:space:];&|(/])(psql|pgcli|mysql|mariadb|clickhouse-client|usql|cockroach[[:space:]]+sql)([[:space:]]|$)'
matches "$client" || exit 0

if matches 'localhost|127\.0\.0\.1|::1|docker[[:space:]]+compose[[:space:]]+exec|docker-compose[[:space:]]+exec'; then
  exit 0
fi

if matches 'drop[[:space:]]+(table|database|schema)|truncate[[:space:]]|alter[[:space:]]+table[^;]*drop[[:space:]]+column'; then
  refuse "this sends DROP, TRUNCATE or DROP COLUMN to a database the guard cannot confirm is local."
fi

# DELETE and UPDATE are judged per statement: one with a WHERE does not excuse
# another without.
unbounded="$(printf '%s' "$lc" | tr ';' '\n' \
  | grep -E 'delete[[:space:]]+from[[:space:]]|update[[:space:]]+[^[:space:]]+[[:space:]]+set[[:space:]]' \
  | grep -vE '[[:space:]]where[[:space:]]' || true)"
if [ -n "$unbounded" ]; then
  refuse "this sends a DELETE or UPDATE with no WHERE clause to a database the guard cannot confirm is local."
fi

exit 0
