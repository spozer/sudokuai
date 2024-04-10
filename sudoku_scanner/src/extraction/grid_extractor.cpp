#include "grid_extractor.hpp"

#include <opencv2/imgproc.hpp>
#include <vector>

#include "classification/number_classifier.hpp"

#ifdef DEVMODE
#include <opencv2/highgui.hpp>
#endif

const int GRID_SIZE = 450;
const int CELL_SIZE = GRID_SIZE / 9;

std::vector<int> GridExtractor::extract_grid(cv::Mat &img, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    cv::Mat thresholded;
    cv::cvtColor(img, img, cv::COLOR_BGR2GRAY);
    crop_and_transform(img, x1, y1, x2, y2, x3, y3, x4, y4);
    cv::pyrDown(img, thresholded);
    cv::pyrUp(thresholded, thresholded);
    // cv::adaptiveThreshold(thresholded, thresholded, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 69, 20);
    // cv::adaptiveThreshold(thresholded, thresholded, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 63, 10);
    cv::adaptiveThreshold(thresholded, thresholded, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 53, 10);
#ifdef DEVMODE
    cv::imshow("transformed + thresholded", thresholded);
#endif
    remove_grid_lines(thresholded);
#ifdef DEVMODE
    cv::imshow("thresholded (grid extraction)", thresholded);
#endif
    std::vector<Cell> cells = extract_cells(thresholded, img);
#ifdef DEVMODE
    cv::imshow("cells", stitch_cells(cells));
#endif
    NumberClassifier::predict_numbers(cells);

    return cells_to_array(cells);
}

void GridExtractor::crop_and_transform(cv::Mat &img, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    std::vector<cv::Point2f> dst_pts{
        cv::Point2f(0, 0),
        cv::Point2f(GRID_SIZE - 1, 0),
        cv::Point2f(0, GRID_SIZE - 1),
        cv::Point2f(GRID_SIZE - 1, GRID_SIZE - 1)};

    std::vector<cv::Point2f> img_pts{
        cv::Point2f(x1, y1),
        cv::Point2f(x2, y2),
        cv::Point2f(x3, y3),
        cv::Point2f(x4, y4)};

    cv::Mat transformation_matrix = cv::getPerspectiveTransform(img_pts, dst_pts);
    cv::warpPerspective(img, img, transformation_matrix, cv::Size(GRID_SIZE, GRID_SIZE));
}

void GridExtractor::remove_grid_lines(cv::Mat &binary) {
    cv::Mat inv;
    cv::bitwise_not(binary, inv);

    cv::Mat horizontal_lines;
    cv::Mat kernel_h = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(0.8 * CELL_SIZE, 1));
    cv::morphologyEx(inv, horizontal_lines, cv::MORPH_OPEN, kernel_h);

    cv::Mat vertical_lines;
    cv::Mat kernel_v = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(1, 0.9 * CELL_SIZE));
    cv::morphologyEx(inv, vertical_lines, cv::MORPH_OPEN, kernel_v);

    // use existing Mat to save some memory
    cv::bitwise_or(horizontal_lines, vertical_lines, horizontal_lines);
    cv::Mat &grid_lines = horizontal_lines;
    vertical_lines.release();

    // make grid thicker
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_CROSS, cv::Size(5, 5));
    cv::dilate(grid_lines, grid_lines, kernel);

    // remove grid from input image
    cv::bitwise_or(binary, grid_lines, binary);

#ifdef DEVMODE
    cv::imshow("grid lines", grid_lines);
#endif
}

std::vector<int> GridExtractor::cells_to_array(std::vector<Cell> &cells) {
    std::vector<int> array(9 * 9, 0);

    for (Cell &cell : cells) {
        array[cell.x + 9 * cell.y] = cell.number;
    }

    return array;
}

void GridExtractor::flood_fill_white(cv::Mat &binary, std::vector<cv::Point> &points, int x, int y) {
    binary.at<uchar>(y, x) = 255;
    points.push_back(cv::Point(x, y));

    // four point flood
    int min_x = std::max(x - 1, 0);
    int max_x = std::min(x + 1, binary.cols - 1);
    int min_y = std::max(y - 1, 0);
    int max_y = std::min(y + 1, binary.rows - 1);

    if (binary.at<uchar>(y, min_x) < 255) {
        flood_fill_white(binary, points, min_x, y);
    }
    if (binary.at<uchar>(y, max_x) < 255) {
        flood_fill_white(binary, points, max_x, y);
    }
    if (binary.at<uchar>(min_y, x) < 255) {
        flood_fill_white(binary, points, x, min_y);
    }
    if (binary.at<uchar>(max_y, x) < 255) {
        flood_fill_white(binary, points, x, max_y);
    }
}

