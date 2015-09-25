// Small benchmark utility that reads data from standard input into a buffer
// and then applies an array of compression algorithms to it.

#include <chrono>
#include <iterator>
#include <iostream>
#include <vector>

#include "bundle/bundle.hpp"

using namespace bundle;

auto main() -> int {
  bundle::string buffer;
  {
    std::string str{std::istreambuf_iterator<char>{std::cin},
                    std::istreambuf_iterator<char>{}};
    buffer = str; // no better way to construct a bundle::string?
  }
  std::vector<unsigned> libs{RAW, LZ4, LZ4HC, SHOCO, MINIZ, LZMA20, LZIP, LZMA25,
                             BROTLI9, BROTLI11, ZSTD, BSC};
  std::cout << "algorithm\traw\tpacked\tunpacked\tcompression\tdecompression\n";
  for (auto& use : libs) {
    auto pack_start = std::chrono::high_resolution_clock::now();
    auto packed = pack(use, buffer);
    auto pack_stop = std::chrono::high_resolution_clock::now();
    auto unpack_start = std::chrono::high_resolution_clock::now();
    auto unpacked = unpack(packed);
    auto unpack_stop = std::chrono::high_resolution_clock::now();
    std::cout << name_of(use) << '\t'
              << buffer.size() << '\t'
              << packed.size() << '\t'
              << unpacked.size() << '\t'
              << (pack_stop - pack_start).count() << '\t'
              << (unpack_stop - unpack_start).count() << std::endl;
  }
}
