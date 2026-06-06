#!/usr/bin/env python3
"""Launch the official ZED ROS 2 wrapper for a ZED 2i camera."""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import EnvironmentVariable, LaunchConfiguration, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    camera_name = LaunchConfiguration('camera_name')
    camera_model = LaunchConfiguration('camera_model')
    serial_number = LaunchConfiguration('serial_number')
    publish_tf = LaunchConfiguration('publish_tf')

    zed_wrapper_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            PathJoinSubstitution([
                FindPackageShare('zed_wrapper'),
                'launch',
                'zed_camera.launch.py',
            ])
        ),
        launch_arguments={
            'camera_name': camera_name,
            'camera_model': camera_model,
            'serial_number': serial_number,
            'publish_tf': publish_tf,
        }.items(),
    )

    return LaunchDescription([
        DeclareLaunchArgument(
            'camera_name',
            default_value='zed',
            description='Camera namespace/name used by zed_wrapper.',
        ),
        DeclareLaunchArgument(
            'camera_model',
            default_value='zed2i',
            description='ZED camera model passed to zed_wrapper.',
        ),
        DeclareLaunchArgument(
            'serial_number',
            default_value=EnvironmentVariable('ZED_SERIAL_NUMBER', default_value='0'),
            description='Camera serial number. Defaults to ZED_SERIAL_NUMBER or 0.',
        ),
        DeclareLaunchArgument(
            'publish_tf',
            default_value='true',
            description='Pass-through for zed_wrapper publish_tf.',
        ),
        zed_wrapper_launch,
    ])
