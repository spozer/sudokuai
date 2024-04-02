# NOT FOR FLUTTER!

# Version 3.13+ required for linking targets defined in other CMakeLists
cmake_minimum_required(VERSION 3.13)

project(sudoku_scanner LANGUAGES CXX)

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/sudoku_scanner")

# OpenCV
add_library(opencv_core SHARED IMPORTED)
set_target_properties(opencv_core PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/opencv/libopencv_core.so)

add_library(opencv_imgproc SHARED IMPORTED)
set_target_properties(opencv_imgproc PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/opencv/libopencv_imgproc.so)

add_library(opencv_imgcodecs SHARED IMPORTED)
set_target_properties(opencv_imgcodecs PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/opencv/libopencv_imgcodecs.so)

# Tensorflow Lite
add_library(tensorflowlite_c SHARED IMPORTED)
set_target_properties(tensorflowlite_c PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/tensorflowlite/libtensorflowlite_c.so)

target_link_libraries(
    sudoku_scanner
	opencv_core
	opencv_imgproc
	opencv_imgcodecs
	tensorflowlite_c
)
