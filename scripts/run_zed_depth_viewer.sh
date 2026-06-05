#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/setup_env.sh" >/dev/null
exec "$ZED_DIR/tools/ZED_Depth_Viewer" "$@"
