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

# Prefer an already-Booted simulator, then any available one.
#
# This matters far more than it looks. A `generic/platform=iOS Simulator`
# destination resolves ARCHS to several architectures and evicts the arm64
# slice of the shared DerivedData every time you alternate with Xcode.
# Measured on a large project: 9,227 file compiles / 247s with generic, versus
# 1,278 / 104s with a concrete UDID.
kit_sim_udid() {
  local os_name="${1:-iOS}" udid
  udid="$(xcrun simctl list devices available 2>/dev/null \
    | awk -v os="-- $os_name" '
        index($0, os) == 1 {inblock=1; next}
        /^-- /{inblock=0}
        inblock && /\(Booted\)/ {
          if (match($0, /\([0-9A-F-]{36}\)/)) {
            print substr($0, RSTART+1, RLENGTH-2); exit
          }
        }')"
  [ -n "$udid" ] && { printf '%s\n' "$udid"; return 0; }

  udid="$(xcrun simctl list devices available 2>/dev/null \
    | awk -v os="-- $os_name" '
        index($0, os) == 1 {inblock=1; next}
        /^-- /{inblock=0}
        inblock && /\([0-9A-F-]{36}\)/ {
          if (match($0, /\([0-9A-F-]{36}\)/)) {
            print substr($0, RSTART+1, RLENGTH-2); exit
          }
        }')"
  printf '%s\n' "$udid"
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
  find . -maxdepth 3 \( -name 'Package.swift' -o -name 'Package.resolved' \) \
       -not -path './.build/*' -not -path './DerivedData/*' -exec stat -f '%N %m %z' {} + 2>/dev/null
  find . -maxdepth 2 -name 'project.pbxproj' -exec stat -f '%N %m %z' {} + 2>/dev/null
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
