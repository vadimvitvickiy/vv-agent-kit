#!/usr/bin/env bash
# Structural gate for the kit. Every rule here is one a human would otherwise
# have to remember on every edit.
#
# Usage: validate.sh [path]   — defaults to the repo root.
# Exit 0 = clean, 1 = violations found (each printed with file and reason).
#
# No bash arrays: macOS still ships bash 3.2, where "${arr[@]}" under `set -u`
# errors on an empty array.
set -uo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
fail=0

report() {
  printf '%s\n  %s\n' "$1" "$2" >&2
  fail=1
}

# Every kit:<name> reference must resolve to something that exists. Commands and
# agents are valid targets too, not just skills.
known="$(
  {
    find "$root/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
    find "$root/commands" -maxdepth 1 -name '*.md' -exec basename {} .md \;
    find "$root/agents" -maxdepth 1 -name '*.md' -exec basename {} .md \;
  } 2>/dev/null | sort -u
)"

known_ref() {
  printf '%s\n' "$known" | grep -qx -- "$1"
}

while IFS= read -r f; do
  [ -n "$f" ] || continue
  dir="$(basename "$(dirname "$f")")"
  front="$(awk 'NR==1 && $0=="---"{inf=1; next} inf && $0=="---"{exit} inf{print}' "$f")"

  if [ -z "$front" ]; then
    report "$f" "missing YAML frontmatter"
    continue
  fi

  name="$(printf '%s\n' "$front" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
  desc="$(printf '%s\n' "$front" | sed -n 's/^description:[[:space:]]*//p' | head -1)"

  [ -n "$name" ] || report "$f" "frontmatter has no 'name'"
  [ -n "$desc" ] || report "$f" "frontmatter has no 'description'"

  if [ -n "$name" ] && [ "$name" != "$dir" ]; then
    report "$f" "name '$name' does not match directory '$dir'"
  fi

  case "$name" in
    *[!a-z0-9-]*) report "$f" "name '$name' must be lowercase letters, numbers and hyphens only" ;;
  esac

  case "$desc" in
    "Use when"*) ;;
    *) report "$f" "description must start with 'Use when'" ;;
  esac

  if [ "${#desc}" -gt 500 ]; then
    report "$f" "description is ${#desc} chars, over the 500 limit"
  fi

  # A description that narrates the workflow becomes a shortcut agents take
  # instead of reading the skill body.
  if printf '%s' "$desc" | grep -qiE '(dispatch|, then |after that|step [0-9]|between (each|tasks))'; then
    report "$f" "description appears to summarize workflow; state triggering conditions only"
  fi

  if [ "${#front}" -gt 1024 ]; then
    report "$f" "frontmatter is ${#front} chars, over the 1024 limit"
  fi
done < <(find "$root/skills" -name SKILL.md 2>/dev/null | sort)

# Placeholders are legal only in the trees that exist to be filled in.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    "$root"/templates/*|"$root"/packs/*|"$root"/tests/*) continue ;;
  esac
  report "$f" "contains an unfilled {{PLACEHOLDER}}"
done < <(grep -rlE '\{\{[A-Z_]+\}\}' "$root" --include='*.md' 2>/dev/null | sort)

while IFS= read -r line; do
  [ -n "$line" ] || continue
  f="${line%%:*}"
  ref="$(printf '%s' "$line" | grep -oE 'kit:[a-z0-9-]+' | head -1)"
  ref="${ref#kit:}"
  [ -n "$ref" ] || continue
  known_ref "$ref" || report "$f" "cross-reference 'kit:$ref' names no skill, command or agent"
done < <(
  for tree in skills agents commands hooks; do
    grep -rnoE 'kit:[a-z0-9-]+' "$root/$tree" --include='*.md' 2>/dev/null
  done | sort -u
)

# Hooks must fail open and be executable.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -x "$f" ] || report "$f" "hook is not executable"
  grep -q 'set -uo pipefail' "$f" || report "$f" "hook does not 'set -uo pipefail'"
done < <(find "$root/hooks" -name '*.sh' 2>/dev/null | sort)

if [ "$fail" -eq 0 ]; then
  count="$(find "$root/skills" -name SKILL.md 2>/dev/null | grep -c . || true)"
  echo "validate: clean (${count} skills)"
fi
exit "$fail"
