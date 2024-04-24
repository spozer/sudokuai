cmake_minimum_required(VERSION 3.13)

project(external LANGUAGES CXX)

# OpenCV
add_library(opencv_core SHARED IMPORTED GLOBAL)
set_target_properties(opencv_core PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/opencv/libopencv_core.so)

add_library(opencv_imgproc SHARED IMPORTED GLOBAL)
set_target_properties(opencv_imgproc PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/opencv/libopencv_imgproc.so)

add_library(opencv_imgcodecs SHARED IMPORTED GLOBAL)
set_target_properties(opencv_imgcodecs PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/opencv/libopencv_imgcodecs.so)

add_library(opencv_highgui SHARED IMPORTED GLOBAL)
set_target_properties(opencv_highgui PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/opencv/libopencv_highgui.so)

add_library(opencv_calib3d SHARED IMPORTED GLOBAL)
set_target_properties(opencv_calib3d PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/opencv/libopencv_calib3d.so)

add_library(opencv_features2d SHARED IMPORTED GLOBAL)
set_target_properties(opencv_features2d PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/opencv/libopencv_features2d.so)

add_library(opencv_flann SHARED IMPORTED GLOBAL)
set_target_properties(opencv_flann PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/opencv/libopencv_flann.so)

# Tensorflow Lite
add_library(tensorflowlite_c SHARED IMPORTED GLOBAL)
set_target_properties(tensorflowlite_c PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/tensorflowlite/libtensorflowlite_c.so)

add_library(tensorflowlite_gpu SHARED IMPORTED GLOBAL)
set_target_properties(tensorflowlite_gpu PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/tensorflowlite/libtensorflowlite_gpu_delegate.so)

