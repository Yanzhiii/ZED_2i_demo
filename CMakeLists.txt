cmake_minimum_required(VERSION 3.8)
project(zed_2i_bringup)

find_package(ament_cmake REQUIRED)

install(
  DIRECTORY docs launch scripts
  DESTINATION share/${PROJECT_NAME}
)

install(
  FILES README.md README.en.md
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
