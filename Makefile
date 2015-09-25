all: benchmark.cpp
	c++ -std=c++11 -stdlib=libc++ -O3 -o benchmark $< bundle/bundle.cpp
