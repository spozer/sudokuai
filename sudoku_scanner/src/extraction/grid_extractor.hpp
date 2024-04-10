#ifndef GRID_EXTRACTOR_HPP
#define GRID_EXTRACTOR_HPP

#include <opencv2/core.hpp>
#include <vector>

#include "structs/cell.hpp"

class GridExtractor {
   public:
    static std::vector<int> extract_grid(cv::Mat &img, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4);

   private:
    GridExtractor() = delete;
    static void crop_and_transform(cv::Mat &img, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4);
    static void remove_grid_lines(cv::Mat &binary);
    static std::vector<int> cells_to_array(std::vector<Cell> &cells);
    static void flood_fill_white(cv::Mat &binary, std::vector<cv::Point> &points, int x, int y);
    static bool extract_number(cv::Mat &binary, cv::Rect &output, cv::Point &center);
    static void make_square(cv::Rect &rect, int pad_size);
    static std::vector<Cell> extract_cells(cv::Mat &binary, cv::Mat &img);
    static cv::Mat stitch_cells(std::vector<Cell> &cells);  // debug
};

#endif
