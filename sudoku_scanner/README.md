# sudoku_scanner

TODO: describe how to setup for developing and running this plugin
setup.sh -- installiert notwendige android jni und includes (für tensorflow fehlen einige includes z.B. core/async/c/*)
TODO: setup für dev libs -- opencv und tensorflow lite selber compilen (automatisieren?)
opencv: https://docs.opencv.org/4.x/d7/d9f/tutorial_linux_install.html
tflite: https://www.tensorflow.org/lite/guide/build_cmake#build_tensorflow_lite_c_library

TODO: nur libs importen von opencv die auch gebraucht werden (core imgprocs imgcodecs) -> kein #incldue <opencv2/opencv.hpp>

TODO: tflite mit gpu delegates https://www.tensorflow.org/lite/android/delegates/gpu_native#java
https://central.sonatype.com/artifact/org.tensorflow/tensorflow-lite-gpu/2.6.0/versions

TODO: int32_t statt int benutzen oder sogar kleiner int8_t wo geht

A new Flutter FFI plugin project.

## Getting Started

This project is a starting point for a Flutter
[FFI plugin](https://docs.flutter.dev/development/platform-integration/c-interop),
a specialized package that includes native code directly invoked with Dart FFI.

## Project structure

This template uses the following structure:

* `src`: Contains the native source code, and a CmakeFile.txt file for building
  that source code into a dynamic library.

* `lib`: Contains the Dart code that defines the API of the plugin, and which
  calls into the native code using `dart:ffi`.

* platform folders (`android`, `ios`, `windows`, etc.): Contains the build files
  for building and bundling the native code library with the platform application.

## Building and bundling native code

The `pubspec.yaml` specifies FFI plugins as follows:

```yaml
  plugin:
    platforms:
      some_platform:
        ffiPlugin: true
```

This configuration invokes the native build for the various target platforms
and bundles the binaries in Flutter applications using these FFI plugins.

This can be combined with dartPluginClass, such as when FFI is used for the
implementation of one platform in a federated plugin:

```yaml
  plugin:
    implements: some_other_plugin
    platforms:
      some_platform:
        dartPluginClass: SomeClass
        ffiPlugin: true
```

A plugin can have both FFI and method channels:

```yaml
  plugin:
    platforms:
      some_platform:
        pluginClass: SomeName
        ffiPlugin: true
```

The native build systems that are invoked by FFI (and method channel) plugins are:

* For Android: Gradle, which invokes the Android NDK for native builds.
  * See the documentation in android/build.gradle.
* For iOS and MacOS: Xcode, via CocoaPods.
  * See the documentation in ios/sudoku_scanner.podspec.
  * See the documentation in macos/sudoku_scanner.podspec.
* For Linux and Windows: CMake.
  * See the documentation in linux/CMakeLists.txt.
  * See the documentation in windows/CMakeLists.txt.

## Binding to native code

To use the native code, bindings in Dart are needed.
To avoid writing these by hand, they are generated from the header file
(`src/sudoku_scanner.h`) by `package:ffigen`.
Regenerate the bindings by running `flutter pub run ffigen --config ffigen.yaml`.

## Invoking native code

Very short-running native functions can be directly invoked from any isolate.
For example, see `sum` in `lib/sudoku_scanner.dart`.

Longer-running functions should be invoked on a helper isolate to avoid
dropping frames in Flutter applications.
For example, see `sumAsync` in `lib/sudoku_scanner.dart`.

## Flutter help

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

