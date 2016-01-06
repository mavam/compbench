BENCHMARK = benchmark

FLAGS = -std=c++11 -stdlib=libc++ -O3 -Wall
LIBS = -lz -lbz2

all: bench pcap-bench bro-bench pcap-plots bro-plots

bundle.o: bundle/bundle.cpp
	c++ $(FLAGS) -c $< -o bundle.o

bench: benchmark.cpp bundle.o
	c++ $(FLAGS) -o $(BENCHMARK) bundle.o $< $(LIBS)

pcap-bench:
	./benchmark < data/pcap/2009-M57-day11-18-10k.pcap > pcap.log

pcap-plots: pcap.log
	cd screenshots; ../plot pcap < ../pcap.log

bro-bench:
	cat data/bro/*.log | ./benchmark > bro.log

bro-plots: bro.log
	cd screenshots; ../plot bro < ../bro.log

clean:
	rm -f $(BENCHMARK) bundle.o pcap.log bro.log

.PHONY: bench pcap-bench pcap-plots bro-bench bro-plots clean
