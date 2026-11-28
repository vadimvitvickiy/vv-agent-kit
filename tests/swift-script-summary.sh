#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/bin" "$fixture/tmp" "$fixture/Fixture.xcodeproj"
cp -R "$repo/plugins/swift/templates/scripts" "$fixture/"
cd "$fixture"

export PATH="$fixture/bin:$PATH"
export TMPDIR="$fixture/tmp"
export KIT_SIM=00000000-0000-0000-0000-000000000001
export KIT_LOG_ROOT="$fixture/logs"
unset KIT_DERIVED_DATA
touch "$TMPDIR/.kit-xcode-defaults"

cat > bin/xcodebuild <<'SH'
#!/usr/bin/env bash
result_bundle=""
derived_data="$PWD/default-build"
xctestrun=""
previous=""
for arg; do
  case "$previous" in
    -resultBundlePath) result_bundle="$arg" ;;
    -derivedDataPath) derived_data="$arg" ;;
    -xctestrun) xctestrun="$arg" ;;
  esac
  case "$arg" in
    -resolvePackageDependencies) exit 0 ;;
    build|build-for-testing|test|test-without-building|-showBuildSettings) action="$arg" ;;
  esac
  previous="$arg"
done
case "$derived_data" in
  /*) ;;
  *) derived_data="$PWD/$derived_data" ;;
esac
products="$derived_data/Build/Products"
if [ "$action" = -showBuildSettings ]; then
  printf '    BUILD_DIR = %s\n' "$products"
  exit 0
fi
if [ "$action" = build-for-testing ] && [ "${FIXTURE_TEST_PRODUCTS:-}" = 1 ]; then
  mkdir -p "$products"
  touch "$products/Fixture_current.xctestrun"
fi
printf 'verbose %s output\n' "$action"
if [ "$action" = "${FIXTURE_FAIL_ACTION:-}" ]; then
  if [ "$action" = test ]; then
    if [ "${FIXTURE_TEST_BUNDLE:-}" = 1 ]; then
      mkdir -p "$result_bundle"
    fi
    printf '✘ Test fixtureTest() recorded an issue at Fixture.swift:10: Expectation failed\n' >&2
  else
    printf 'error: %s fixture failed\n' "$action" >&2
  fi
  exit 65
fi
if [ "$action" = test-without-building ]; then
  printf 'Replayed %s\n' "$xctestrun"
fi
if [ "$action" = test ] || [ "$action" = test-without-building ]; then
  printf 'Test run with 1 test passed\n'
fi
SH
# The template uses BSD stat to order test products. Translate that call on GNU hosts.
if stat -c '%Y' . >/dev/null 2>&1; then
  cat > bin/stat <<'SH'
#!/usr/bin/env bash
if [ "$1" = -f ] && [ "$2" = '%m %N' ]; then
  shift 2
  exec /usr/bin/stat -c '%Y %n' -- "$@"
fi
exec /usr/bin/stat "$@"
SH
fi
cat > bin/xcrun <<'SH'
#!/usr/bin/env bash
[ "$1" = xcresulttool ] || exit 0
[ "$#" -eq 6 ] || exit 1
cat <<'JSON'
{
  "testFailures" : [
    {
      "failureText" : "Expected A, got B",
      "testName" : "fixtureTest()"
    }
  ],
  "title" : "Test - Fixture",
  "totalTestCount" : 1
}
JSON
SH
printf '#!/usr/bin/env bash\ncat\n' > bin/xcbeautify
chmod +x bin/*

run() {
  local expected_status="$1" status=0
  shift
  bash "$@" --scheme Fixture > console.log 2>&1 || status=$?
  if [ "$status" -ne "$expected_status" ]; then
    cat console.log >&2
    printf 'Expected exit %s, got %s\n' "$expected_status" "$status" >&2
    exit 1
  fi
}

contains() {
  grep -Fq -- "$1" "$2" || { printf 'Missing %s in %s\n' "$1" "$2" >&2; exit 1; }
}

omits_verbose_output() {
  if grep -q '^verbose ' console.log; then
    cat console.log >&2
    exit 1
  fi
}

run 0 scripts/build.sh
contains 'verbose build output' console.log
run 0 scripts/build.sh --summary
omits_verbose_output
contains 'build-logs/Fixture.log' console.log
contains 'verbose build output' "$KIT_LOG_ROOT/build-logs/Fixture.log"

FIXTURE_FAIL_ACTION=build run 65 scripts/build.sh --summary
omits_verbose_output
contains 'error: build fixture failed' console.log

run 0 scripts/test.sh --summary
omits_verbose_output
contains '1 tests passed' console.log
contains 'test-runs/Fixture.log' console.log
contains 'verbose build-for-testing output' "$KIT_LOG_ROOT/test-runs/Fixture.build.log"
contains 'verbose test output' "$KIT_LOG_ROOT/test-runs/Fixture.log"

FIXTURE_FAIL_ACTION='test' run 65 scripts/test.sh --summary
omits_verbose_output
contains 'Fixture.swift:10: Expectation failed' console.log
contains 'preserved in' console.log

FIXTURE_FAIL_ACTION='test' FIXTURE_TEST_BUNDLE=1 run 65 scripts/test.sh --summary
omits_verbose_output
contains 'Expected A, got B' console.log
contains '1 tests)' console.log

mkdir -p default-build/Build/Products
touch default-build/Build/Products/Fixture_stale.xctestrun
FIXTURE_TEST_PRODUCTS=1 run 0 scripts/test.sh --isolated --summary
contains "Replayed $PWD/.build/derived-data/Build/Products/Fixture_current.xctestrun" \
  "$KIT_LOG_ROOT/test-runs/Fixture.log"

printf 'Swift script summary and isolated test checks passed\n'
