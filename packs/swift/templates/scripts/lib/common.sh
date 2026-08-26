#!/usr/bin/env bash
# Shared helpers for the kit's Xcode scripts. Sourced, never executed.
#
# Every non-obvious choice here was measured on a large Xcode project. Read the
# comment before changing one — several of these look like they could be
# simplified and cannot.
#
# bash 3.2 compatible: macOS still ships it. No associative arrays, no `mapfile`.
set -uo pipefail

KIT_LOG_ROOT="${KIT_LOG_ROOT:-.agents/state}"

kit_die() { printf '%s\n' "$*" >&2; exit 1; }
kit_warn() { printf '%s\n' "$*" >&2; }

kit_now() { date +%s; }
kit_elapsed() { printf '%dm%02ds' "$(( ($1) / 60 ))" "$(( ($1) % 60 ))"; }

# --- project discovery ------------------------------------------------------

# A workspace wins when both exist: that is what Xcode itself opens.
kit_project_args() {
  local ws proj
  ws="$(find . -maxdepth 1 -name '*.xcworkspace' | head -1)"
  if [ -n "$ws" ]; then
    printf -- '-workspace\n%s\n' "$ws"
    return 0
  fi
  proj="$(find . -maxdepth 1 -name '*.xcodeproj' | head -1)"
  if [ -n "$proj" ]; then
    printf -- '-project\n%s\n' "$proj"
    return 0
  fi
  return 1
}

kit_scheme() {
  if [ -n "${KIT_SCHEME:-}" ]; then
    printf '%s\n' "$KIT_SCHEME"
    return 0
  fi

  local schemes base preferred
  schemes="$(xcodebuild "$@" -list 2>/dev/null \
    | awk '/Schemes:/{s=1; next} s && NF {gsub(/^[ \t]+|[ \t]+$/,""); print} s && !NF {exit}')"
  [ -n "$schemes" ] || return 1

  # Prefer the scheme named after the project or workspace — that is the app.
  # `-list` sorts alphabetically, so taking the first entry frequently picks a
  # framework target instead, and compile-checks a dependency while reporting
  # success for the whole project.
  base="$(basename "${2:-}" 2>/dev/null | sed 's/\.[^.]*$//')"
  if [ -n "$base" ]; then
    preferred="$(printf '%s\n' "$schemes" | grep -x -- "$base" | head -1)"
    if [ -n "$preferred" ]; then
      printf '%s\n' "$preferred"
      return 0
    fi
  fi

  printf '%s\n' "$schemes" | head -1
}

# --- simulator selection ----------------------------------------------------

# The device to fall back to when nothing suitable is already booted. Left unset,
# the head of `simctl list` is whatever order the tool happens to emit, so
# consecutive cold runs silently drift between devices and a flake cannot be
# attributed to one. Set KIT_SIM to pin a device outright (name or UDID).
: "${KIT_SIM_PREFERRED:=}"

# Every available simulator for a platform, one per line: "<booted|-> <udid> <name>".
kit_sim_list() {
  local os_name="${1:-iOS}"
  xcrun simctl list devices available 2>/dev/null \
    | awk -v os="-- $os_name" '
        index($0, os) == 1 {inblock=1; next}
        /^-- /            {inblock=0}
        inblock && match($0, /\([0-9A-F-]{36}\)/) {
          udid = substr($0, RSTART+1, RLENGTH-2)
          name = substr($0, 1, RSTART-1)
          gsub(/^[ \t]+|[ \t]+$/, "", name)
          print (index($0, "(Booted)") ? "booted" : "-"), udid, name
        }'
}

# $1 = list, $2 = booted|any, $3 = device name (empty matches any device).
# The name is compared against the whole field, so a preference of "iPhone 17 Pro"
# cannot also select "iPhone 17 Pro Max".
kit_sim_match() {
  printf '%s\n' "$1" | awk -v want_booted="$2" -v want_name="$3" '
    want_booted == "booted" && $1 != "booted" {next}
    {
      udid = $2
      name = $0
      sub(/^[^ ]+ [^ ]+ /, "", name)
      if (want_name == "" || name == want_name) { print udid; exit }
    }'
}

# A concrete simulator UDID for a platform.
#
# This matters far more than it looks. A `generic/platform=iOS Simulator`
# destination resolves ARCHS to several architectures and evicts the arm64
# slice of the shared DerivedData every time you alternate with Xcode.
# Measured on a large project: 9,227 file compiles / 247s with generic, versus
# 1,278 / 104s with a concrete UDID.
kit_sim_udid() {
  local os_name="${1:-iOS}" want list candidate

  # An explicit UDID is used as given — it may name a device this platform block
  # does not list, which is the caller's business, not ours.
  case "${KIT_SIM:-}" in
    ????????-????-????-????-????????????) printf '%s\n' "$KIT_SIM"; return 0 ;;
  esac

  want="${KIT_SIM:-$KIT_SIM_PREFERRED}"
  list="$(kit_sim_list "$os_name")"
  [ -n "$list" ] || return 0

  # Ranked, and the order is the whole point: a booted preferred device, then any
  # booted device — reusing a warm one is free where a cold boot costs 20-35s —
  # then the preferred device cold, then the head of the list. The first two keep
  # a warm run warm; the third is what stops a cold run picking arbitrarily.
  for candidate in \
    "$(kit_sim_match "$list" booted "$want")" \
    "$(kit_sim_match "$list" booted '')" \
    "$(kit_sim_match "$list" any    "$want")" \
    "$(kit_sim_match "$list" any    '')"
  do
    [ -n "$candidate" ] && { printf '%s\n' "$candidate"; return 0; }
  done
}

