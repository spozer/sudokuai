#include <opencv2/imgproc/types_c.h>
#include <tensorflow/lite/c/c_api.h>

#include <cstdint>
#include <cstdio>
#include <memory>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>

#include "detection/grid_detector.hpp"
#include "extraction/grid_extractor.hpp"
#include "extraction/structs/grid.hpp"
#include "sudoku_scanner.h"

const std::string IMAGE_PATH = std::string(CMAKE_IMAGES_PATH) + "/26.jpg";
const std::string MODEL_PATH = std::string(CMAKE_ASSETS_PATH) + "/model.tflite";
const int RESOLUTION = 480;

void print_info() {
    printf("OpenCV %s\n", cv::getVersionString().c_str());
    printf("TensorFlow Lite C %s\n", TfLiteVersion());
#ifdef NDEBUG
    printf("No Debug mode\n");
#else
    printf("Debug mode\n");
#endif
    if (__cplusplus == 202101L)
        printf("C++23\n");
    else if (__cplusplus == 202002L)
        printf("C++20\n");
    else if (__cplusplus == 201703L)
        printf("C++17\n");
    else if (__cplusplus == 201402L)
        printf("C++14\n");
    else if (__cplusplus == 201103L)
        printf("C++11\n");
    else if (__cplusplus == 199711L)
        printf("C++98\n");
    else
        printf("pre-standard C++: %ld\n", __cplusplus);

    printf("\n\n");
}

void print_sudoku_grid(const std::vector<std::uint8_t> &grid) {
    for (int i = 0; i < grid.size(); ++i) {
        if (i % 9 == 0) {
            printf("\n");
        }
        if (i % 27 == 0 && i > 0) {
            printf("-------+-------+-------\n");
        }
        if (i % 3 == 0 && i % 9 > 0) {
            printf(" |");
        }
        if (grid[i] > 0) {
            printf(" %d", grid[i]);
        } else {
            printf(" ·");
        }
    }
    printf("\n");
}

int main() {
    print_info();

    cv::Mat image = cv::imread(IMAGE_PATH);
    int src_width = image.size().width;
    int src_height = image.size().height;

    if (image.empty()) {
        printf("Could not read image %s\n", IMAGE_PATH.c_str());
        return 1;
    }

    // init tflite model
    set_model(MODEL_PATH.c_str());

    // bounding box
    std::unique_ptr<BoundingBox> bb(detect_grid(IMAGE_PATH.c_str()));
    printf("%f %f\n", bb->bottom_left.x, bb->bottom_left.y);

    Grid grid = GridExtractor::extract_grid(
        image,
        bb->top_left.x * image.size().width,
        bb->top_left.y * image.size().height,
        bb->top_right.x * image.size().width,
        bb->top_right.y * image.size().height,
        bb->bottom_left.x * image.size().width,
        bb->bottom_left.y * image.size().height,
        bb->bottom_right.x * image.size().width,
        bb->bottom_right.y * image.size().height);

    // makes copy
    std::vector<std::uint8_t> grid_vec(grid.data, grid.data + grid.size);
    print_sudoku_grid(grid_vec);

    cv::waitKey(0);

    // std::unique_ptr<std::uint8_t> bbroi(extract_grid_from_roi(IMAGE_PATH.c_str(), (src_width < src_height) ? src_width : src_height, 0));
    // std::vector<std::uint8_t> grid2_vec(bbroi.get(), bbroi.get() + 81);
    // print_sudoku_grid(grid2_vec);

    // cv::waitKey(0);

    return 0;
}
