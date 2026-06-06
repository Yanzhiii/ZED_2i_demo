# ZED 2i Bringup

Minimal ROS 2 Humble package for launching a Stereolabs ZED 2i independently. It is intended to be used next to other ROS 2 projects without modifying them.

Chinese version: [README.md](README.md)

## Goals

- Provide a small ROS 2 package named `zed_2i_bringup`.
- Keep one non-ROS smoke test for validating the camera and local ZED SDK.
- Support integration through a separate overlay workspace.
- Do not commit the local SDK, virtualenv, outputs, logs, absolute local paths, or real camera serial numbers.

## Dependencies

- Ubuntu 22.04 + ROS 2 Humble.
- Local ZED SDK under `sdk/zed`, ignored by Git.
- `.venv` for the non-ROS test only.
- Official Stereolabs ROS 2 wrapper underlay, default: `~/Projects/ros2_zed_ws`.

Prepare the underlay:

```bash
scripts/setup_ros2_zed.sh
```

If apt dependencies are already installed:

```bash
scripts/setup_ros2_zed.sh --skip-apt
```

## Non-ROS Test

```bash
scripts/run_quick_test.sh --frames 30
```

Images are written to `outputs/`, which is ignored by Git.

## ROS 2 Standalone Launch

Build this package:

```bash
source /opt/ros/humble/setup.bash
source ~/Projects/ros2_zed_ws/install/setup.bash
colcon build --symlink-install --packages-select zed_2i_bringup
source install/setup.bash
```

If you use zsh, replace `setup.bash` with `setup.zsh`.

Launch the camera:

```bash
ros2 launch zed_2i_bringup zed2i.launch.py
```

To select a specific camera:

```bash
export ZED_SERIAL_NUMBER=<ZED_SERIAL_NUMBER>
ros2 launch zed_2i_bringup zed2i.launch.py
```

Script shortcut:

```bash
scripts/run_zed_ros2.sh
```

Useful checks:

```bash
ros2 topic hz /zed/zed_node/rgb/color/rect/image
ros2 topic hz /zed/zed_node/depth/depth_registered
ros2 topic hz /zed/zed_node/point_cloud/cloud_registered
```

## Launch API

Main entrypoint:

```bash
ros2 launch zed_2i_bringup zed2i.launch.py
```

Arguments:

- `camera_name`: default `zed`.
- `camera_model`: default `zed2i`.
- `serial_number`: defaults to `ZED_SERIAL_NUMBER`, or `0` if unset.
- `publish_tf`: default `true`.

## Generic Project Integration

Use a separate ZED overlay workspace next to the target project. Do not modify the target project directly:

```bash
mkdir -p ~/Projects/<project>_zed_ws/src
cd ~/Projects/<project>_zed_ws/src
git clone <this-repo-url> zed_2i_bringup
```

Build:

```bash
cd ~/Projects/<project>_zed_ws
source /opt/ros/humble/setup.bash
source ~/Projects/ros2_zed_ws/install/setup.bash
colcon build --symlink-install --packages-select zed_2i_bringup
source install/setup.bash
```

Run it independently: start the target project stack in one terminal, and run `ros2 launch zed_2i_bringup zed2i.launch.py` in another.

See [docs/INTEGRATION.md](docs/INTEGRATION.md) for a generic overlay integration workflow.
