#include "grid_detector.hpp"
#include <opencv2/imgproc/types_c.h>
#include <opencv2/opencv.hpp>

std::vector<cv::Point> GridDetector::detect_grid(cv::Mat &img) {
    cv::Mat thresholded;
    cv::cvtColor(img, img, cv::COLOR_BGR2GRAY);
    cv::adaptiveThreshold(img, thresholded, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV, 69, 20);

    cv::Mat hough_lines = get_hough_lines(thresholded);

    return get_max_rectangle(hough_lines);
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

std::vector<cv::Point> GridDetector::get_max_rectangle(cv::Mat &hough_lines) {
    int width = hough_lines.size().width;
    int height = hough_lines.size().height;
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Point> max_rectangle = {cv::Point(0, 0), cv::Point(width, 0), cv::Point(0, height), cv::Point(width, height)};

    cv::findContours(hough_lines, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

    if (contours.size() > 0) {
        auto is_bigger = [](std::vector<cv::Point> &contour1, std::vector<cv::Point> &contour2) { return cv::contourArea(contour1) > cv::contourArea(contour2); };
        std::sort(contours.begin(), contours.end(), is_bigger);

        for (std::vector<cv::Point> &contour : contours) {

            if (cv::contourArea(contour) < (width * height) / 20) {
                break;
            }

            std::vector<cv::Point> poly_approx;
            double eps = 0.02 * cv::arcLength(contour, true);
            cv::approxPolyDP(contour, poly_approx, eps, true);

            if (poly_approx.size() == 4) {
                max_rectangle = poly_approx;
                sort_rectangle(max_rectangle);
            }
        }
    }

    return max_rectangle;
}

cv::Mat GridDetector::get_hough_lines(cv::Mat &binary) {
    std::vector<cv::Vec4i> lines;
    cv::Mat hough_lines = cv::Mat::zeros(binary.size(), binary.type());
    cv::HoughLinesP(binary, lines, 1, CV_PI / 180, 50, 50, 5);

    for (cv::Vec4i &line : lines) {
        cv::Point start(line[0], line[1]);
        cv::Point end(line[2], line[3]);

        cv::line(hough_lines, start, end, cv::Scalar(255, 255, 255), 3);
    }

    return hough_lines;
}
