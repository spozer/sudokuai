#ifndef GRID_HPP
#define GRID_HPP

#include <algorithm>
#include <cstdint>
#include <new>
#include <stdexcept>
#include <utility>

struct Grid {
    const std::size_t rows = 9;
    const std::size_t cols = 9;
    const std::size_t size = rows * cols;
    std::uint8_t* data = nullptr;

    Grid() {
        data = new std::uint8_t[size]();
    }

    // copy constructor
    Grid(const Grid& other) {
        if (other.data) {
            data = new std::uint8_t[size]();
            std::copy(other.data, other.data + other.size, data);
        }
    }

    // move constructor
    Grid(Grid&& other) {
        std::swap(data, other.data);
    }

    ~Grid() {
        delete[] data;
    }

    std::uint8_t& operator[](int index) {
        if (!data || index < 0 || index >= size) {
            throw std::out_of_range("Grid[] : index(" + std::to_string(index) + ") is out of range");
        }

        return data[index];
    }

    std::uint8_t operator[](int index) const {
        if (!data || index < 0 || index >= size) {
            throw std::out_of_range("const Grid[] : index(" + std::to_string(index) + ") is out of range");
        }

        return data[index];
    }

    // copy assignment operator
    Grid& operator=(const Grid& other) {
        if (&other != this) {
            Grid temp(other);  // makes copy
            std::swap(data, temp.data);
        }
        return *this;
    }

    // move assignment operator
    Grid& operator=(Grid&& other) {
        Grid temp(std::move(other));  // moves the array
        std::swap(data, temp.data);
        return *this;
    }

    // removes ownership of data for this object
    std::uint8_t* get_ownership() {
        auto pointer = data;
        data = nullptr;
        return pointer;
    }
};

#endif
