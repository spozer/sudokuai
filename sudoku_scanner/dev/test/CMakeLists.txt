cmake_minimum_required(VERSION 3.14)
project(sudoku_scanner_test LANGUAGES CXX)

# GoogleTest requires at least C++14
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
FetchContent_Declare(
	googletest
	URL https://github.com/google/googletest/archive/03597a01ee50ed33e9dfd640b249b4be3799d395.zip
	DOWNLOAD_EXTRACT_TIMESTAMP OFF
)

FetchContent_MakeAvailable(googletest)

add_executable(
	integration_test
	integration_test.cpp
)

target_link_libraries(
	integration_test
	GTest::gtest_main
	sudoku_scanner
)

include(GoogleTest)
gtest_discover_tests(integration_test)
