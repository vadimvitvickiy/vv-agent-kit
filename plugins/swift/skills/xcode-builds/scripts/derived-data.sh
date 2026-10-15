#!/usr/bin/env bash
# Report and clean Xcode DerivedData folders left behind by removed checkouts.
#
#   derived-data.sh                       report free space and every folder's state
#   derived-data.sh --delete <checkout>   delete the folders of a checkout that no longer exists
#   derived-data.sh --delete-orphans      delete every orphan the report lists
#
# A project folder records the workspace it was built from in info.plist's
# WorkspacePath. Live: that path exists. Orphan: it does not, so nothing will
# read the folder again. Unknown: no WorkspacePath at all — reported, never
# deleted. The shared caches beside the project folders (ModuleCache.noindex
# and the like) belong to every project and are never touched.
#
# Sizes come from du, which counts APFS clones twice; the df lines before and
# after a delete are the real measure of what was freed.
set -uo pipefail

die() { printf 'derived-data: %s\n' "$*" >&2; exit 1; }

# DERIVED_DATA_ROOT overrides Xcode's setting, to point the script at a scratch folder.
custom="${DERIVED_DATA_ROOT:-$(defaults read com.apple.dt.Xcode IDECustomDerivedDataLocation 2>/dev/null)}"
case "$custom" in
  '') ROOT="$HOME/Library/Developer/Xcode/DerivedData" ;;
  /*) ROOT="$custom" ;;
  *)  die "DerivedData location is relative to each workspace ($custom); nothing global to scan" ;;
esac
[ -d "$ROOT" ] || die "no DerivedData folder at $ROOT"

free_space() {
  df -h /System/Volumes/Data 2>/dev/null | awk 'NR==2 { printf "data volume: %s free of %s\n", $4, $2 }'
}

# One line per project folder: "<state>\t<folder>\t<workspace path>".
classify() {
  local dir ws
  for dir in "$ROOT"/*/; do
    dir="${dir%/}"
    [ -d "$dir" ] || continue  # an empty root leaves the glob unexpanded
    case "$(basename "$dir")" in
      *.noindex|SDKExplicitPrecompiledModules) continue ;;
    esac
    ws="$(plutil -extract WorkspacePath raw "$dir/info.plist" 2>/dev/null)"
    if [ -z "$ws" ]; then
      printf 'unknown\t%s\t-\n' "$dir"
    elif [ -e "$ws" ]; then
      printf 'live\t%s\t%s\n' "$dir" "$ws"
    else
      printf 'orphan\t%s\t%s\n' "$dir" "$ws"
    fi
  done
}

delete() {
  local dir="$1"
  printf 'deleting %s\n' "$dir"
  rm -rf "$dir" || printf 'derived-data: could not fully delete %s\n' "$dir" >&2
}

case "${1:-}" in
  '')
    free_space
    classify | while IFS="$(printf '\t')" read -r state dir ws; do
      printf '%-8s %7s  %s  <- %s\n' "$state" "$(du -sh "$dir" 2>/dev/null | cut -f1)" "$(basename "$dir")" "$ws"
    done
    ;;
  --delete)
    [ -n "${2:-}" ] || die "--delete needs the removed checkout's path"
    checkout="${2%/}"
    case "$checkout" in /*) ;; *) checkout="$PWD/$checkout" ;; esac
    [ -e "$checkout" ] && die "$checkout still exists; remove the checkout first"
    free_space
    found=0
    while IFS="$(printf '\t')" read -r state dir ws; do
      case "$ws" in
        "$checkout"/*) [ "$state" = orphan ] && { delete "$dir"; found=1; } ;;
      esac
    done < <(classify)
    [ "$found" = 1 ] || printf 'no DerivedData folder was built from %s\n' "$checkout"
    free_space
    ;;
  --delete-orphans)
    free_space
    while IFS="$(printf '\t')" read -r state dir _; do
      [ "$state" = orphan ] && delete "$dir"
    done < <(classify)
    free_space
    ;;
  *)
    die "unknown argument: $1 (see the header of $0)"
    ;;
esac
