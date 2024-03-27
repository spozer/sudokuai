#ifndef GRID_EXTRACTOR_HPP
#define GRID_EXTRACTOR_HPP

#include "structs/cell.hpp"
#include <opencv2/opencv.hpp>

class GridExtractor {
  public:
    static std::vector<int> extract_grid(cv::Mat &img, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4);
    static cv::Mat crop_and_transform(cv::Mat img, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4); // public because of debug
    static std::vector<Cell> extract_cells(cv::Mat &thresh, cv::Mat &img); // public because of debug
    static cv::Mat stitch_cells(std::vector<Cell> &cells); // debug

  private:
    GridExtractor() = delete;
    static cv::Mat add_border(cv::Mat &img, int size); // debug
    static std::vector<int> cells_to_array(std::vector<Cell> &cells);
    static void extract_number(cv::Mat &img, std::vector<cv::Point> &output);
    static void make_square(cv::Rect &rect, int size, int pad_size);
    static void flood_fill_white(cv::Mat &img, std::vector<cv::Point> &points, int x, int y);
};

#endif
