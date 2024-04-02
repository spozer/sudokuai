#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <vector>

namespace ss {
#include "../src/sudoku_scanner.h"
}

// relative path from build directory
const std::string MODEL_PATH = "../../assets/model.tflite";
const std::string IMAGES_PATH = "../images";

void test_on_image(std::string &image_path, std::vector<int> &expected_grid) {
    std::unique_ptr<ss::BoundingBox> bb(ss::detect_grid((char *)image_path.c_str()));
    std::unique_ptr<int> grid_ptr(ss::extract_grid((char *)image_path.c_str(), bb.get()));
    std::vector<int> grid(grid_ptr.get(), grid_ptr.get() + 81);

    ASSERT_EQ(grid.size(), expected_grid.size());

    for (int i = 0; i < grid.size(); ++i) {
        EXPECT_EQ(grid[i], expected_grid[i]) << "Wrong value at (" << i % 9 << ", " << i / 9 << ")";
    }
}

TEST(IntegrationTest, TestFirstImage) {
    std::string image_path = IMAGES_PATH + "/1.jpg";

    std::vector<int> expected_grid{
        0, 0, 1, 0, 0, 0, 0, 3, 0,
        0, 0, 3, 4, 7, 1, 0, 0, 6,
        0, 0, 2, 0, 0, 0, 8, 0, 0,
        1, 0, 0, 0, 5, 7, 0, 0, 3,
        0, 0, 0, 0, 0, 0, 0, 0, 0,
        7, 0, 0, 3, 9, 0, 0, 0, 5,
        0, 0, 6, 0, 0, 0, 2, 0, 0,
        2, 0, 0, 1, 4, 5, 3, 0, 0,
        0, 9, 0, 0, 0, 0, 5, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestSecondImage) {
    std::string image_path = IMAGES_PATH + "/2.jpg";

    std::vector<int> expected_grid{
        8, 0, 0, 0, 1, 0, 0, 0, 9,
        0, 5, 0, 8, 0, 7, 0, 1, 0,
        0, 0, 4, 0, 9, 0, 7, 0, 0,
        0, 6, 0, 7, 0, 1, 0, 2, 0,
        5, 0, 8, 0, 6, 0, 1, 0, 7,
        0, 1, 0, 5, 0, 2, 0, 9, 0,
        0, 0, 7, 0, 4, 0, 6, 0, 0,
        0, 8, 0, 3, 0, 9, 0, 4, 0,
        3, 0, 0, 0, 5, 0, 0, 0, 8};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestForthImage) {
    std::string image_path = IMAGES_PATH + "/4.jpg";

    std::vector<int> expected_grid{
        0, 0, 0, 3, 0, 6, 0, 0, 0,
        0, 8, 3, 2, 0, 7, 1, 5, 0,
        0, 2, 0, 0, 0, 0, 0, 3, 0,
        8, 6, 0, 0, 2, 0, 0, 4, 1,
        0, 0, 0, 5, 0, 1, 0, 0, 0,
        7, 3, 0, 0, 8, 0, 0, 9, 5,
        0, 4, 0, 0, 0, 0, 0, 1, 0,
        0, 5, 7, 4, 0, 2, 6, 8, 0,
        0, 0, 0, 9, 0, 3, 0, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestFithImage) {
    std::string image_path = IMAGES_PATH + "/5.jpg";

    std::vector<int> expected_grid{
        0, 0, 0, 3, 0, 6, 0, 0, 0,
        0, 8, 3, 2, 0, 7, 1, 5, 0,
        0, 2, 0, 0, 0, 0, 0, 3, 0,
        8, 6, 0, 0, 2, 0, 0, 4, 1,
        0, 0, 0, 5, 0, 1, 0, 0, 0,
        7, 3, 0, 0, 8, 0, 0, 9, 5,
        0, 4, 0, 0, 0, 0, 0, 1, 0,
        0, 5, 7, 4, 0, 2, 6, 8, 0,
        0, 0, 0, 9, 0, 3, 0, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestSixthImage) {
    std::string image_path = IMAGES_PATH + "/6.jpg";

    std::vector<int> expected_grid{
        0, 0, 0, 3, 0, 6, 0, 0, 0,
        0, 8, 3, 2, 0, 7, 1, 5, 0,
        0, 2, 0, 0, 0, 0, 0, 3, 0,
        8, 6, 0, 0, 2, 0, 0, 4, 1,
        0, 0, 0, 5, 0, 1, 0, 0, 0,
        7, 3, 0, 0, 8, 0, 0, 9, 5,
        0, 4, 0, 0, 0, 0, 0, 1, 0,
        0, 5, 7, 4, 0, 2, 6, 8, 0,
        0, 0, 0, 9, 0, 3, 0, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestSeventhImage) {
    std::string image_path = IMAGES_PATH + "/7.jpg";

    std::vector<int> expected_grid{
        0, 0, 1, 3, 0, 0, 6, 8, 9,
        0, 0, 8, 0, 9, 0, 0, 0, 0,
        9, 0, 0, 0, 4, 0, 0, 0, 0,
        0, 5, 9, 0, 0, 0, 0, 6, 0,
        0, 0, 7, 0, 0, 6, 0, 0, 1,
        0, 1, 0, 5, 7, 0, 9, 0, 0,
        0, 0, 0, 4, 0, 0, 7, 0, 0,
        7, 0, 0, 0, 0, 9, 0, 0, 0,
        0, 4, 6, 1, 3, 0, 5, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestEighthImage) {
    std::string image_path = IMAGES_PATH + "/8.jpg";

    std::vector<int> expected_grid{
        0, 0, 1, 3, 0, 0, 6, 8, 9,
        0, 0, 8, 0, 9, 0, 0, 0, 0,
        9, 0, 0, 0, 4, 0, 0, 0, 0,
        0, 5, 9, 0, 0, 0, 0, 6, 0,
        0, 0, 7, 0, 0, 6, 0, 0, 1,
        0, 1, 0, 5, 7, 0, 9, 0, 0,
        0, 0, 0, 4, 0, 0, 7, 0, 0,
        7, 0, 0, 0, 0, 9, 0, 0, 0,
        0, 4, 6, 1, 3, 0, 5, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestNinthImage) {
    std::string image_path = IMAGES_PATH + "/9.jpg";

    std::vector<int> expected_grid{
        0, 0, 1, 3, 0, 0, 6, 8, 9,
        0, 0, 8, 0, 9, 0, 0, 0, 0,
        9, 0, 0, 0, 4, 0, 0, 0, 0,
        0, 5, 9, 0, 0, 0, 0, 6, 0,
        0, 0, 7, 0, 0, 6, 0, 0, 1,
        0, 1, 0, 5, 7, 0, 9, 0, 0,
        0, 0, 0, 4, 0, 0, 7, 0, 0,
        7, 0, 0, 0, 0, 9, 0, 0, 0,
        0, 4, 6, 1, 3, 0, 5, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestTenthImage) {
    std::string image_path = IMAGES_PATH + "/10.jpg";

    std::vector<int> expected_grid{
        0, 0, 1, 3, 0, 0, 6, 8, 9,
        0, 0, 8, 0, 9, 0, 0, 0, 0,
        9, 0, 0, 0, 4, 0, 0, 0, 0,
        0, 5, 9, 0, 0, 0, 0, 6, 0,
        0, 0, 7, 0, 0, 6, 0, 0, 1,
        0, 1, 0, 5, 7, 0, 9, 0, 0,
        0, 0, 0, 4, 0, 0, 7, 0, 0,
        7, 0, 0, 0, 0, 9, 0, 0, 0,
        0, 4, 6, 1, 3, 0, 5, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestEleventhImage) {
    std::string image_path = IMAGES_PATH + "/11.jpg";

    std::vector<int> expected_grid{
        0, 0, 0, 2, 3, 0, 0, 0, 0,
        0, 6, 7, 0, 0, 0, 9, 2, 0,
        0, 9, 0, 0, 0, 7, 0, 3, 0,
        0, 0, 4, 0, 7, 0, 0, 0, 8,
        6, 0, 0, 4, 0, 2, 0, 0, 1,
        7, 0, 0, 0, 1, 0, 6, 0, 0,
        0, 7, 0, 6, 0, 0, 0, 1, 0,
        0, 1, 8, 0, 0, 0, 3, 7, 0,
        0, 0, 0, 0, 5, 1, 0, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestTwelfthImage) {
    std::string image_path = IMAGES_PATH + "/12.jpg";

    std::vector<int> expected_grid{
        0, 0, 0, 0, 5, 0, 0, 7, 0,
        0, 0, 0, 3, 0, 0, 2, 5, 0,
        0, 0, 0, 0, 0, 4, 0, 3, 8,
        0, 0, 0, 0, 7, 6, 4, 0, 3,
        1, 0, 0, 0, 0, 0, 0, 0, 2,
        9, 0, 3, 2, 8, 0, 0, 0, 0,
        4, 5, 0, 1, 0, 0, 0, 0, 0,
        0, 8, 6, 0, 0, 5, 0, 0, 0,
        0, 7, 0, 0, 9, 0, 0, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestThirteenthImage) {
    std::string image_path = IMAGES_PATH + "/13.jpg";

    std::vector<int> expected_grid{
        5, 3, 0, 0, 7, 0, 0, 0, 0,
        6, 0, 0, 1, 9, 5, 0, 0, 0,
        0, 9, 8, 0, 0, 0, 0, 6, 0,
        8, 0, 0, 0, 6, 0, 0, 0, 3,
        4, 0, 0, 8, 0, 3, 0, 0, 1,
        7, 0, 0, 0, 2, 0, 0, 0, 6,
        0, 6, 0, 0, 0, 0, 2, 8, 0,
        0, 0, 0, 4, 1, 9, 0, 0, 5,
        0, 0, 0, 0, 8, 0, 0, 7, 9};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestFourteethImage) {
    std::string image_path = IMAGES_PATH + "/14.jpg";

    std::vector<int> expected_grid{
        5, 3, 0, 0, 7, 0, 0, 0, 0,
        6, 0, 0, 1, 9, 5, 0, 0, 0,
        0, 9, 8, 0, 0, 0, 0, 6, 0,
        8, 0, 0, 0, 6, 0, 0, 0, 3,
        4, 0, 0, 8, 0, 3, 0, 0, 1,
        7, 0, 0, 0, 2, 0, 0, 0, 6,
        0, 6, 0, 0, 0, 0, 2, 8, 0,
        0, 0, 0, 4, 1, 9, 0, 0, 5,
        0, 0, 0, 0, 8, 0, 0, 7, 9};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestFifteenthImage) {
    std::string image_path = IMAGES_PATH + "/15.jpg";

    std::vector<int> expected_grid{
        5, 3, 0, 0, 7, 0, 0, 0, 0,
        6, 0, 0, 1, 9, 5, 0, 0, 0,
        0, 9, 8, 0, 0, 0, 0, 6, 0,
        8, 0, 0, 0, 6, 0, 0, 0, 3,
        4, 0, 0, 8, 0, 3, 0, 0, 1,
        7, 0, 0, 0, 2, 0, 0, 0, 6,
        0, 6, 0, 0, 0, 0, 2, 8, 0,
        0, 0, 0, 4, 1, 9, 0, 0, 5,
        0, 0, 0, 0, 8, 0, 0, 7, 9};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestSixteenthImage) {
    std::string image_path = IMAGES_PATH + "/16.jpg";

    std::vector<int> expected_grid{
        5, 3, 0, 0, 7, 0, 0, 0, 0,
        6, 0, 0, 1, 9, 5, 0, 0, 0,
        0, 9, 8, 0, 0, 0, 0, 6, 0,
        8, 0, 0, 0, 6, 0, 0, 0, 3,
        4, 0, 0, 8, 0, 3, 0, 0, 1,
        7, 0, 0, 0, 2, 0, 0, 0, 6,
        0, 6, 0, 0, 0, 0, 2, 8, 0,
        0, 0, 0, 4, 1, 9, 0, 0, 5,
        0, 0, 0, 0, 8, 0, 0, 7, 9};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestSeventeenthImage) {
    std::string image_path = IMAGES_PATH + "/17.jpg";

    std::vector<int> expected_grid{
        5, 3, 0, 0, 7, 0, 0, 0, 0,
        6, 0, 0, 1, 9, 5, 0, 0, 0,
        0, 9, 8, 0, 0, 0, 0, 6, 0,
        8, 0, 0, 0, 6, 0, 0, 0, 3,
        4, 0, 0, 8, 0, 3, 0, 0, 1,
        7, 0, 0, 0, 2, 0, 0, 0, 6,
        0, 6, 0, 0, 0, 0, 2, 8, 0,
        0, 0, 0, 4, 1, 9, 0, 0, 5,
        0, 0, 0, 0, 8, 0, 0, 7, 9};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestEighteenthImage) {
    std::string image_path = IMAGES_PATH + "/18.jpg";

    std::vector<int> expected_grid{
        5, 3, 0, 0, 7, 0, 0, 0, 0,
        6, 0, 0, 1, 9, 5, 0, 0, 0,
        0, 9, 8, 0, 0, 0, 0, 6, 0,
        8, 0, 0, 0, 6, 0, 0, 0, 3,
        4, 0, 0, 8, 0, 3, 0, 0, 1,
        7, 0, 0, 0, 2, 0, 0, 0, 6,
        0, 6, 0, 0, 0, 0, 2, 8, 0,
        0, 0, 0, 4, 1, 9, 0, 0, 5,
        0, 0, 0, 0, 8, 0, 0, 7, 9};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestNineteenthImage) {
    std::string image_path = IMAGES_PATH + "/19.jpg";

    std::vector<int> expected_grid{
        0, 0, 0, 3, 0, 6, 0, 0, 0,
        0, 8, 3, 2, 0, 7, 1, 5, 0,
        0, 2, 0, 0, 0, 0, 0, 3, 0,
        8, 6, 0, 0, 2, 0, 0, 4, 1,
        0, 0, 0, 5, 0, 1, 0, 0, 0,
        7, 3, 0, 0, 8, 0, 0, 9, 5,
        0, 4, 0, 0, 0, 0, 0, 1, 0,
        0, 5, 7, 4, 0, 2, 6, 8, 0,
        0, 0, 0, 9, 0, 3, 0, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestTwentiethImage) {
    std::string image_path = IMAGES_PATH + "/20.jpg";

    std::vector<int> expected_grid{
        0, 0, 0, 3, 0, 6, 0, 0, 0,
        0, 8, 3, 2, 0, 7, 1, 5, 0,
        0, 2, 0, 0, 0, 0, 0, 3, 0,
        8, 6, 0, 0, 2, 0, 0, 4, 1,
        0, 0, 0, 5, 0, 1, 0, 0, 0,
        7, 3, 0, 0, 8, 0, 0, 9, 5,
        0, 4, 0, 0, 0, 0, 0, 1, 0,
        0, 5, 7, 4, 0, 2, 6, 8, 0,
        0, 0, 0, 9, 0, 3, 0, 0, 0};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestTwentyfirstImage) {
    std::string image_path = IMAGES_PATH + "/21.jpg";

    std::vector<int> expected_grid{
        4, 6, 0, 2, 0, 0, 0, 0, 0,
        0, 0, 1, 6, 9, 0, 0, 0, 0,
        0, 7, 8, 0, 0, 0, 0, 0, 0,
        0, 0, 4, 0, 8, 0, 0, 0, 1,
        9, 0, 0, 0, 0, 0, 0, 0, 7,
        7, 0, 0, 0, 4, 0, 3, 0, 0,
        0, 0, 0, 0, 0, 0, 6, 8, 0,
        0, 0, 0, 0, 5, 9, 2, 0, 0,
        0, 0, 0, 0, 0, 6, 0, 9, 3};

    test_on_image(image_path, expected_grid);
}

TEST(IntegrationTest, TestTwentysecondImage) {
    std::string image_path = IMAGES_PATH + "/22.jpg";

    std::vector<int> expected_grid{
        0, 3, 9, 1, 0, 0, 0, 0, 0,
        4, 0, 8, 0, 6, 0, 0, 0, 2,
        2, 0, 0, 5, 8, 0, 7, 0, 0,
        8, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 2, 0, 0, 0, 9, 0, 0, 0,
        3, 0, 6, 0, 0, 0, 0, 4, 9,
        0, 0, 0, 0, 1, 0, 0, 3, 0,
        0, 4, 0, 3, 0, 0, 0, 0, 8,
        7, 0, 0, 0, 0, 0, 4, 0, 0};

    test_on_image(image_path, expected_grid);
}

int main(int argc, char **argv) {
    testing::InitGoogleTest(&argc, argv);
    ss::set_model((char *)MODEL_PATH.c_str());
    return RUN_ALL_TESTS();
}
