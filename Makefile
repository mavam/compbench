BENCHMARK = benchmark

all: bench pcap-plots bro-plots

bench: benchmark.cpp
	c++ -std=c++11 -stdlib=libc++ -O3 -Wall -o $(BENCHMARK) $< bundle/bundle.cpp

pcap-bench:
	./benchmark < data/pcap/2009-M57-day11-18-10k.pcap > pcap.log

pcap-plots: pcap.log
	cd screenshots; ../plot pcap < ../pcap.log

bro-bench:
	cat data/bro/*.log | ./benchmark > bro.log

bro-plots: bro.log
	cd screenshots; ../plot bro < ../bro.log

clean:
	rm -f $(BENCHMARK) pcap.log bro.log

.PHONY: bench pcap-bench pcap-plots bro-bench bro-plots clean
