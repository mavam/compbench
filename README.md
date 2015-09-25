A benchmark utility to examine and compare various compression algorithms.

### Usage

Build with `make` and the run as follows:

    ./benchmark < input > log

where `input` is the data you want to run through the compressors.
Thereafter, generate the plots:

    ./plot < log

This generates several PDFs in the current directory for your perusal.
