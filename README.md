# ZED 2i Demo

本项目用于在本机跑通 ZED 2i，并保留一个最小 Python 采集 demo。

## 当前状态

- 相机：ZED 2i，SN `37970765`
- SDK：ZED SDK `5.2.3`，本地安装在 `sdk/zed`
- Python：`.venv` 内已安装 `pyzed 5.2`、`opencv-python`、`numpy`
- 验证结果：`HD720@30` 打开成功，RGB/depth 采集 `30/30` 帧成功
- 输出文件：`outputs/zed_left.png`、`outputs/zed_depth.png`

## 快速运行

```bash
source .venv/bin/activate
source scripts/setup_env.sh
python src/zed_quick_test.py --frames 30
```

或直接运行：

```bash
scripts/run_quick_test.sh --frames 30
```

默认深度模式是 `NEURAL`。如果只想快速验证链路，可用较轻的模式：

```bash
scripts/run_quick_test.sh --frames 30 --depth-mode PERFORMANCE
```

## 项目结构

- `src/zed_quick_test.py`：最小 ZED Python demo，打开相机、抓帧、保存 RGB 和 depth preview。
- `scripts/setup_env.sh`：设置 `ZED_DIR`、`LD_LIBRARY_PATH`、虚拟环境 `PATH`。
- `scripts/check_connection.sh`：检查 USB、视频节点、ZED USB 权限、GPU 和本地 SDK。
- `scripts/run_zed_explorer.sh`：启动官方图像查看工具。
- `scripts/run_zed_depth_viewer.sh`：启动官方深度查看工具。
- `scripts/run_zed_diagnostic.sh`：启动官方诊断工具。
- `scripts/apply_system_rules.sh`：重新应用 ZED udev/sysctl/ldconfig 系统规则。
- `sdk/zed/`：本地 ZED SDK、官方工具、官方 samples 和本地 API 文档。
- `resources/system_rules/`：保留下来的 ZED udev/sysctl 规则文件。
- `outputs/`：demo 生成的图片，可随时删除。

## 建议阅读顺序

1. 先读 `src/zed_quick_test.py`，重点看 `InitParameters`、`camera.open()`、`camera.grab()`、`retrieve_image()`、`retrieve_measure()`。
2. 再跑 `scripts/check_connection.sh`，理解 ZED 2i 同时暴露 USB video 设备和 HID/MCU 控制设备。
3. 用 `scripts/run_zed_explorer.sh` 看原始左右目图像，用 `scripts/run_zed_depth_viewer.sh` 看 SDK 深度效果。
4. 打开 `sdk/zed/doc/API/Documentation_Python.html`，查 `sl.Camera`、`sl.InitParameters`、`sl.RuntimeParameters`、`sl.Mat`。
5. 看官方示例目录：`sdk/zed/samples/depth sensing`、`sdk/zed/samples/positional tracking`、`sdk/zed/samples/object detection`。

## 建立初步认知

- ZED 2i 本质是双目相机 + IMU/MCU；图像走 UVC/video，传感器和控制走 HID/USB。
- SDK 的基本循环是：配置 `InitParameters`，`open()` 相机，循环 `grab()`，再按需取 image/depth/point cloud。
- RGB 图像来自 `retrieve_image(..., sl.VIEW.LEFT)`；深度来自 `retrieve_measure(..., sl.MEASURE.DEPTH)`。
- 深度模式影响速度和质量；SDK 5.x 推荐 `NEURAL`，快速链路测试可以用 `PERFORMANCE`。
- 标定文件会按相机序列号下载并缓存；本机已有 `sdk/zed/settings/SN37970765.conf`。

## 故障排查

```bash
scripts/check_connection.sh
```

如果出现 `Permissions denied : can't open device` 或 `NOT VALID SERIAL NUMBER FOR SENSORS MODULE MCU`：

```bash
scripts/apply_system_rules.sh
# 然后拔插相机，或重启登录会话
```

如果仍有 MCU/serial 相关错误：

```bash
scripts/run_zed_diagnostic.sh -r
```
