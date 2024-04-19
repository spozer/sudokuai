# sudoku_scanner

This is a [FFI Flutter plugin](https://docs.flutter.dev/platform-integration/android/c-interop) written in C/C++ using OpenCV and Tensorflow Lite.

## Project structure

* `src`: Contains the native source code, and a CmakeFile.txt file for building that source code into a dynamic library.

* `lib`: Contains the Dart code that defines the API of the plugin, and which calls into the native code using `dart:ffi`.

* `android`: Contains the build files and JNI libraries for building and bundling the native code library with the platform application.

* `dev`: Contains source code and 3rd party libraries for debugging and testing the native code under Linux.

## How to build

Run `setup.sh` to download and install the needed JNI libraries for Android. It installs the JNI libraries to `android/src/main/jniLibs/${ANDROID_ABI}` and the third-party headers to `includes/opencv2` and `includes/tensorflow/lite`.

For debugging and testing under Linux, you need to manually compile the libraries for [OpenCV](https://docs.opencv.org/4.x/d7/d9f/tutorial_linux_install.html) and [Tensorflow Lite](https://www.tensorflow.org/lite/guide/build_cmake#build_tensorflow_lite_c_library) and move them to `linux/libs/opencv` and `linux/libs/tensorflowlite` respectively.

Debugging:
``` bash
cd dev/build
cmake [-G Ninja] ..
cmake --build .
./sudoku_scanner_dev
```

Testing:
``` bash
cd test/build
cmake [-G Ninja] ..
cmake --build .
ctest [or ninja test]
```

## Binding to native code

To use the native code, bindings in Dart are needed. To avoid writing these by hand, they are generated from the header file (`src/sudoku_scanner.h`) by `package:ffigen`. Regenerate the bindings by running `flutter pub run ffigen --config ffigen.yaml`.
