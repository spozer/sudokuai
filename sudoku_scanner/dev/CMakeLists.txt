cmake_minimum_required(VERSION 3.13)

project(sudoku_scanner_dev LANGUAGES CXX)

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../linux" "${CMAKE_CURRENT_BINARY_DIR}/sudoku_scanner")

target_compile_definitions(sudoku_scanner PRIVATE DEVMODE)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../includes)

# OpenCV
add_library(opencv_highgui SHARED IMPORTED)
set_target_properties(opencv_highgui PROPERTIES
	IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../linux/libs/opencv/libopencv_highgui.so)

add_executable(
	sudoku_scanner_dev
	dev.cpp
)

target_link_libraries(
	sudoku_scanner_dev PRIVATE
	opencv_highgui
	sudoku_scanner
)
