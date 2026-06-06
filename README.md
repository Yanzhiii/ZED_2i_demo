# ZED 2i Bringup

轻量 ROS2 Humble 包，用于单独启动 Stereolabs ZED 2i，并为后续接入其他 ROS2 项目做准备。

English version: [README.en.md](README.en.md)

## 目标

- 提供一个最小 ROS2 package：`zed_2i_bringup`。
- 保留一个非 ROS2 smoke test，方便先验证 ZED SDK、USB、权限和深度链路。
- 其他项目只通过独立 workspace 对接；本仓库不修改外部项目。
- 不提交本地 SDK、虚拟环境、输出图片、日志、本机绝对路径或真实相机序列号。

## 依赖

- Ubuntu 22.04 + ROS2 Humble。
- ZED SDK 本地目录：`sdk/zed`，不提交到 Git。
- Python 虚拟环境 `.venv`，用于非 ROS2 测试，不参与 ROS2 构建。
- 官方 Stereolabs ROS2 wrapper underlay：默认位于 `~/Projects/ros2_zed_ws`。

准备官方 underlay：

```bash
scripts/setup_ros2_zed.sh
```

如果系统依赖已安装，只重建 underlay：

```bash
scripts/setup_ros2_zed.sh --skip-apt
```

## 非 ROS2 测试

用于确认相机和 ZED SDK 正常：

```bash
scripts/run_quick_test.sh --frames 30
```

输出文件写入 `outputs/`，该目录不会提交到 Git。

## ROS2 独立启动

在当前仓库作为 workspace 构建：

```bash
source /opt/ros/humble/setup.bash
source ~/Projects/ros2_zed_ws/install/setup.bash
colcon build --symlink-install --packages-select zed_2i_bringup
source install/setup.bash
```

如果使用 zsh，把 `setup.bash` 换成 `setup.zsh`。

启动 ZED 2i：

```bash
ros2 launch zed_2i_bringup zed2i.launch.py
```

如果需要固定相机：

```bash
export ZED_SERIAL_NUMBER=<ZED_SERIAL_NUMBER>
ros2 launch zed_2i_bringup zed2i.launch.py
```

也可以用脚本启动：

```bash
scripts/run_zed_ros2.sh
```

常用检查：

```bash
ros2 topic hz /zed/zed_node/rgb/color/rect/image
ros2 topic hz /zed/zed_node/depth/depth_registered
ros2 topic hz /zed/zed_node/point_cloud/cloud_registered
```

## Launch 接口

主入口：

```bash
ros2 launch zed_2i_bringup zed2i.launch.py
```

参数：

- `camera_name`：默认 `zed`。
- `camera_model`：默认 `zed2i`。
- `serial_number`：默认读取 `ZED_SERIAL_NUMBER`，未设置时为 `0`。
- `publish_tf`：默认 `true`。

## 通用项目对接

推荐在目标项目旁边创建独立 ZED overlay，不直接修改目标项目：

```bash
mkdir -p ~/Projects/<project>_zed_ws/src
cd ~/Projects/<project>_zed_ws/src
git clone <this-repo-url> zed_2i_bringup
```

构建：

```bash
cd ~/Projects/<project>_zed_ws
source /opt/ros/humble/setup.bash
source ~/Projects/ros2_zed_ws/install/setup.bash
colcon build --symlink-install --packages-select zed_2i_bringup
source install/setup.bash
```

运行时保持独立：一个终端启动目标项目原有 stack，另一个终端启动 `ros2 launch zed_2i_bringup zed2i.launch.py`。

更完整的通用 overlay 对接说明见 [docs/INTEGRATION.md](docs/INTEGRATION.md)。

## 项目结构

- `package.xml` / `CMakeLists.txt`：最小 ROS2 package。
- `launch/zed2i.launch.py`：include 官方 `zed_wrapper` 的 ZED 2i launch。
- `src/zed_quick_test.py`：非 ROS2 smoke test。
- `scripts/setup_ros2_zed.sh`：准备官方 ZED ROS2 underlay。
- `scripts/run_zed_ros2.sh`：脚本方式启动 ROS2。
- `scripts/run_quick_test.sh`：脚本方式运行非 ROS2 测试。
- `scripts/check_connection.sh`：检查 USB、权限、GPU 和 SDK。
- `resources/system_rules/`：ZED udev/sysctl 规则备份。

## 故障排查

```bash
scripts/check_connection.sh
```

如果遇到权限问题：

```bash
scripts/apply_system_rules.sh
```

然后拔插相机或重新登录。

ROS2 构建时不要让 `.venv` 接管 Python。`scripts/setup_ros2_zed.sh` 会刻意避开 `.venv`，并默认使用 `/usr/bin/python3`。
