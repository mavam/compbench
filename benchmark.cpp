// Small benchmark utility that reads data from standard input into a buffer
// and then applies an array of compression algorithms to it.

#include <chrono>
#include <iterator>
#include <iostream>
#include <vector>

#if defined(__MSVCRT__) || defined(__OS2__) || defined(_MSC_VER)
#include <fcntl.h>
#include <io.h>
#endif

#include "bundle/bundle.hpp"

using namespace bundle;

auto main() -> int {

#if defined(__MSVCRT__) || defined(__OS2__) || defined(_MSC_VER)
  setmode( fileno( stdin ), O_BINARY );
  setmode( fileno( stdout ), O_BINARY );
#endif

  std::string buffer { std::istreambuf_iterator<char>{std::cin},
                       std::istreambuf_iterator<char>{}};

  std::vector<unsigned> libs{RAW, LZ4, LZ4HC, SHOCO, MINIZ, LZMA20, LZIP,
                             LZMA25, BROTLI9, BROTLI11, ZSTD, BSC};
  std::cout << "algorithm\traw\tpacked\tunpacked\tcompression\tdecompression\n";
  for (auto& use : libs) {
    auto pack_start = std::chrono::high_resolution_clock::now();
    auto packed = pack(use, buffer);
    auto pack_stop = std::chrono::high_resolution_clock::now();
    auto unpack_start = std::chrono::high_resolution_clock::now();
    auto unpacked = unpack(packed);
    auto unpack_stop = std::chrono::high_resolution_clock::now();
    if( buffer == unpacked ) // log if ok (shoco will fail on binary input!)
    std::cout << name_of(use) << '\t'
              << buffer.size() << '\t'
              << packed.size() << '\t'
              << unpacked.size() << '\t'
              << (pack_stop - pack_start).count() << '\t'
              << (unpack_stop - unpack_start).count() << std::endl;
  }
}
