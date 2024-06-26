#include "sudoku_scanner.h"

#include <cassert>
#include <cstdint>
#include <new>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <vector>

#include "detection/grid_detector.hpp"
#include "dictionary/dictionary.hpp"
#include "extraction/grid_extractor.hpp"
#include "extraction/structs/cell.hpp"
#include "extraction/structs/grid.hpp"

BoundingBox *detect_grid(const char *path) {
    BoundingBox *bb_ptr = new BoundingBox();
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
std::uint8_t *extract_grid(const char *path, const BoundingBox *bounding_box) {
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

    Grid grid = GridExtractor::extract_grid(
        mat,
        bounding_box->top_left.x * mat.size().width,
        bounding_box->top_left.y * mat.size().height,
        bounding_box->top_right.x * mat.size().width,
        bounding_box->top_right.y * mat.size().height,
        bounding_box->bottom_left.x * mat.size().width,
        bounding_box->bottom_left.y * mat.size().height,
        bounding_box->bottom_right.x * mat.size().width,
        bounding_box->bottom_right.y * mat.size().height);

    return grid.get_ownership();
}

// TODO: try get image as byte array directly from dart
std::uint8_t *extract_grid_from_roi(
    const char *path,
    std::int32_t roi_size,
    // offset from center of image
    std::int32_t roi_offset) {
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

    Grid grid = GridExtractor::extract_grid(
        image_copy,
        points[0].x,
        points[0].y,
        points[1].x,
        points[1].y,
        points[2].x,
        points[2].y,
        points[3].x,
        points[3].y);

    return grid.get_ownership();
}

void set_model(const char *path) {
    setenv(PATH_TO_MODEL_ENV_VAR, path, 1);
}

void free_pointer(void *pointer) {
    free(pointer);
}
