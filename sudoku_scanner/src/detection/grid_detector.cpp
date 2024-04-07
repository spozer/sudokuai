#include "grid_detector.hpp"

#include <algorithm>
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

const double MIN_AREA = RESOLUTION * RESOLUTION / 10;

const std::vector<std::tuple<int, double>> THRESHOLD_SETTINGS = {
    // blockSize and C for [cv::adaptiveThreshold]
    {69, 20.0},
    {45, 15.0},
    {23, 10.0},
    {9, 10.0}};

// TODO: move to helper headers (helper.hpp utility.hpp ?)
void GridDetector::resize_to_resolution(cv::Mat &img, int resolution) {
    int src_width = img.size().width;
    int src_height = img.size().height;
    int dest_width, dest_height;

    if (src_height > src_width) {
        dest_width = resolution;
        dest_height = (static_cast<double>(src_height) / src_width) * resolution;
    } else {
        dest_width = (static_cast<double>(src_width) / src_height) * resolution;
        dest_height = resolution;
    }

    int interpolation = std::min(src_width, src_height) < resolution ? cv::INTER_LINEAR : cv::INTER_AREA;

    cv::resize(img, img, cv::Size(dest_width, dest_height), interpolation);
}

// TODO: move to helper headers
double GridDetector::calc_angle(cv::Point point0, cv::Point point1, cv::Point point2) {
    cv::Point line1 = point1 - point0;
    cv::Point line2 = point2 - point0;

    return std::acos(line1.dot(line2) / (cv::norm(line1) * cv::norm(line2))) * 180 / CV_PI;
}

std::vector<cv::Point> GridDetector::detect_grid(cv::Mat &img) {
    cv::Size src_size = img.size();
    cv::cvtColor(img, img, cv::COLOR_BGR2GRAY);
    cv::pyrDown(img, img);
    cv::pyrUp(img, img);
    resize_to_resolution(img, RESOLUTION);

#ifdef DEVMODE
    cv::Mat dil;
    cv::equalizeHist(img, dil);
    cv::adaptiveThreshold(dil, dil, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 69, 20.0);
    cv::dilate(dil, dil, cv::Mat());
    // cv::dilate(dil, dil, cv::Mat());
    // cv::dilate(dil, dil, cv::Mat());
    // cv::dilate(dil, dil, cv::Mat());
    // cv::dilate(dil, dil, cv::Mat());
    cv::imshow("dil", dil);
#endif

    cv::Mat thresholded;
    std::vector<cv::Point> detection;

    // change of basis from resized image to original source image
    double t_x = static_cast<double>(src_size.width) / img.size().width;
    double t_y = static_cast<double>(src_size.height) / img.size().height;

    for (const auto &[block_size, c] : THRESHOLD_SETTINGS) {
        cv::adaptiveThreshold(img, thresholded, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV, block_size, c);
        bool has_sudoku_grid = find_sudoku_grid(thresholded, detection);

#ifdef DEVMODE
        std::string name = "Threshold " + std::to_string(block_size) + ", " + std::to_string(c) + " (detection)";
        cv::imshow(name, thresholded);
#endif
        if (has_sudoku_grid) {
#ifdef DEVMODE
            cv::cvtColor(img, img, cv::COLOR_GRAY2BGR);
            cv::polylines(img, std::vector{detection[0], detection[1], detection[3], detection[2]}, true, cv::Scalar(0, 0, 255));
            cv::imshow("detection", img);
#endif
            // get points in original sized image
            for (cv::Point &point : detection) {
                point.x *= t_x;
                point.y *= t_y;
            }

            return detection;
        }
    }

    // no detection
    return {cv::Point(0, 0), cv::Point(src_size.width - 1, 0), cv::Point(0, src_size.height - 1), cv::Point(src_size.width - 1, src_size.height - 1)};
}

