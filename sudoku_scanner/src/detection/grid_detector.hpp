#ifndef GRID_DETECTOR_HPP
#define GRID_DETECTOR_HPP

#include <opencv2/core.hpp>
#include <vector>

class GridDetector {
   public:
    static std::vector<cv::Point> detect_grid(cv::Mat &img);

   private:
    GridDetector() = delete;
    static void resize_to_resolution(cv::Mat &img, int resolution);
    static void sort_quadrilateral(std::vector<cv::Point> &quadrilateral);
    static bool find_sudoku_grid(const cv::Mat &vector, std::vector<cv::Point> &output);
    static cv::Mat get_hough_lines(cv::Mat &img);
};

#endif
