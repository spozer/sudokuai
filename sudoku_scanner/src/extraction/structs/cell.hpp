#ifndef CELL_HPP
#define CELL_HPP

#include <opencv2/opencv.hpp>

struct Cell {
    const cv::Mat img;
    const int x;
    const int y;
    int number = 0;

    Cell(const cv::Mat img, const int x, const int y) : img(img), x(x), y(y) {}
};

#endif
