cmake_minimum_required(VERSION 3.13)

project(sudoku_scanner_dev LANGUAGES CXX)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/shared")

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../includes)

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

add_library(opencv_highgui SHARED IMPORTED)
set_target_properties(opencv_highgui PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/opencv/libopencv_highgui.so)

# Tensorflow Lite
add_library(tensorflowlite_c SHARED IMPORTED)
set_target_properties(tensorflowlite_c PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/tensorflowlite/libtensorflowlite_c.so)

add_executable(sudoku_scanner_dev
	dev.cpp
)

target_link_libraries(sudoku_scanner_dev PRIVATE
	sudoku_scanner
	opencv_core
	opencv_imgproc
	opencv_imgcodecs
	opencv_highgui
	tensorflowlite_c
)
