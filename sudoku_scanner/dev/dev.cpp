#include <opencv2/imgproc/types_c.h>
#include <stdio.h>
#include <tensorflow/lite/c/c_api.h>

#include <iostream>
#include <opencv2/highgui.hpp>
#include <opencv2/opencv.hpp>

#include "../src/native_sudoku_scanner.hpp"

int main() {
    printf("OpenCV %s\n", CV_VERSION);
    printf("TensorFlow Lite (C) %s\n", TfLiteVersion());
#ifdef NDEBUG
    printf("no debug\n");
#else
    printf("debug\n");
#endif
    if (__cplusplus == 202101L)
        std::cout << "C++23";
    else if (__cplusplus == 202002L)
        std::cout << "C++20";
    else if (__cplusplus == 201703L)
        std::cout << "C++17";
    else if (__cplusplus == 201402L)
        std::cout << "C++14";
    else if (__cplusplus == 201103L)
        std::cout << "C++11";
    else if (__cplusplus == 199711L)
        std::cout << "C++98";
    else
        std::cout << "pre-standard C++." << __cplusplus;
    std::cout << "\n";

    cv::Mat empty_img = cv::Mat::zeros(cv::Size(200, 200),CV_8UC1);
    cv::imshow("hello world", empty_img);
    cv::waitKey(0);


    return 0;
}
