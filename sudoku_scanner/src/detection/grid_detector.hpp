#ifndef GRID_DETECTOR_HPP
#define GRID_DETECTOR_HPP

#include <opencv2/core.hpp>
#include <vector>

class GridDetector {
   public:
    static void resize_to_resolution(cv::Mat &img, int resolution);
    static std::vector<cv::Point> detect_grid(cv::Mat &img);

   private:
    GridDetector() = delete;
    static double calc_angle(cv::Point point0, cv::Point point1, cv::Point point2);
    static void sort_rectangle(std::vector<cv::Point> &rectangle);
    static bool find_max_area_squarelike(const cv::Mat &vector, std::vector<cv::Point> &result);
    static cv::Mat get_hough_lines(cv::Mat &img);
};

#endif
