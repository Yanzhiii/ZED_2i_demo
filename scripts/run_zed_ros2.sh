#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROS_DISTRO_NAME="${ROS_DISTRO_NAME:-humble}"
ROS_SETUP="/opt/ros/$ROS_DISTRO_NAME/setup.bash"
ROS2_ZED_WS="${ROS2_ZED_WS:-"$HOME/Projects/ros2_zed_ws"}"
CAMERA_MODEL="${ZED_CAMERA_MODEL:-zed2i}"
CAMERA_NAME="${ZED_CAMERA_NAME:-zed}"
PUBLISH_TF="${ZED_PUBLISH_TF:-true}"

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

source_local_package_setup() {
  local setup_file
  for setup_file in \
    "$REPO_ROOT/install/local_setup.bash" \
    "$REPO_ROOT/../../install/local_setup.bash"; do
    if [ -f "$setup_file" ]; then
      source_under_nounset "$setup_file"
      return 0
    fi
  done
}

if [ ! -f "$ROS_SETUP" ]; then
  echo "ROS 2 $ROS_DISTRO_NAME setup file not found: $ROS_SETUP" >&2
  exit 1
fi

if [ ! -f "$ROS2_ZED_WS/install/local_setup.bash" ]; then
  echo "ZED ROS2 workspace is not built. Run scripts/setup_ros2_zed.sh first." >&2
  exit 1
fi

configure_zed_sdk_env
source_under_nounset "$ROS_SETUP"
source_under_nounset "$ROS2_ZED_WS/install/local_setup.bash"
source_local_package_setup

launch_args=(
  "camera_model:=$CAMERA_MODEL"
  "camera_name:=$CAMERA_NAME"
  "publish_tf:=$PUBLISH_TF"
)

if [ -n "${ZED_SERIAL_NUMBER:-}" ]; then
  launch_args+=("serial_number:=$ZED_SERIAL_NUMBER")
fi

if ros2 pkg prefix zed_2i_bringup >/dev/null 2>&1; then
  exec ros2 launch zed_2i_bringup zed2i.launch.py "${launch_args[@]}" "$@"
fi

exec ros2 launch "$REPO_ROOT/launch/zed2i.launch.py" "${launch_args[@]}" "$@"
