cmake_minimum_required(VERSION 3.13)

project(sudoku_scanner_dev LANGUAGES CXX)

add_executable(
	sudoku_scanner_dev
	main.cpp
)

target_link_libraries(
	sudoku_scanner_dev PRIVATE
	sudoku_scanner
	opencv_core
	opencv_imgproc
	opencv_imgcodecs
	opencv_highgui
	tensorflowlite_c
)
