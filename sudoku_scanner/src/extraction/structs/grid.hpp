#ifndef GRID_HPP
#define GRID_HPP

#include <cassert>
#include <cstdint>
#include <memory>
#include <new>

struct Grid {
    const std::size_t rows = 9;
    const std::size_t cols = 9;
    const std::size_t size = rows * cols;
    std::unique_ptr<std::uint8_t[]> data;

    Grid() : data(new std::uint8_t[size]()) {}

    // subscript operator
    std::uint8_t& operator[](std::size_t index) {
        assert(data && index < size);
        return data[index];
    }

    // const subscript operator
    std::uint8_t operator[](std::size_t index) const {
        assert(data && index < size);
        return data[index];
    }

    // removes ownership of data
    std::uint8_t* get_ownership() {
        return data.release();
    }
};

#endif
