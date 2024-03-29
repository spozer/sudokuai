#include "grid_extractor.hpp"

#include <opencv2/imgproc.hpp>
#include <vector>

#include "classification/number_classifier.hpp"

std::vector<int> GridExtractor::extract_grid(cv::Mat &img, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    cv::Mat transformed;
    cv::Mat thresholded;

    cv::cvtColor(img, img, cv::COLOR_BGR2GRAY);
    transformed = crop_and_transform(img, x1, y1, x2, y2, x3, y3, x4, y4);
    // cv::adaptiveThreshold(img, thresholded, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 69, 20);
    cv::adaptiveThreshold(transformed, thresholded, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 63, 10);
    // cv::adaptiveThreshold(transformed, thresholded, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 53, 10);

    std::vector<Cell> cells = extract_cells(thresholded, transformed);
    NumberClassifier::predict_numbers(cells);

    return cells_to_array(cells);
}

cv::Mat GridExtractor::crop_and_transform(cv::Mat img, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    const int dst_size = 450;  // img.size().width;
    cv::Mat dst = cv::Mat::zeros(dst_size, dst_size, CV_8UC1);
    std::vector<cv::Point2f> dst_pts;
    std::vector<cv::Point2f> img_pts;

    dst_pts.push_back(cv::Point(0, 0));
    dst_pts.push_back(cv::Point(dst_size - 1, 0));
    dst_pts.push_back(cv::Point(0, dst_size - 1));
    dst_pts.push_back(cv::Point(dst_size - 1, dst_size - 1));

    img_pts.push_back(cv::Point2f(x1, y1));
    img_pts.push_back(cv::Point2f(x2, y2));
    img_pts.push_back(cv::Point2f(x3, y3));
    img_pts.push_back(cv::Point2f(x4, y4));

    cv::Mat transformation_matrix = cv::getPerspectiveTransform(img_pts, dst_pts);
    cv::warpPerspective(img, dst, transformation_matrix, dst.size());

    return dst;
}

std::vector<Cell> GridExtractor::extract_cells(cv::Mat &thresh, cv::Mat &img) {
    int cell_size = img.size().height / 9;
    std::vector<Cell> cells;

    for (int y = 0; y < 9; ++y) {
        for (int x = 0; x < 9; ++x) {
            std::vector<cv::Point> points;
            cv::Rect cell_cut(x * cell_size, y * cell_size, cell_size, cell_size);
            cv::Mat cell_thresh = thresh(cell_cut);
            extract_number(cell_thresh, points);

            // cell is not empty
            if (!points.empty()) {
                cv::Mat cell_img = img(cell_cut);
                cv::Rect bbox = cv::boundingRect(points);
                make_square(bbox, cell_size, 2);
                cv::Mat number_img = cell_img(bbox);
                // cv::Mat number_img = cell_img;                          // debug TODO delete
                // cv::rectangle(number_img, bbox, cv::Scalar(0, 255, 0)); // debug TODO delete
                cells.push_back(Cell(number_img, x, y));
            }
        }
    }

    return cells;
}

// only for debug
cv::Mat GridExtractor::stitch_cells(std::vector<Cell> &cells) {
    const int size = 450;
    int cell_size = int(size / 9);
    cv::Mat stitched = cv::Mat::zeros(size, size, CV_8UC1);

    for (Cell &cell : cells) {
        cv::Mat resized;
        cv::resize(cell.img, resized, cv::Size(cell_size, cell_size));
        int x = cell.x * cell_size;
        int y = cell.y * cell_size;
        resized.copyTo(stitched(cv::Rect(x, y, cell_size, cell_size)));
    }

    return stitched;
}

// only for debug (used in stich_cells)
cv::Mat GridExtractor::add_border(cv::Mat &img, int size) {
    for (int x = 0; x < img.size().width; ++x) {
        for (int pad = 0; pad <= size; ++pad) {
            img.at<uchar>(pad, x) = 123;
            img.at<uchar>(img.size().height - 1 - pad, x) = 123;
        }
    }
    for (int y = 0; y < img.size().height; ++y) {
        for (int pad = 0; pad <= size; ++pad) {
            img.at<uchar>(y, pad) = 123;
            img.at<uchar>(y, img.size().width - 1 - pad) = 123;
        }
    }
    return img;
}

std::vector<int> GridExtractor::cells_to_array(std::vector<Cell> &cells) {
    std::vector<int> array(9 * 9, 0);

    for (Cell &cell : cells) {
        array[cell.x + 9 * cell.y] = cell.number;
    }

    return array;
}

void GridExtractor::extract_number(cv::Mat &img, std::vector<cv::Point> &output) {
    const int threshold = 70;  // min amount of points for number
    int cell_size = img.size().width;
    int scan_size = cell_size / 5;

    int scan_box_min = (cell_size - scan_size) / 2;
    int scan_box_max = cell_size - scan_box_min;

    std::vector<std::vector<cv::Point>> connected_areas;

    for (int y = scan_box_min; y < scan_box_max; ++y) {
        for (int x = scan_box_min; x < scan_box_max; ++x) {
            if (img.at<uchar>(y, x) < 255) {
                std::vector<cv::Point> points;
                flood_fill_white(img, points, x, y);

                if (points.size() > threshold) {
                    connected_areas.push_back(points);
                }
            }
        }
    }

    if (connected_areas.size() > 0) {
        auto is_bigger = [](std::vector<cv::Point> &list1, std::vector<cv::Point> &list2) { return list1.size() > list2.size(); };
        std::vector<std::vector<cv::Point>>::iterator pr = std::max_element(connected_areas.begin(), connected_areas.end(), is_bigger);
        output = *pr;
    }
}

void GridExtractor::make_square(cv::Rect &rect, int size, int pad_size) {
    cv::Point top_left = rect.tl();
    cv::Point bottom_right = rect.br();

    // make square
    int width = rect.width;
    int height = rect.height;
    // move x
    if (height > width) {
        int delta_x = (height - width) / 2;
        top_left.x = std::max(top_left.x - delta_x, 0);
        bottom_right.x = std::min(bottom_right.x + delta_x, size);
        // move y
    } else if (width > height) {
        int delta_y = (width - height) / 2;
        top_left.y = std::max(top_left.y - delta_y, 0);
        bottom_right.y = std::min(bottom_right.y + delta_y, size);
    }

    // apply padding
    top_left.x = std::max(top_left.x - pad_size, 0);
    top_left.y = std::max(top_left.y - pad_size, 0);
    bottom_right.x = std::min(bottom_right.x + pad_size, size);
    bottom_right.y = std::min(bottom_right.y + pad_size, size);

    rect = cv::Rect(top_left, bottom_right);
}

void GridExtractor::flood_fill_white(cv::Mat &img, std::vector<cv::Point> &points, int x, int y) {
    int width = img.size().width;
    int height = img.size().height;

    img.at<uchar>(y, x) = 255;
    points.push_back(cv::Point(x, y));

    // four point flood
    int min_x = std::max(x - 1, 0);
    int max_x = std::min(x + 1, width - 1);
    int min_y = std::max(y - 1, 0);
    int max_y = std::min(y + 1, height - 1);

    if (img.at<uchar>(y, min_x) < 255) {
        flood_fill_white(img, points, min_x, y);
    }
    if (img.at<uchar>(y, max_x) < 255) {
        flood_fill_white(img, points, max_x, y);
    }
    if (img.at<uchar>(min_y, x) < 255) {
        flood_fill_white(img, points, x, min_y);
    }
    if (img.at<uchar>(max_y, x) < 255) {
        flood_fill_white(img, points, x, max_y);
    }
}
