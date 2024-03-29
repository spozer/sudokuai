#ifndef NUMBER_CLASSIFIER_HPP
#define NUMBER_CLASSIFIER_HPP

#include <vector>

#include "../structs/cell.hpp"

class NumberClassifier {
   public:
    static void predict_numbers(std::vector<Cell> &cells);

   private:
    NumberClassifier() = delete;
    static int arg_max(std::vector<float> &list);
};

#endif
