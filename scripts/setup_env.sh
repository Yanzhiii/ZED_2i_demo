#!/usr/bin/env bash

if [ -n "${BASH_VERSION:-}" ]; then
  SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  eval 'SCRIPT_PATH="${(%):-%x}"'
else
  SCRIPT_PATH="$0"
fi

REPO_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
export ZED_DIR="${ZED_DIR:-"$REPO_ROOT/sdk/zed"}"
export LD_LIBRARY_PATH="$ZED_DIR/lib:${LD_LIBRARY_PATH:-}"
export PATH="$REPO_ROOT/.venv/bin:$ZED_DIR/tools:$PATH"

echo "REPO_ROOT=$REPO_ROOT"
echo "ZED_DIR=$ZED_DIR"
echo "Python=$(command -v python)"
