#ifndef CELL_HPP
#define CELL_HPP

#include <cstdint>
#include <opencv2/core.hpp>

struct Cell {
    const cv::Mat img;
    const std::uint8_t x;
    const std::uint8_t y;
    std::uint8_t number = 0;

    Cell(const cv::Mat &img, const std::uint8_t x, const std::uint8_t y) : img(img), x(x), y(y) {}
};

#endif
