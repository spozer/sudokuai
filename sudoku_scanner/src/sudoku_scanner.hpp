struct Offset {
    double x;
    double y;
};

struct BoundingBox {
    Offset top_left = Offset{0, 0};
    Offset top_right = Offset{1, 0};
    Offset bottom_left = Offset{0, 1};
    Offset bottom_right = Offset{1, 1};
};

extern "C" {
struct BoundingBox *detect_grid(char *path);

int *extract_grid(char *path, BoundingBox *bounding_box);

int *extract_grid_from_roi(char *path, int roi_size, int roi_offset);

bool debug_grid_detection(char *path);

bool debug_grid_extraction(char *path, BoundingBox *bounding_box);

void set_model(char *path);

void free_pointer(int *pointer);
}
