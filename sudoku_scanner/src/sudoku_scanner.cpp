#include "sudoku_scanner.h"

#include <cassert>
#include <cstdlib>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <vector>

#include "detection/grid_detector.hpp"
#include "dictionary/dictionary.hpp"
#include "extraction/grid_extractor.hpp"
#include "extraction/structs/cell.hpp"

BoundingBox *detect_grid(char *path) {
    BoundingBox *bb_ptr = (BoundingBox *)std::malloc(sizeof(BoundingBox));
    cv::Mat mat = cv::imread(path);
    int width = mat.size().width;
    int height = mat.size().height;

    if (width == 0 || height == 0) {
        return bb_ptr;
    }

    std::vector<cv::Point> points = GridDetector::detect_grid(mat);

    bb_ptr->top_left.x = static_cast<double>(points[0].x) / width;
    bb_ptr->top_left.y = static_cast<double>(points[0].y) / height;
    bb_ptr->top_right.x = static_cast<double>(points[1].x) / width;
    bb_ptr->top_right.y = static_cast<double>(points[1].y) / height;
    bb_ptr->bottom_left.x = static_cast<double>(points[2].x) / width;
    bb_ptr->bottom_left.y = static_cast<double>(points[2].y) / height;
    bb_ptr->bottom_right.x = static_cast<double>(points[3].x) / width;
    bb_ptr->bottom_right.y = static_cast<double>(points[3].y) / height;

    return bb_ptr;
}

// TODO: try get image as byte array directly from dart
int *extract_grid(char *path, BoundingBox *bounding_box) {
    assert(bounding_box->top_left.x >= 0 && bounding_box->top_left.y >= 0);
    assert(bounding_box->top_right.x > 0 && bounding_box->top_right.y >= 0);
    assert(bounding_box->bottom_left.x >= 0 && bounding_box->bottom_left.y > 0);
    assert(bounding_box->bottom_right.x > 0 && bounding_box->bottom_right.y > 0);
    assert(bounding_box->top_left.x <= bounding_box->top_right.x);
    assert(bounding_box->top_left.x <= bounding_box->bottom_right.x);
    assert(bounding_box->top_left.y <= bounding_box->bottom_left.y);
    assert(bounding_box->top_left.y <= bounding_box->bottom_right.y);
    assert(bounding_box->bottom_left.x <= bounding_box->top_right.x);
    assert(bounding_box->bottom_left.x <= bounding_box->bottom_right.x);
    assert(bounding_box->top_right.y <= bounding_box->bottom_left.y);
    assert(bounding_box->top_right.y <= bounding_box->bottom_right.y);

    cv::Mat mat = cv::imread(path);

    std::vector<int> grid = GridExtractor::extract_grid(
        mat,
        bounding_box->top_left.x * mat.size().width,
        bounding_box->top_left.y * mat.size().height,
        bounding_box->top_right.x * mat.size().width,
        bounding_box->top_right.y * mat.size().height,
        bounding_box->bottom_left.x * mat.size().width,
        bounding_box->bottom_left.y * mat.size().height,
        bounding_box->bottom_right.x * mat.size().width,
        bounding_box->bottom_right.y * mat.size().height);
    mat.release();

    // TODO: use uint8_t instead of 32-bit int
    int *grid_ptr = (int *)std::malloc(grid.size() * sizeof(int));

    // copy grid_array to pointer
    for (int i = 0; i < grid.size(); ++i) {
        grid_ptr[i] = grid[i];
    }

    return grid_ptr;
}

// TODO: try get image as byte array directly from dart
int *extract_grid_from_roi(
    char *path,
    int roi_size,
    // offset from center of image
    int roi_offset) {
    cv::Mat image = cv::imread(path);

    assert(roi_size > 0 && roi_size <= image.size().width);
    assert(abs(roi_offset) <= (image.size().height - roi_size) / 2);

    // get position of top left corner
    const int offset_w = (image.size().width - roi_size) / 2;
    const int offset_h = roi_offset + (image.size().height - roi_size) / 2;
    // get roi as rectangle
    const cv::Rect roi(offset_w, offset_h, roi_size, roi_size);

    // crop image so it only contains ROI
    image = image(roi);
    cv::Mat image_copy = image.clone();

    std::vector<cv::Point> points = GridDetector::detect_grid(image);
    image.release();

    std::vector<int> grid = GridExtractor::extract_grid(
        image_copy,
        points[0].x,
        points[0].y,
        points[1].x,
        points[1].y,
        points[2].x,
        points[2].y,
        points[3].x,
        points[3].y);
    image_copy.release();

    // TODO: use uint8_t instead of 32-bit int
    int *grid_ptr = (int *)std::malloc(grid.size() * sizeof(int));

    // copy grid_array to pointer
    for (int i = 0; i < grid.size(); ++i) {
        grid_ptr[i] = grid[i];
    }

    return grid_ptr;
}

void set_model(char *path) {
    setenv(PATH_TO_MODEL_ENV_VAR, path, 1);
}

void free_pointer(int *pointer) {
    free(pointer);
}
