# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.13)

# Project-level configuration.
set(PROJECT_NAME "sudoku_scanner")
project(${PROJECT_NAME} LANGUAGES CXX)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/shared")

# OpenCV
add_library(opencv SHARED IMPORTED)
set_target_properties(opencv PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

# Tensorflow Lite
add_library(tensorflowlite_c SHARED IMPORTED)
set_target_properties(tensorflowlite_c PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libtensorflowlite_jni.so)

add_library(tensorflowlite_gpu SHARED IMPORTED)
set_target_properties(tensorflowlite_gpu PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libtensorflowlite_gpu_jni.so)

# Android Log
find_library(log-lib log)

target_link_libraries(sudoku_scanner opencv tensorflowlite_c tensorflowlite_gpu ${log-lib})

