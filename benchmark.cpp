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

#include <zlib.h>

#include <chrono>
#include <iterator>
#include <iostream>
#include <vector>

#if defined(__MSVCRT__) || defined(__OS2__) || defined(_MSC_VER)
#include <fcntl.h>
#include <io.h>
#endif

#include "bundle/bundle.hpp"

// Abstracts an algorithm with compression and decompression functionality.
template <class Algorithm>
struct algorithm;

// The DEFLATE algorithm.
template <unsigned Algorithm>
struct gzip { };

// An algorithm from bundle.
template <int Level>
struct other { };

// Specialization for bundle.
template <unsigned Algorithm>
struct algorithm<other<Algorithm>> {
  static std::string name() {
    return bundle::name_of(Algorithm);
  }

  template <class Input, class Output>
  static size_t compress(Input const& in, Output& out) {
    out.resize(bundle::bound(Algorithm, in.size()));
    auto out_size = out.size();
    auto result = bundle::pack(Algorithm, &in[0], in.size(), &out[0], out_size);
    // There's an issue with bundle's notion of successful packing. The
    // function pack() returns true iff the output is strictly smaller than the
    // input. This is obviously not true for RAW, which is why we exclude it.
    if (Algorithm == bundle::RAW)
      return in.size();
    if (!result)
      throw std::runtime_error{"bundle compression failed"};
    return out_size;
  }

  template <class Input, class Output>
  static size_t uncompress(Input const& in, Output& out) {
    size_t out_size = out.size();
    if (!bundle::unpack(Algorithm, &in[0], in.size(), &out[0], out_size))
      throw std::runtime_error{"bundle decompression failed"};
    return out_size;
  }
};

// Specialization for zlib.
template <int Level>
struct algorithm<gzip<Level>> {
  static std::string name() {
    return "DEFLATE:" + std::to_string(Level);
  }

  template <class Input, class Output>
  static size_t compress(Input const& in, Output& out) {
    out.resize(compressBound(in.size()));
    uLongf out_size = out.size();
    auto result = compress2(
      reinterpret_cast<Bytef*>(&out[0]), &out_size,
      reinterpret_cast<Bytef const*>(in.data()), in.size(), Level);
    if (result != Z_OK)
      throw std::runtime_error{"zlib compression failed"};
    return out_size;
  }

  template <class Input, class Output>
  static size_t uncompress(Input const& in, Output& out) {
    using ::uncompress;
    uLongf out_size = out.size();
    auto result = uncompress(
      reinterpret_cast<Bytef*>(&out[0]), &out_size,
      reinterpret_cast<Bytef const*>(in.data()), in.size());
    if (result != Z_OK)
      throw std::runtime_error{"zlib uncompression failed"};
    return out_size;
  }
};

template <class Algorithm, class Buffer>
void run(Buffer const& buffer) {
  using clock = std::chrono::high_resolution_clock;
  auto to_mus = [](std::chrono::high_resolution_clock::duration d) {
    return std::chrono::duration_cast<std::chrono::microseconds>(d).count();
  };
  Buffer packed;
  packed.resize(buffer.size() * 2); // avoid hitting the allocator later
  auto pack_start = clock::now();
  auto packed_size = Algorithm::compress(buffer, packed);
  auto pack_stop = clock::now();
  packed.resize(packed_size);
  Buffer unpacked;
  unpacked.resize(buffer.size());
  auto unpack_start = clock::now();
  auto unpacked_size = Algorithm::uncompress(packed, unpacked);
  auto unpack_stop = clock::now();
  std::cout << Algorithm::name() << '\t'
            << buffer.size() << '\t'
            << packed_size << '\t'
            << unpacked_size << '\t'
            << to_mus(pack_stop - pack_start) << '\t'
            << to_mus(unpack_stop - unpack_start) << std::endl;
}

auto main() -> int {
  // Force binary std::cin on a few platforms.
#if defined(__MSVCRT__) || defined(__OS2__) || defined(_MSC_VER)
  setmode(fileno(stdin), O_BINARY);
  setmode(fileno(stdout), O_BINARY);
#endif
  std::string buffer{std::istreambuf_iterator<char>{std::cin},
                      std::istreambuf_iterator<char>{}};
  std::cout << "Algorithm\tRaw\tPacked\tUnpacked\tCompression\tDecompression\n";
  // Run all bundle algorithms except for SHOCO, which only works with ASCII
  // data.
  run<algorithm<other<bundle::RAW>>>(buffer);
  run<algorithm<other<bundle::LZ4F>>>(buffer);
  run<algorithm<other<bundle::MINIZ>>>(buffer);
  run<algorithm<other<bundle::LZIP>>>(buffer);
  run<algorithm<other<bundle::LZMA20>>>(buffer);
  run<algorithm<other<bundle::ZPAQ>>>(buffer);
  run<algorithm<other<bundle::LZ4>>>(buffer);
  run<algorithm<other<bundle::BROTLI9>>>(buffer);
  run<algorithm<other<bundle::ZSTD>>>(buffer);
  run<algorithm<other<bundle::LZMA25>>>(buffer);
  run<algorithm<other<bundle::BSC>>>(buffer);
  run<algorithm<other<bundle::BROTLI11>>>(buffer);
  run<algorithm<other<bundle::SHRINKER>>>(buffer);
  run<algorithm<other<bundle::CSC20>>>(buffer);
  run<algorithm<other<bundle::ZSTDF>>>(buffer);
  run<algorithm<other<bundle::BCM>>>(buffer);
  run<algorithm<other<bundle::ZLING>>>(buffer);
  run<algorithm<other<bundle::MCM>>>(buffer);
  run<algorithm<other<bundle::TANGELO>>>(buffer);
  run<algorithm<other<bundle::ZMOLLY>>>(buffer);
  // Run gzip.
  run<algorithm<gzip<1>>>(buffer);
  run<algorithm<gzip<9>>>(buffer);
}
