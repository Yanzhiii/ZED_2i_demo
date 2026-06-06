#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROS_DISTRO_NAME="${ROS_DISTRO_NAME:-humble}"
ROS_SETUP="/opt/ros/$ROS_DISTRO_NAME/setup.bash"
ROS2_ZED_WS="${ROS2_ZED_WS:-"$HOME/Projects/ros2_zed_ws"}"
CAMERA_MODEL="${ZED_CAMERA_MODEL:-zed2i}"
CAMERA_NAME="${ZED_CAMERA_NAME:-zed}"
START_ZED_NODE="${ZED_RVIZ_START_NODE:-False}"

remove_path_entry() {
  local entry_to_remove="$1"
  local old_ifs="$IFS"
  local path_entry
  local new_path=""

  IFS=:
  for path_entry in $PATH; do
    if [ "$path_entry" = "$entry_to_remove" ] || [ -z "$path_entry" ]; then
      continue
    fi
    if [ -z "$new_path" ]; then
      new_path="$path_entry"
    else
      new_path="$new_path:$path_entry"
    fi
  done
  IFS="$old_ifs"
  export PATH="$new_path"
}

configure_zed_sdk_env() {
  export ZED_DIR="${ZED_DIR:-"$REPO_ROOT/sdk/zed"}"
  export LD_LIBRARY_PATH="$ZED_DIR/lib:${LD_LIBRARY_PATH:-}"
  remove_path_entry "$REPO_ROOT/.venv/bin"
  export PATH="$ZED_DIR/tools:$PATH"
}

source_under_nounset() {
  set +u
  # shellcheck source=/dev/null
  source "$1"
  set -u
}

if [ ! -f "$ROS_SETUP" ]; then
  echo "ROS 2 $ROS_DISTRO_NAME setup file not found: $ROS_SETUP" >&2
  exit 1
fi

if [ ! -f "$ROS2_ZED_WS/install/local_setup.bash" ]; then
  echo "ZED ROS2 workspace is not built. Run scripts/setup_ros2_zed.sh first." >&2
  exit 1
fi

if [ "$START_ZED_NODE" != "False" ] && [ "$START_ZED_NODE" != "false" ] && [ -n "${ZED_SERIAL_NUMBER:-}" ]; then
  echo "zed_display_rviz2 does not pass ZED_SERIAL_NUMBER to zed_wrapper; start scripts/run_zed_ros2.sh separately for fixed serial selection." >&2
fi

configure_zed_sdk_env
source_under_nounset "$ROS_SETUP"
source_under_nounset "$ROS2_ZED_WS/install/local_setup.bash"

exec ros2 launch zed_display_rviz2 display_zed_cam.launch.py \
  "camera_model:=$CAMERA_MODEL" \
  "camera_name:=$CAMERA_NAME" \
  "start_zed_node:=$START_ZED_NODE" \
  "$@"
