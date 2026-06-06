#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROS_DISTRO_NAME="${ROS_DISTRO_NAME:-humble}"
ROS_SETUP="/opt/ros/$ROS_DISTRO_NAME/setup.bash"
ROS2_ZED_WS="${ROS2_ZED_WS:-"$HOME/Projects/ros2_zed_ws"}"
ZED_WRAPPER_VERSION="${ZED_WRAPPER_VERSION:-v5.3.1}"
ZED_EXAMPLES_VERSION="${ZED_EXAMPLES_VERSION:-v5.3.1}"

INSTALL_APT=1
RUN_BUILD=1
RUN_ROSDEP=1

APT_HINT_PACKAGES=(
  "ros-$ROS_DISTRO_NAME-zed-msgs"
  "ros-$ROS_DISTRO_NAME-zed-description"
  "ros-$ROS_DISTRO_NAME-grid-map-rviz-plugin"
  "ros-$ROS_DISTRO_NAME-nmea-msgs"
  "ros-$ROS_DISTRO_NAME-geographic-msgs"
  "ros-$ROS_DISTRO_NAME-robot-localization"
  "ros-$ROS_DISTRO_NAME-ament-cmake-clang-format"
)

usage() {
  cat <<'USAGE'
Usage: scripts/setup_ros2_zed.sh [--skip-apt] [--skip-rosdep] [--skip-build]

Environment:
  ROS2_ZED_WS           Workspace path, default: ~/Projects/ros2_zed_ws
  ZED_WRAPPER_VERSION   zed-ros2-wrapper tag, default: v5.3.1
  ZED_EXAMPLES_VERSION  zed-ros2-examples tag, default: v5.3.1
  ROS_PYTHON_EXECUTABLE ROS-compatible Python, default: /usr/bin/python3
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-apt)
      INSTALL_APT=0
      ;;
    --skip-build)
      RUN_BUILD=0
      ;;
    --skip-rosdep)
      RUN_ROSDEP=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

display_path() {
  local path="$1"
  if [[ "$path" == "$HOME" ]]; then
    printf '~'
  elif [[ "$path" == "$HOME/"* ]]; then
    printf '~/%s' "${path#"$HOME/"}"
  elif [[ "$path" == "$REPO_ROOT" ]]; then
    printf '<repo>'
  elif [[ "$path" == "$REPO_ROOT/"* ]]; then
    printf '<repo>/%s' "${path#"$REPO_ROOT/"}"
  else
    printf '%s' "$path"
  fi
}

sanitize_output() {
  sed -e "s#${HOME}#~#g" -e "s#${REPO_ROOT}#<repo>#g"
}

run_sanitized() {
  "$@" 2>&1 | sanitize_output
}

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

missing_apt_packages() {
  local package
  for package in "${APT_HINT_PACKAGES[@]}"; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
      printf '%s\n' "$package"
    fi
  done
}

ensure_sudo_for_missing_packages() {
  local missing_packages=("$@")

  if [ "${#missing_packages[@]}" -eq 0 ]; then
    return 0
  fi

  if sudo -n true >/dev/null 2>&1; then
    return 0
  fi

  if [ -t 0 ]; then
    sudo -v
    return 0
  fi

  echo "Missing ROS apt dependencies and sudo needs an interactive password." >&2
  echo "Run this manually, then rerun scripts/setup_ros2_zed.sh --skip-apt:" >&2
  printf '  sudo apt update && sudo apt install -y' >&2
  printf ' %q' "${missing_packages[@]}" >&2
  printf '\n' >&2
  exit 1
}

source_under_nounset() {
  set +u
  # shellcheck source=/dev/null
  source "$1"
  set -u
}

clone_or_checkout() {
  local repo_url="$1"
  local target_dir="$2"
  local version="$3"

  if [ ! -d "$target_dir/.git" ]; then
    echo "Cloning $(basename "$target_dir")@$version into $(display_path "$target_dir")"
    run_sanitized git clone --quiet "$repo_url" "$target_dir"
  else
    echo "Updating $(basename "$target_dir") to $version"
    run_sanitized git -C "$target_dir" fetch --quiet --tags origin
  fi

  run_sanitized git -C "$target_dir" checkout --quiet "$version"
}

