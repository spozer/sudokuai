#ifndef GRID_DETECTOR_HPP
#define GRID_DETECTOR_HPP

#include <opencv2/opencv.hpp>

class GridDetector {
  public:
    static std::vector<cv::Point> detect_grid(cv::Mat &img);

  private:
    GridDetector() = delete;
    static void sort_rectangle(std::vector<cv::Point> &rectangle);
    static std::vector<cv::Point> get_max_rectangle(cv::Mat &hough_lines);
    static cv::Mat get_hough_lines(cv::Mat &img);
};

#endif
