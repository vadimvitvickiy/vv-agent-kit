#!/usr/bin/env bash
# Stop — the kit mandates a test with every behaviour change. Where PR CI runs no
# unit tests, this is the only automated gate on that rule.
#
# Fires at most ONCE per session (sentinel), and only when a source file was
# touched more recently than the newest local test run. One blocked turn is
# enough: the model either runs the tests or states why the change is exempt.
#
# OPT-IN. This hook is registered for every project the plugin is installed in,
# but it is the only one that can block a turn, so it stays inert unless the
# project opted in. A blocking gate applied to a project that never asked for it
# is worse than no gate at all — it gets the whole plugin disabled.
#
# A project opts in by having `scripts/test.sh` (written by /kit:scripts), or by
# setting KIT_TEST_COMMAND explicitly. The script is preferred because it also
# writes the run log this gate reads: without something writing that log, the
# gate fires on every session regardless of whether tests ran.
#
# Configuration:
#   KIT_TEST_COMMAND   explicit test command; overrides scripts/test.sh
#   KIT_SOURCE_GLOB    pathspec for source files         (default '*.swift')
#   KIT_TEST_LOG_DIR   dir whose newest file marks a run (default .agents/state/test-runs)
#
# Fail-open: anything unexpected exits 0 so a bug here can never wedge a session.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
payload="$(cat)"

# A Stop hook that blocks re-enters Stop when the follow-up turn ends. Bail then.
jq -e '.stop_hook_active == true' >/dev/null 2>&1 <<<"$payload" && exit 0

session="$(jq -r '.session_id // "unknown"' <<<"$payload" 2>/dev/null)" || exit 0
cwd="$(jq -r '.cwd // empty' <<<"$payload" 2>/dev/null)" || exit 0
[ -n "$cwd" ] || exit 0
cd "$cwd" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Opt-in check happens after the cd, so scripts/test.sh is resolved in the
# project, not wherever the hook was launched from.
if [ -n "${KIT_TEST_COMMAND:-}" ]; then
  test_cmd="$KIT_TEST_COMMAND"
elif [ -x scripts/test.sh ]; then
  test_cmd="scripts/test.sh"
else
  exit 0
fi

glob="${KIT_SOURCE_GLOB:-*.swift}"
log_dir="${KIT_TEST_LOG_DIR:-.agents/state/test-runs}"

sentinel="${TMPDIR:-/tmp}/kit-test-gate-${session}"
[ -e "$sentinel" ] && exit 0

# BSD and GNU stat disagree on the mtime flag.
mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null
}

changed="$(
  {
    git diff --name-only HEAD -- "$glob"
    git ls-files --others --exclude-standard -- "$glob"
  } 2>/dev/null | sort -u
)"
[ -n "$changed" ] || exit 0

newest_change=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  m="$(mtime "$f")" || continue
  [ -n "$m" ] || continue
  [ "$m" -gt "$newest_change" ] && newest_change="$m"
done <<<"$changed"
[ "$newest_change" -gt 0 ] || exit 0

newest_test=0
if [ -d "$log_dir" ]; then
  for f in "$log_dir"/*; do
    [ -f "$f" ] || continue
    m="$(mtime "$f")" || continue
    [ -n "$m" ] || continue
    [ "$m" -gt "$newest_test" ] && newest_test="$m"
  done
fi
[ "$newest_test" -ge "$newest_change" ] && exit 0

: >"$sentinel"
count="$(printf '%s\n' "$changed" | grep -c .)"

# Only files touched since the last test run are actionable; a long-lived branch
# can carry a hundred others, and listing them all floods the context.
recent="$(
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    m="$(mtime "$f")" || continue
    [ -n "$m" ] || continue
    [ "$m" -gt "$newest_test" ] && printf '%s\n' "$f"
  done <<<"$changed" | head -10
)"

{
  printf 'Test gate: %s source file(s) changed with no local test run since.\n\n' "$count"
  printf '%s\n' "$recent" | sed 's/^/  /'
  printf '\nRun `%s`, or state explicitly which exemption applies\n' "$test_cmd"
  printf '(see kit:writing-tests — generated code, pure layout, renames).\n'
  printf 'This gate fires once per session — it will not block you again.\n'
} >&2
exit 2