if [ ! -f "$ROS_SETUP" ]; then
  echo "ROS 2 $ROS_DISTRO_NAME setup file not found: $ROS_SETUP" >&2
  exit 1
fi

configure_zed_sdk_env

echo "ROS workspace: $(display_path "$ROS2_ZED_WS")"
echo "ZED SDK: $(display_path "$ZED_DIR")"
echo "Wrapper: $ZED_WRAPPER_VERSION"
echo "Examples: $ZED_EXAMPLES_VERSION"

if [ "$INSTALL_APT" -eq 1 ]; then
  mapfile -t missing_packages < <(missing_apt_packages)
  ensure_sudo_for_missing_packages "${missing_packages[@]}"

  if dpkg -s "ros-$ROS_DISTRO_NAME-zed-msgs" >/dev/null 2>&1; then
    echo "APT package ros-$ROS_DISTRO_NAME-zed-msgs already installed"
  else
    echo "Installing ros-$ROS_DISTRO_NAME-zed-msgs from ROS apt"
    run_sanitized sudo apt update
    run_sanitized sudo apt install -y "ros-$ROS_DISTRO_NAME-zed-msgs"
  fi
fi

mkdir -p "$ROS2_ZED_WS/src"

clone_or_checkout \
  https://github.com/stereolabs/zed-ros2-wrapper.git \
  "$ROS2_ZED_WS/src/zed-ros2-wrapper" \
  "$ZED_WRAPPER_VERSION"

clone_or_checkout \
  https://github.com/stereolabs/zed-ros2-examples.git \
  "$ROS2_ZED_WS/src/zed-ros2-examples" \
  "$ZED_EXAMPLES_VERSION"

if [ "$RUN_BUILD" -eq 0 ]; then
  echo "Build skipped"
  exit 0
fi

source_under_nounset "$ROS_SETUP"

ROS_PYTHON_EXECUTABLE="${ROS_PYTHON_EXECUTABLE:-/usr/bin/python3}"
if ! "$ROS_PYTHON_EXECUTABLE" -c 'import catkin_pkg' >/dev/null 2>&1; then
  echo "ROS Python is missing catkin_pkg: $ROS_PYTHON_EXECUTABLE" >&2
  echo "Install python3-catkin-pkg or set ROS_PYTHON_EXECUTABLE to a ROS-compatible Python." >&2
  exit 1
fi

CUDA_TOOLKIT_ROOT_DIR="${CUDA_TOOLKIT_ROOT_DIR:-}"
if [ -z "$CUDA_TOOLKIT_ROOT_DIR" ] && command -v nvcc >/dev/null 2>&1; then
  CUDA_TOOLKIT_ROOT_DIR="$(cd "$(dirname "$(readlink -f "$(command -v nvcc)")")/.." && pwd)"
fi

cmake_args=(
  -DCMAKE_BUILD_TYPE=Release
  -DZED_DIR="$ZED_DIR"
  "-DPYTHON_EXECUTABLE=$ROS_PYTHON_EXECUTABLE"
  "-DPython3_EXECUTABLE=$ROS_PYTHON_EXECUTABLE"
  --log-level=WARNING
)
if [ -n "$CUDA_TOOLKIT_ROOT_DIR" ]; then
  cmake_args+=("-DCUDA_TOOLKIT_ROOT_DIR=$CUDA_TOOLKIT_ROOT_DIR")
fi

echo "Installing ROS dependencies for wrapper and RViz display package"
if [ "$RUN_ROSDEP" -eq 1 ]; then
  mapfile -t missing_packages < <(missing_apt_packages)
  ensure_sudo_for_missing_packages "${missing_packages[@]}"
  run_sanitized rosdep install \
    --from-paths "$ROS2_ZED_WS/src/zed-ros2-wrapper" "$ROS2_ZED_WS/src/zed-ros2-examples/zed_display_rviz2" \
    --ignore-src -r -y
else
  echo "rosdep skipped"
fi

echo "Building zed_display_rviz2 dependency chain"
(
  cd "$ROS2_ZED_WS"
  run_sanitized colcon build \
    --symlink-install \
    --packages-up-to zed_display_rviz2 \
    --packages-skip zed_debug \
    --cmake-args "${cmake_args[@]}"
)

echo "ROS2 ZED workspace is ready: $(display_path "$ROS2_ZED_WS")"