# $1 = udid, $2 = platform. The device's NAME, for writing into a config file that
# is shared through source control: UDIDs are regenerated per machine and per
# Xcode install, names survive both.
kit_sim_name() {
  kit_sim_list "${2:-iOS}" | awk -v id="$1" '$2 == id { sub(/^[^ ]+ [^ ]+ /, ""); print; exit }'
}

# Boot early and in the background: a cold boot costs 20-35s, and overlapping it
# with the build takes it off the critical path. Simulators are deliberately
# LEFT BOOTED afterwards so the next run starts warm.
kit_boot_async() {
  local udid="$1"
  [ -n "$udid" ] || return 0
  xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 &
}

# --- xcodebuild invocation --------------------------------------------------

# Xcode 26 re-validates macro and package-plugin fingerprints and can hang.
# The CLI flags cover most cases; the defaults are belt-and-braces because the
# hang can occur before the flags are parsed. cfprefsd must be kicked or the
# write stays stale-cached.
kit_apply_xcode_defaults() {
  local stamp="${TMPDIR:-/tmp}/.kit-xcode-defaults"
  [ -e "$stamp" ] && return 0
  defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES 2>/dev/null
  defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES 2>/dev/null
  defaults write com.apple.dt.Xcode IDEPackageSupportUseBuiltinSCM -bool YES 2>/dev/null
  killall cfprefsd >/dev/null 2>&1
  : >"$stamp"
}

# Flags safe on any project.
#
# NOT included, deliberately:
#   CODE_SIGNING_ALLOWED=NO — a build-setting override changes the build
#     description. If Xcode builds the same DerivedData without it, the two
#     evict each other; measured as a 5,879-file rebuild on every switch.
#     Simulator products need no signing anyway.
#   -derivedDataPath — omitting it reuses Xcode's shared cache, so IDE and CLI
#     builds warm each other. Pass KIT_DERIVED_DATA only for an isolated build.
#     This applies to phases that COMPILE. `test-without-building -xctestrun`
#     names no project, so omitting the flag there does the opposite: xcodebuild
#     mints a fresh anonymous DerivedData per run for its logs. test.sh passes it
#     deliberately — see the comment there before removing it.
#   -disableAutomaticPackageResolution / -skipPackageUpdates — measured to
#     change nothing. They govern version resolution, not the graph load.
kit_common_flags() {
  printf -- '-skipMacroValidation\n-skipPackagePluginValidation\n'
  if [ -n "${KIT_DERIVED_DATA:-}" ]; then
    printf -- '-derivedDataPath\n%s\n' "$KIT_DERIVED_DATA"
  fi
}

# --- SPM resolution gating --------------------------------------------------

# Resolving costs 6-12s warm, up to 32s cold, and `xcodebuild build` resolves
# whatever it needs anyway. Gate it on a cheap stat-based stamp (name+mtime+size)
# rather than hashing contents: ~0.1s, and a spurious `touch` only costs one
# needless resolve.
kit_spm_stamp() {
  # The stamp describes a PRIMED STORE, not merely a set of manifests, so the
  # store it was primed against belongs in it. Without this line an --isolated run
  # writes a stamp that a later default-store run reads as "already resolved",
  # and the default store is then used unresolved.
  printf 'derived-data=%s\n' "${KIT_DERIVED_DATA:-default}"
  # -L follows symlinks. A package directory symlinked into the tree — the normal
  # way a local package under active development is wired in — is walked straight
  # past by a plain find, so its manifest never enters the fingerprint and editing
  # it never triggers a re-resolve. maxdepth bounds the cycle risk -L introduces.
  find -L . -maxdepth 3 \( -name 'Package.swift' -o -name 'Package.resolved' \) \
       -not -path './.build/*' -not -path './DerivedData/*' -exec stat -f '%N %m %z' {} + 2>/dev/null
  find -L . -maxdepth 2 -name 'project.pbxproj' -exec stat -f '%N %m %z' {} + 2>/dev/null
}

kit_resolve_packages_if_stale() {
  local stamp_file="$KIT_LOG_ROOT/.packages-stamp" current
  current="$(kit_spm_stamp | shasum | cut -d' ' -f1)"
  if [ -f "$stamp_file" ] && [ "$(cat "$stamp_file" 2>/dev/null)" = "$current" ]; then
    return 0
  fi
  xcodebuild "$@" -resolvePackageDependencies >/dev/null 2>&1
  mkdir -p "$(dirname "$stamp_file")"
  printf '%s\n' "$current" >"$stamp_file"
}

# --- output -----------------------------------------------------------------

# xcbeautify/xcpretty are for the human watching. Counts and failures are always
# parsed from the RAW log: xcpretty silently drops Swift Testing output.
kit_formatter() {
  if command -v xcbeautify >/dev/null 2>&1; then
    printf 'xcbeautify\n'
  elif command -v xcpretty >/dev/null 2>&1; then
    printf 'xcpretty\n'
  else
    printf 'cat\n'
  fi
}

kit_run_logged() {
  local log="$1"; shift
  mkdir -p "$(dirname "$log")"
  set -o pipefail
  "$@" 2>&1 | tee "$log" | "$(kit_formatter)"
  return "${PIPESTATUS[0]}"
}
