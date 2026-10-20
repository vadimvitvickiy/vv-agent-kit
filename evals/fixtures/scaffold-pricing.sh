#!/bin/bash
# Copies the pricing fixture into the run's workspace and commits it, so every
# case starts from the same small git repo. Sourced by each case's scaffold.sh.
set -euo pipefail
fixture="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pricing"
cp -R "$fixture/." .
git init -q
git add -A
git -c user.name=dev -c user.email=dev@example.com commit -qm "add pricing badge"
commit() { git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm "$1"; }
