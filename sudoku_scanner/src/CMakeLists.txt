# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(sudoku_scanner_library VERSION 0.0.1 LANGUAGES CXX)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../includes)

add_library(sudoku_scanner SHARED
  ${CMAKE_CURRENT_SOURCE_DIR}/sudoku_scanner.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/detection/grid_detector.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/extraction/grid_extractor.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/extraction/classification/number_classifier.cpp
)

set_target_properties(sudoku_scanner PROPERTIES
  PUBLIC_HEADER sudoku_scanner.hpp
  OUTPUT_NAME "sudoku_scanner"
)

target_compile_definitions(sudoku_scanner PUBLIC DART_SHARED_LIB)
