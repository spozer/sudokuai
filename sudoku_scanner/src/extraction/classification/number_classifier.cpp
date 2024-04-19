#include "number_classifier.hpp"

#include <tensorflow/lite/c/c_api.h>

#include <opencv2/imgproc.hpp>
#include <string>
#include <vector>

#include "../../dictionary/dictionary.hpp"
#include "../structs/cell.hpp"

#ifdef __ANDROID__
#include <android/log.h>
#endif

// TODO: use tflite with gpu delegates https://www.tensorflow.org/lite/android/delegates/gpu_native#java
// https://central.sonatype.com/artifact/org.tensorflow/tensorflow-lite-gpu/2.6.0/versions

void NumberClassifier::predict_numbers(std::vector<Cell> &cells) {
    cv::Mat input;
    std::vector<float> output(9, 0.0);
    std::string path_to_model = std::getenv(PATH_TO_MODEL_ENV_VAR);

    // create the model and interpreter options
    TfLiteModel *model = TfLiteModelCreateFromFile(path_to_model.data());
    TfLiteInterpreterOptions *options = TfLiteInterpreterOptionsCreate();
    TfLiteInterpreterOptionsSetNumThreads(options, 2);

    // create the interpreter
    TfLiteInterpreter *interpreter = TfLiteInterpreterCreate(model, options);

    // allocate tensors
    TfLiteInterpreterAllocateTensors(interpreter);
    TfLiteTensor *input_tensor = TfLiteInterpreterGetInputTensor(interpreter, 0);
    const TfLiteTensor *output_tensor = TfLiteInterpreterGetOutputTensor(interpreter, 0);

    for (Cell &cell : cells) {
        // prepare cell image
        cv::resize(cell.img, input, cv::Size(28, 28));
        input.convertTo(input, CV_32FC1);
        input /= 255.0;

        // load input data into model
        TfLiteTensorCopyFromBuffer(input_tensor, input.data, input.rows * input.cols * sizeof(float));
        // execute inference
        TfLiteInterpreterInvoke(interpreter);
        // extract the output tensor data
        TfLiteTensorCopyToBuffer(output_tensor, output.data(), output.size() * sizeof(float));

        // interpret output
        int number = arg_max(output) + 1;
        cell.number = number;

#ifdef __ANDROID__
#ifndef NDEBUG
        float confidence = output[number - 1] * 100;
        std::string debug = "(" + std::to_string(cell.x) + ", " + std::to_string(cell.y) + ") " + std::to_string(number) + " [" + std::to_string(confidence) + "%]";
        __android_log_print(ANDROID_LOG_DEBUG, "predict_numbers", "%s", debug.c_str());
#endif
#endif
    }
    // dispose of the model and interpreter objects
    TfLiteInterpreterDelete(interpreter);
    TfLiteInterpreterOptionsDelete(options);
    TfLiteModelDelete(model);
}

int NumberClassifier::arg_max(std::vector<float> &list) {
    float max = 0.0;
    int index = -1;

    for (int i = 0; i < list.size(); ++i) {
        if (list[i] > max) {
            max = list[i];
            index = i;
        }
    }

    return index;
}
