#!/usr/bin/env bash
# Structural gate for the kit. Every rule here is one a human would otherwise
# have to remember on every edit.
#
# Usage: validate.sh [path]   — defaults to the repo root.
# Exit 0 = clean, 1 = violations found (each printed with file and reason).
#
# The repo is a marketplace of several plugins: the neutral one at the root, and
# one per stack under plugins/<stack>/. Every rule runs over all of them.
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

# One plugin root per line: the repo root, then every plugins/<stack>/ with a manifest.
plugin_roots="$(
  printf '%s\n' "$root"
  find "$root/plugins" -mindepth 3 -maxdepth 3 -path '*/.claude-plugin/plugin.json' 2>/dev/null \
    | sed 's|/.claude-plugin/plugin.json$||' | sort
)"

# The namespace a plugin's components are invoked under — its manifest name.
namespace() {
  local manifest="$1/.claude-plugin/plugin.json" ns=""
  [ -f "$manifest" ] && ns="$(sed -n 's/^[[:space:]]*"name":[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -1)"
  printf '%s' "${ns:-vvkit}"
}

# Files under the named subtrees of every plugin root.
find_in_plugins() {
  local subtrees="$1"
  shift
  while IFS= read -r pr; do
    [ -n "$pr" ] || continue
    for tree in $subtrees; do
      [ -d "$pr/$tree" ] && find "$pr/$tree" "$@"
    done
  done <<<"$plugin_roots"
}

# Every <namespace>:<name> reference must resolve to something that exists.
# Commands and agents are valid targets too, not just skills.
known="$(
  while IFS= read -r pr; do
    [ -n "$pr" ] || continue
    ns="$(namespace "$pr")"
    {
      find "$pr/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
      find "$pr/commands" -maxdepth 1 -name '*.md' -exec basename {} .md \;
      find "$pr/agents" -maxdepth 1 -name '*.md' -exec basename {} .md \;
    } 2>/dev/null | sed "s|^|$ns:|"
  done <<<"$plugin_roots" | sort -u
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

  # Without an H1 the skill has no title once the frontmatter is stripped, and
  # every heading in the body reads as a top-level section.
  grep -q '^# ' "$f" || report "$f" "body has no H1 heading"
done < <(find_in_plugins skills -name SKILL.md 2>/dev/null | sort)

# Placeholders are legal only in the trees that exist to be filled in.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  # templates/ exist to be filled in; tests/ holds deliberate violations;
  # .claude/ and .agents/ are this repo's own notes, not shipped components.
  case "$f" in
    "$root"/templates/*|"$root"/plugins/*/templates/*|"$root"/tests/*|"$root"/.claude/*|"$root"/.agents/*) continue ;;
  esac
  report "$f" "contains an unfilled {{PLACEHOLDER}}"
done < <(grep -rlE '\{\{[A-Z_]+\}\}' "$root" --include='*.md' --include='*.json' --include='*.yml' 2>/dev/null | sort)

while IFS= read -r line; do
  [ -n "$line" ] || continue
  f="${line%%:*}"
  ref="$(printf '%s' "$line" | grep -oE 'vvkit(-[a-z0-9]+)?:[a-z0-9-]+' | head -1)"
  [ -n "$ref" ] || continue
  known_ref "$ref" || report "$f" "cross-reference '$ref' names no skill, command or agent"
done < <(
  find_in_plugins "skills agents commands hooks templates rules" -name '*.md' 2>/dev/null \
    | while IFS= read -r f; do grep -noE 'vvkit(-[a-z0-9]+)?:[a-z0-9-]+' "$f" | sed "s|^|$f:|"; done \
    | sort -u
)

# An @-link force-loads the file at session start, which spends the context the
# references/ split exists to save. Plain relative paths only.
while IFS= read -r line; do
  [ -n "$line" ] || continue
  report "${line%%:*}" "uses an @-link; reference files must be linked by plain path"
done < <(
  find_in_plugins "skills agents commands" -name '*.md' 2>/dev/null \
    | while IFS= read -r f; do grep -nE '(^|[[:space:](])@[A-Za-z0-9_./-]+\.md' "$f" | sed "s|^|$f:|"; done \
    | sort -u
)

# The install commands are the first thing a reader copies. A placeholder that
# survived into them is a broken first impression, and no other check sees it:
# the {{PLACEHOLDER}} rule above only knows about brace syntax.
if [ -f "$root/README.md" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    report "$root/README.md:${line%%:*}" "install command still contains a placeholder"
  done < <(
    grep -nE 'claude plugin (marketplace add|install)' "$root/README.md" 2>/dev/null \
      | grep -E '<[a-z][a-z0-9_-]*>'
  )
fi

# Every shipped shell script must fail open and be executable — the generated
# ones in templates/ land in users' repos, so they are held to the same bar as hooks.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -x "$f" ] || report "$f" "script is not executable"
  grep -q 'set -uo pipefail' "$f" || report "$f" "script does not 'set -uo pipefail'"
done < <(find_in_plugins "hooks templates" -name '*.sh' 2>/dev/null | sort)

if [ "$fail" -eq 0 ]; then
  count="$(find_in_plugins skills -name SKILL.md 2>/dev/null | grep -c . || true)"
  plugins="$(printf '%s\n' "$plugin_roots" | grep -c .)"
  echo "validate: clean (${count} skills across ${plugins} plugins)"
fi
exit "$fail"