void GridDetector::sort_quadrilateral(std::vector<cv::Point> &quadrilateral) {
    cv::Point tl, tr, bl, br;

    auto has_smaller_sum = [](cv::Point point1, cv::Point point2) { return point1.x + point1.y < point2.x + point2.y; };
    auto has_smaller_diff = [](cv::Point point1, cv::Point point2) { return point1.y - point1.x < point2.y - point2.x; };

    // sort for smaller sum -> {tl < (tr ? bl) < br}
    std::sort(quadrilateral.begin(), quadrilateral.end(), has_smaller_sum);

    // sort for smaller diff -> {(tl) tr < bl (br)}
    std::sort(quadrilateral.begin() + 1, quadrilateral.end() - 1, has_smaller_diff);
}

bool GridDetector::find_sudoku_grid(const cv::Mat &binary, std::vector<cv::Point> &result) {
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    std::vector<std::vector<cv::Point>> quadrilaterals;
    std::vector<std::vector<cv::Point>> squarelikes;

    cv::findContours(binary, contours, hierarchy, cv::RETR_CCOMP, cv::CHAIN_APPROX_SIMPLE);

    if (contours.empty()) {
        return false;
    }

    // TODO: move to helper header
    auto mod = [](int a, int b) { return ((a % b) + b) % b; };

    for (int i = 0; i < contours.size(); ++i) {
        // check if contour has no holes
        if (hierarchy[i][2] == -1) {
            continue;
        }

        auto &contour = contours[i];
        std::vector<cv::Point> poly_approx;
        double eps = 0.02 * cv::arcLength(contour, true);
        cv::approxPolyDP(contour, poly_approx, eps, true);

        if (poly_approx.size() == 4 && cv::isContourConvex(poly_approx) && cv::contourArea(contour) > MIN_AREA) {
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

            // filter out non rectangle-like angles
            if (min_angle < 70 || max_angle > 110) {
                continue;
            }

#ifdef DEVMODE
            // count child contours
            int next_child = hierarchy[i][2];
            int count = 1;

            while (true) {
                next_child = hierarchy[next_child][0];
                if (next_child == -1) {
                    break;
                }
                count++;
            }
            printf("contour %d has %d child(s)\n", i, count);
#endif
            // check if photo was taken perpendicular to image plane ("Draufsicht")
            // this means the measured angles of the rectangular contoure are expected to be ~90°
            if (max_angle - min_angle > 5) {
                quadrilaterals.push_back(poly_approx);
                continue;
            }

            // Now that we now that the contour is for sure a rectangle,
            // we can check whether it is also a square. This is done by
            // measuring the contoures aspect ratio.

            cv::RotatedRect rect = cv::minAreaRect(poly_approx);
            double aspect_ratio = static_cast<double>(rect.size.width) / std::max(rect.size.height, 1.0f);
#ifdef DEVMODE
            printf("aspect ratio: %f\n", aspect_ratio);
#endif
            // filter out non square-like aspect ratios
            if (aspect_ratio < 0.9 || aspect_ratio > 1.1) {
                continue;
            }

            squarelikes.push_back(poly_approx);
        }
    }

#ifdef DEVMODE
    printf("found %zu square-like contour(s)\n", quadrilaterals.size() + squarelikes.size());
#endif

    // detected quadrilaterals can be squares depending on the perspective the photo was taken at
    std::vector<std::vector<cv::Point>> &possible_squares = squarelikes.empty() ? quadrilaterals : squarelikes;

    // TODO: maybe move to helper header?
    auto is_bigger = [](std::vector<cv::Point> &contour1, std::vector<cv::Point> &contour2) {
        return cv::contourArea(contour1) < cv::contourArea(contour2);
    };

    if (possible_squares.empty()) {
        return false;
    }

    // find biggest area square-like
    std::vector<cv::Point> &max_squarelike = *std::max_element(possible_squares.begin(), possible_squares.end(), is_bigger);
    sort_quadrilateral(max_squarelike);
    result = max_squarelike;

    return true;
}

// TODO: remove, not needed?
cv::Mat GridDetector::get_hough_lines(cv::Mat &binary) {
    std::vector<cv::Vec4i> lines;
    cv::Mat hough_lines = cv::Mat::zeros(binary.size(), binary.type());
    cv::HoughLinesP(binary, lines, 1, CV_PI / 180, 50, RESOLUTION / 3.8, 5);

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
