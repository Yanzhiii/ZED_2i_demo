#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/setup_env.sh" >/dev/null
exec python "$REPO_ROOT/src/zed_quick_test.py" "$@"
