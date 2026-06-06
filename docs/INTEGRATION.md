# 通用对接说明

本文件说明如何把 `zed_2i_bringup` 作为独立 ZED 2i ROS2 bringup 包接入任意 ROS2 Humble 项目。

## 推荐方式

保持 ZED 独立 overlay，不直接修改目标项目：

```bash
mkdir -p ~/Projects/<project>_zed_ws/src
cd ~/Projects/<project>_zed_ws/src
git clone <this-repo-url> zed_2i_bringup
```

也可以在你自己的集成仓库中把本仓库作为 submodule 放到 `src/zed_2i_bringup`。

## 准备 ZED underlay

本包依赖官方 Stereolabs ROS2 wrapper。先在本仓库目录运行：

```bash
scripts/setup_ros2_zed.sh
```

默认会准备 `~/Projects/ros2_zed_ws`。该 workspace 只放官方 ZED wrapper/examples，不属于目标项目。

## 构建项目侧 ZED overlay

```bash
cd ~/Projects/<project>_zed_ws
source /opt/ros/humble/setup.bash
source ~/Projects/ros2_zed_ws/install/setup.bash
colcon build --symlink-install --packages-select zed_2i_bringup
source install/setup.bash
```

如果使用 zsh，把 `setup.bash` 换成 `setup.zsh`。

## 独立运行

终端 A：按目标项目原有流程启动原 stack。

终端 B：启动 ZED 2i：

```bash
cd ~/Projects/<project>_zed_ws
source /opt/ros/humble/setup.bash
source ~/Projects/ros2_zed_ws/install/setup.bash
source install/setup.bash
export ZED_SERIAL_NUMBER=<ZED_SERIAL_NUMBER>
ros2 launch zed_2i_bringup zed2i.launch.py
```

如果只有一台 ZED 相机，`ZED_SERIAL_NUMBER` 可以不设置。

## 验证

```bash
ros2 node list
ros2 topic hz /zed/zed_node/rgb/color/rect/image
ros2 topic hz /zed/zed_node/depth/depth_registered
ros2 topic hz /zed/zed_node/point_cloud/cloud_registered
```

## 当前边界

- 不修改目标项目。
- 不在目标项目 launch 中 include ZED。
- 不做 ZED 数据到目标项目 topic 的桥接。
- 不替换目标项目现有传感器。

后续需要一键启动、topic remap、TF 标定或数据桥接时，再按目标项目的接口单独规划。
