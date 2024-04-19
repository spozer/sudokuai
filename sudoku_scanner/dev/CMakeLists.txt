# NOT FOR FLUTTER!

# Version 3.13+ required for linking targets defined in other CMakeLists
cmake_minimum_required(VERSION 3.13)

project(sudoku_scanner LANGUAGES CXX)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
add_compile_definitions(CMAKE_IMAGES_PATH="${CMAKE_CURRENT_SOURCE_DIR}/images")
add_compile_definitions(CMAKE_ASSETS_PATH="${CMAKE_CURRENT_SOURCE_DIR}/../assets")
enable_testing()

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../src ${CMAKE_CURRENT_BINARY_DIR}/sudoku_scanner)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/external)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/src)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/test)

target_compile_definitions(sudoku_scanner PRIVATE DEVMODE)

target_include_directories(sudoku_scanner PUBLIC
	${CMAKE_CURRENT_SOURCE_DIR}/../src
)

target_include_directories(sudoku_scanner_dev PRIVATE 
	${CMAKE_CURRENT_SOURCE_DIR}/../includes
)

target_link_libraries(sudoku_scanner PRIVATE
	opencv_core
	opencv_imgproc
	opencv_imgcodecs
	opencv_highgui
	tensorflowlite_c
)

