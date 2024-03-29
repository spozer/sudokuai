#ifndef SUDOKU_SCANNER_H
#define SUDOKU_SCANNER_H

#ifdef __cplusplus
#define FFI_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#include <cstdint>
using std::int32_t;
#else
#include <stdint.h>
#define FFI_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

struct Offset {
    double x;
    double y;
};

struct BoundingBox {
    struct Offset top_left;
    struct Offset top_right;
    struct Offset bottom_left;
    struct Offset bottom_right;
};

FFI_EXPORT struct BoundingBox *detect_grid(char *path);

FFI_EXPORT int32_t *extract_grid(char *path, struct BoundingBox *bounding_box);

FFI_EXPORT int32_t *extract_grid_from_roi(char *path, int32_t roi_size, int32_t roi_offset);

FFI_EXPORT void set_model(char *path);

FFI_EXPORT void free_pointer(int32_t *pointer);

#endif