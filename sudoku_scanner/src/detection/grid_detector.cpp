#include "grid_detector.hpp"

#include <cmath>
#include <opencv2/imgproc.hpp>
#include <string>
#include <tuple>
#include <vector>

#ifdef DEVMODE
#include <opencv2/highgui.hpp>
#endif

// TODO: maybe make some settings headers?
const int RESOLUTION = 480;

const double MIN_AREA = RESOLUTION * RESOLUTION / 15;

const std::vector<std::tuple<int, double>>
    THRESHOLD_SETTINGS = {
        // blockSize and C for [cv::adaptiveThreshold]
        {69, 20.0},
        {45, 15.0},
        {23, 10.0},
        {9, 5.0}};

// TODO: move to helper headers (helper.hpp utility.hpp ?)
void GridDetector::resize_to_resolution(cv::Mat &img, int resolution) {
    cv::Size size;

    if (img.size().height > img.size().width) {
        size = cv::Size(resolution, (static_cast<double>(img.size().height) / img.size().width) * resolution);
    } else {
        size = cv::Size((static_cast<double>(img.size().width) / img.size().height) * resolution, resolution);
    }

    cv::resize(img, img, size);
}

// TODO: move to helper headers
double GridDetector::calc_angle(cv::Point point0, cv::Point point1, cv::Point point2) {
    cv::Point line1 = point1 - point0;
    cv::Point line2 = point2 - point0;

    return std::acos(line1.dot(line2) / (cv::norm(line1) * cv::norm(line2))) * 180 / CV_PI;
}

std::vector<cv::Point> GridDetector::detect_grid(cv::Mat &img) {
    cv::Size original_size = img.size();
    resize_to_resolution(img, RESOLUTION);
    cv::cvtColor(img, img, cv::COLOR_BGR2GRAY);

    cv::Mat thresholded;
    std::vector<cv::Point> detection;

    for (const auto &[block_size, c] : THRESHOLD_SETTINGS) {
        cv::adaptiveThreshold(img, thresholded, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV, block_size, c);
        // cv::Mat hough_lines = get_hough_lines(thresholded);
        bool has_squarelike = find_max_area_squarelike(thresholded, detection);

#ifdef DEVMODE
        std::string name = "Threshold " + std::to_string(block_size) + ", " + std::to_string(c);
        cv::imshow(name, thresholded);
#endif
        if (has_squarelike) {
#ifdef DEVMODE
            cv::cvtColor(img, img, cv::COLOR_GRAY2BGR);
            cv::polylines(img, std::vector{detection[0], detection[1], detection[3], detection[2]}, true, cv::Scalar(0, 0, 255));
            cv::imshow("detection", img);
#endif
            // get points in original sized image
            double scale_x = static_cast<double>(original_size.width) / img.size().width;
            double scale_y = static_cast<double>(original_size.height) / img.size().height;

            for (cv::Point &point : detection) {
                point.x *= scale_x;
                point.y *= scale_y;
            }

            return detection;
        }
    }

    // no detection
    return {cv::Point(0, 0), cv::Point(original_size.width - 1, 0), cv::Point(0, original_size.height - 1), cv::Point(original_size.width - 1, original_size.height - 1)};
}

void GridDetector::sort_rectangle(std::vector<cv::Point> &rectangle) {
    cv::Point tl, tr, bl, br;

    auto has_smaller_sum = [](cv::Point point1, cv::Point point2) { return point1.x + point1.y < point2.x + point2.y; };
    auto has_smaller_diff = [](cv::Point point1, cv::Point point2) { return point1.y - point1.x < point2.y - point2.x; };

    // sort for smaller sum -> {tl < (tr ? bl) < br}
    std::sort(rectangle.begin(), rectangle.end(), has_smaller_sum);

    // sort for smaller diff -> {(tl) tr < bl (br)}
    std::sort(rectangle.begin() + 1, rectangle.end() - 1, has_smaller_diff);
}

bool GridDetector::find_max_area_squarelike(const cv::Mat &binary, std::vector<cv::Point> &result) {
    std::vector<std::vector<cv::Point>> contours;
    std::vector<std::vector<cv::Point>> squarelikes;

    cv::findContours(binary, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);

    if (contours.empty()) {
        return false;
    }

    // TODO: move to helper header
    auto mod = [](int a, int b) { return ((a % b) + b) % b; };

    for (const std::vector<cv::Point> &contour : contours) {
        std::vector<cv::Point> poly_approx;
        double eps = 0.02 * cv::arcLength(contour, true);
        cv::approxPolyDP(contour, poly_approx, eps, true);

        if (poly_approx.size() == 4 && cv::isContourConvex(poly_approx) && cv::contourArea(contour) > MIN_AREA) {
            // TODO: this method only good for extract_from_roi (could also be done with messuring angles to be ~90°)
            // TODO: implement strict mode expection this method (parameter -> bool strict)
            /* this method of finding a rotated bounding box of the sudoku grid expects that
                the image was not taken at an acute angle. In other words the sudoku grid is still
                square-like from the image's perspective. */
            // cv::RotatedRect rect = cv::minAreaRect(poly_approx);
            // double aspect_ratio = static_cast<double>(rect.size.width) / rect.size.height;

#ifdef DEVMODE
            // printf("aspect ratio: %f\n", aspect_ratio);
#endif

            // continue if rect is not square-like
            // if (aspect_ratio < 0.75 || aspect_ratio > 1.25) {
            //     continue;
            // }

            double min_angle = 360;
            double max_angle = 0;

            for (int i = 0; i < 4; ++i) {
                double angle = calc_angle(poly_approx[i], poly_approx[mod(i - 1, 4)], poly_approx[mod(i + 1, 4)]);
                max_angle = cv::max(max_angle, angle);
                min_angle = cv::min(min_angle, angle);
#ifdef DEVMODE
                printf("angle %d (%d, %d): %f\n", i, poly_approx[i].x, poly_approx[i].y, angle);
#endif
            }

            // check for square-like angles
            if (min_angle < 70 || max_angle > 110) {
                continue;
            }

            squarelikes.push_back(poly_approx);
        }
    }

#ifdef DEVMODE
    printf("found %zu square-like contour(s)\n", squarelikes.size());
#endif

    if (squarelikes.empty()) {
        return false;
    }

    // TODO: maybe move to helper header?
    auto is_bigger = [](std::vector<cv::Point> &contour1, std::vector<cv::Point> &contour2) { return cv::contourArea(contour1) > cv::contourArea(contour2); };

    // find biggest area square-like
    std::sort(squarelikes.begin(), squarelikes.end(), is_bigger);
    sort_rectangle(squarelikes[0]);
    result = squarelikes[0];

    return true;
}

// TODO: remove, not needed?
cv::Mat GridDetector::get_hough_lines(cv::Mat &binary) {
    std::vector<cv::Vec4i> lines;
    cv::Mat hough_lines = cv::Mat::zeros(binary.size(), binary.type());
    cv::HoughLinesP(binary, lines, 1, CV_PI / 180, 50, 50, 5);

    for (cv::Vec4i &line : lines) {
        cv::Point start(line[0], line[1]);
        cv::Point end(line[2], line[3]);

        cv::line(hough_lines, start, end, cv::Scalar(255, 255, 255), 3);
    }

#ifdef DEVMODE
    cv::imshow("hough lines", hough_lines);
#endif

    return hough_lines;
}
