#include <opencv2/imgproc/types_c.h>
#include <tensorflow/lite/c/c_api.h>

#include <cstdio>
#include <memory>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>

#include "../src/detection/grid_detector.hpp"
#include "../src/extraction/grid_extractor.hpp"
#include "../src/sudoku_scanner.h"

const std::string IMAGE_PATH = "../../test/images/8.jpg";
const std::string MODEL_PATH = "../../assets/model.tflite";
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

void print_sudoku_grid(const std::vector<int> &grid) {
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

    if (image.empty()) {
        printf("Could not read image %s\n", IMAGE_PATH.c_str());
        return 1;
    }

    // init tflite model
    set_model((char *)MODEL_PATH.c_str());

    GridDetector::resize_to_resolution(image, RESOLUTION);

    // bounding box
    std::unique_ptr<BoundingBox> bb(detect_grid((char *)IMAGE_PATH.c_str()));
    printf("%f %f\n", bb->bottom_left.x, bb->bottom_left.y);

    std::vector<cv::Point> pts{
        cv::Point(bb->top_left.x * image.cols, bb->top_left.y * image.rows),
        cv::Point(bb->top_right.x * image.cols, bb->top_right.y * image.rows),
        cv::Point(bb->bottom_right.x * image.cols, bb->bottom_right.y * image.rows),
        cv::Point(bb->bottom_left.x * image.cols, bb->bottom_left.y * image.rows)};

    std::vector<int> grid = GridExtractor::extract_grid(
        image,
        bb->top_left.x * image.size().width,
        bb->top_left.y * image.size().height,
        bb->top_right.x * image.size().width,
        bb->top_right.y * image.size().height,
        bb->bottom_left.x * image.size().width,
        bb->bottom_left.y * image.size().height,
        bb->bottom_right.x * image.size().width,
        bb->bottom_right.y * image.size().height);

    print_sudoku_grid(grid);

    cv::waitKey(0);

    std::unique_ptr<int> bbroi(extract_grid_from_roi((char *)IMAGE_PATH.c_str(), 2160, 0));
    std::vector<int> grid2(bbroi.get(), bbroi.get() + 81);

    print_sudoku_grid(grid2);

    cv::waitKey(0);

    return 0;
}
