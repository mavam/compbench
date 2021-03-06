FLAGS = -std=c++11 -stdlib=libc++ -O3 -Wall

all: benchmark pcap-bench bro-bench pcap-plots bro-plots

pcap: pcap-bench pcap-plots

bro: bro-bench bro-plots

plots: bro-plots pcap-plots

bundle.o: bundle/bundle.cpp
	c++ $(FLAGS) -c $< -o bundle.o

benchmark: benchmark.cpp bundle.o
	c++ $(FLAGS) -o $@ bundle.o $< -lz -lbz2

pcap-bench:
	./benchmark < data/pcap/2009-M57-day11-18-10k.pcap > pcap.log

pcap-plots: pcap.log
	cd screenshots; ../plot pcap < ../pcap.log

bro-bench:
	cat data/bro/*.log | ./benchmark > bro.log

bro-plots: bro.log
	cd screenshots; ../plot bro < ../bro.log

clean:
	rm -f bundle.o benchmark pcap.log bro.log

.PHONY: all bro pcap plots bro-bench bro-plots pcap-bench pcap-plots clean
