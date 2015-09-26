// Copyright (c) 2015, Matthias Vallentin
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//
//     3. Neither the name of the copyright holder nor the names of its
//        contributors may be used to endorse or promote products derived from
//        this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

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
  // Force binary std::cin on a few platforms.
#if defined(__MSVCRT__) || defined(__OS2__) || defined(_MSC_VER)
  setmode(fileno(stdin), O_BINARY);
  setmode(fileno(stdout), O_BINARY);
#endif
  std::string buffer{std::istreambuf_iterator<char>{std::cin},
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
    // Since some implementations can fail (SHOCO on binary input), we only
    // report successful runs.
    if (buffer == unpacked)
      std::cout << name_of(use) << '\t'
                << buffer.size() << '\t'
                << packed.size() << '\t'
                << unpacked.size() << '\t'
                << (pack_stop - pack_start).count() << '\t'
                << (unpack_stop - unpack_start).count() << std::endl;
  }
}
