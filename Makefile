BENCH = benchmark

all: bench pcap-bench bro-bench pcap-plots bro-plots

bench: benchmark.cpp
	c++ -std=c++11 -stdlib=libc++ -O3 -Wall -o $(BENCH) $< bundle/bundle.cpp -lz

pcap-bench:
	./benchmark < data/pcap/2009-M57-day11-18-10k.pcap > pcap.log

pcap-plots: pcap.log
	cd screenshots; ../plot pcap < ../pcap.log

bro-bench:
	cat data/bro/*.log | ./benchmark > bro.log

bro-plots: bro.log
	cd screenshots; ../plot bro < ../bro.log

clean:
	rm -f $(BENCH) pcap.log bro.log

.PHONY: bench pcap-bench pcap-plots bro-bench bro-plots clean
