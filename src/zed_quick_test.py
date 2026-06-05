#!/usr/bin/env python3
import argparse
from pathlib import Path
import sys

import cv2
import numpy as np
import pyzed.sl as sl


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Minimal ZED 2i RGB/depth smoke test.")
    parser.add_argument("--frames", type=int, default=30, help="Number of frames to grab.")
    parser.add_argument("--output-dir", default="outputs", help="Directory for saved images.")
    parser.add_argument(
        "--depth-mode",
        default="NEURAL",
        choices=["NEURAL", "NEURAL_LIGHT", "NEURAL_PLUS", "PERFORMANCE", "QUALITY", "ULTRA"],
        help="Depth mode. NEURAL is the SDK 5.x recommended default.",
    )
    parser.add_argument("--no-depth", action="store_true", help="Only grab RGB frames.")
    return parser.parse_args()


def normalize_depth(depth_array: np.ndarray) -> np.ndarray:
    finite_mask = np.isfinite(depth_array) & (depth_array > 0)
    if not np.any(finite_mask):
        return np.zeros(depth_array.shape, dtype=np.uint8)

    valid_depth = depth_array[finite_mask]
    lower_bound = np.percentile(valid_depth, 1)
    upper_bound = np.percentile(valid_depth, 99)
    if upper_bound <= lower_bound:
        upper_bound = lower_bound + 1.0

    clipped_depth = np.clip(depth_array, lower_bound, upper_bound)
    normalized_depth = (255.0 * (clipped_depth - lower_bound) / (upper_bound - lower_bound))
    normalized_depth[~finite_mask] = 0
    return normalized_depth.astype(np.uint8)


def main() -> int:
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    camera = sl.Camera()
    init_parameters = sl.InitParameters()
    init_parameters.camera_resolution = sl.RESOLUTION.HD720
    init_parameters.camera_fps = 30
    init_parameters.coordinate_units = sl.UNIT.METER
    init_parameters.sdk_verbose = 1
    init_parameters.depth_mode = sl.DEPTH_MODE.NONE if args.no_depth else getattr(sl.DEPTH_MODE, args.depth_mode)

    open_status = camera.open(init_parameters)
    if open_status != sl.ERROR_CODE.SUCCESS:
        print(f"Failed to open ZED camera: {open_status}", file=sys.stderr)
        print("Run scripts/check_connection.sh and read README.md troubleshooting notes.", file=sys.stderr)
        return 2

    try:
        camera_info = camera.get_camera_information()
        camera_config = camera_info.camera_configuration
        print(f"SDK version: {camera.get_sdk_version()}")
        print(f"Camera model: {camera_info.camera_model}")
        print(f"Serial number: {camera_info.serial_number}")
        print(f"Resolution: {camera_config.resolution.width}x{camera_config.resolution.height}")
        print(f"FPS: {camera_config.fps}")

        runtime_parameters = sl.RuntimeParameters()
        left_image = sl.Mat()
        depth_measure = sl.Mat()
        successful_grabs = 0

        for frame_index in range(args.frames):
            grab_status = camera.grab(runtime_parameters)
            if grab_status != sl.ERROR_CODE.SUCCESS:
                print(f"Frame {frame_index}: {grab_status}")
                continue
            successful_grabs += 1
            camera.retrieve_image(left_image, sl.VIEW.LEFT)
            if not args.no_depth:
                camera.retrieve_measure(depth_measure, sl.MEASURE.DEPTH)

        if successful_grabs == 0:
            print("No frames grabbed successfully.", file=sys.stderr)
            return 3

        left_array = left_image.get_data()
        if left_array.ndim == 3 and left_array.shape[2] == 4:
            left_bgr = cv2.cvtColor(left_array, cv2.COLOR_BGRA2BGR)
        else:
            left_bgr = left_array
        left_path = output_dir / "zed_left.png"
        cv2.imwrite(str(left_path), left_bgr)
        print(f"Saved RGB frame: {left_path}")

        if not args.no_depth:
            depth_array = depth_measure.get_data()
            depth_path = output_dir / "zed_depth.png"
            cv2.imwrite(str(depth_path), normalize_depth(depth_array))
            finite_depth = depth_array[np.isfinite(depth_array) & (depth_array > 0)]
            if finite_depth.size:
                print(f"Depth median: {float(np.median(finite_depth)):.3f} m")
            print(f"Saved depth preview: {depth_path}")

        print(f"Successful grabs: {successful_grabs}/{args.frames}")
        return 0
    finally:
        camera.close()


if __name__ == "__main__":
    raise SystemExit(main())