bool GridExtractor::extract_number(cv::Mat &binary, cv::Rect &output, cv::Point &center) {
    const int threshold = 35;  // min amount of points for number
    const int scan_size = CELL_SIZE / 3;

    std::vector<cv::Rect> connected_areas;

    for (int y = center.y - scan_size / 2; y < center.y + scan_size / 2; ++y) {
        for (int x = center.x - scan_size / 2; x < center.x + scan_size / 2; ++x) {
            if (binary.at<uchar>(y, x) == 255) {
                continue;
            }

            std::vector<cv::Point> points;
            flood_fill_white(binary, points, x, y);

            if (points.size() < threshold) {
                continue;
            }

            cv::Rect bb = cv::boundingRect(points);

            if (bb.height < 0.2 * CELL_SIZE || bb.height > 0.9 * CELL_SIZE ||
                bb.width < 0.1 * CELL_SIZE || bb.width > 0.8 * CELL_SIZE) {
                continue;
            }

            connected_areas.push_back(bb);
        }
    }

#ifdef DEVMODE
    // cv::Point offset(scan_size / 2, scan_size / 2);
    // cv::rectangle(binary, center - offset, center + offset, cv::Scalar(0, 0, 0));
    // cv::imshow("flood fill", binary);
    // cv::waitKey();
#endif

    if (connected_areas.empty()) {
        return false;
    }

    // find bounding box with biggest area TODO: maybe inside helper header
    auto is_bigger = [](cv::Rect &bb1, cv::Rect &bb2) { return bb1.area() < bb2.area(); };
    output = *std::max_element(connected_areas.begin(), connected_areas.end(), is_bigger);
    return true;
}

void GridExtractor::make_square(cv::Rect &rect, int pad_size) {
    cv::Point top_left = rect.tl();
    cv::Point bottom_right = rect.br();

    // make square
    int width = rect.width;
    int height = rect.height;
    if (height > width) {  // move x
        int delta_x = (height - width) / 2;
        top_left.x = top_left.x - delta_x;
        bottom_right.x = bottom_right.x + delta_x;
    } else if (width > height) {  // move y
        int delta_y = (width - height) / 2;
        top_left.y = top_left.y - delta_y;
        bottom_right.y = bottom_right.y + delta_y;
    }

    // apply padding
    top_left.x = top_left.x - pad_size;
    top_left.y = top_left.y - pad_size;
    bottom_right.x = bottom_right.x + pad_size;
    bottom_right.y = bottom_right.y + pad_size;

    // make sure points are in boundary
    top_left.x = std::max(top_left.x, 0);
    top_left.y = std::max(top_left.y, 0);
    bottom_right.x = std::min(bottom_right.x, GRID_SIZE);
    bottom_right.y = std::min(bottom_right.y, GRID_SIZE);

    rect = cv::Rect(top_left, bottom_right);
}

std::vector<Cell> GridExtractor::extract_cells(cv::Mat &binary, cv::Mat &img) {
    std::vector<Cell> cells;

    for (int y = 0; y < 9; ++y) {
        for (int x = 0; x < 9; ++x) {
            cv::Rect bounding_box;
            cv::Point center(x * CELL_SIZE + CELL_SIZE / 2, y * CELL_SIZE + CELL_SIZE / 2);
            bool has_number = extract_number(binary, bounding_box, center);

            if (has_number) {
                // cv::rectangle(img, bounding_box, cv::Scalar(0, 255, 0));  // debug TODO delete
                make_square(bounding_box, 2);
                cv::Mat number_img = img(bounding_box);
                cells.push_back(Cell(number_img, x, y));
            }
        }
    }

    return cells;
}

// only for debug
cv::Mat GridExtractor::stitch_cells(std::vector<Cell> &cells) {
    cv::Mat stitched = cv::Mat::zeros(GRID_SIZE, GRID_SIZE, CV_8UC1);

    for (Cell &cell : cells) {
        cv::Mat resized;
        cv::resize(cell.img, resized, cv::Size(CELL_SIZE, CELL_SIZE));
        int x = cell.x * CELL_SIZE;
        int y = cell.y * CELL_SIZE;
        resized.copyTo(stitched(cv::Rect(x, y, CELL_SIZE, CELL_SIZE)));
    }

    return stitched;
}
