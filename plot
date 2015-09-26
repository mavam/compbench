#!/usr/bin/env Rscript
#
# Copyright (c) 2015, Matthias Vallentin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     1. Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#
#     2. Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#
#     3. Neither the name of the copyright holder nor the names of its
#        contributors may be used to endorse or promote products derived from
#        this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

suppressMessages(library(dplyr))
suppressMessages(library(ggplot2))
suppressMessages(library(scales))
suppressMessages(library(tidyr))

ingest <- function(filename) {
  read.table(filename, header=TRUE) %>%
    mutate(Algorithm=factor(Algorithm), Ratio=Raw/Packed,
           Savings=1-Packed/Raw,
           Throughput.Compression=(Raw/2^20)/(Compression/1e6),
           Throughput.Decompression=(Packed/2^20)/(Decompression/1e6))
}

plot.tradeoff <- function(data) {
  data %>%
    ggplot(aes(x=Savings, y=Throughput.Compression, color=Algorithm)) +
      geom_point(aes(shape=Algorithm), size=4) +
      scale_shape_manual(values=1:nrow(data)) +
      scale_x_continuous(labels=percent) +
      scale_y_log10(breaks=10^(0:10), labels=comma) +
      labs(x="Space Savings", y="Throughput (MB/second)") +
      ggtitle("Savings vs. Throughput")
}

plot.throughput.scatter <- function(data) {
  data %>%
    ggplot(aes(x=Throughput.Compression, y=Throughput.Decompression)) +
      geom_point(aes(shape=Algorithm, color=Algorithm), size=4) +
      geom_abline(slope=1, color="grey") +
      scale_x_log10(breaks=10^(0:10), labels=comma) +
      scale_y_log10(breaks=10^(0:10), labels=comma) +
      scale_shape_manual(values=1:nrow(data)) +
      labs(x="Compression (MB/sec)", y="Decompression (MB/sec)") +
      ggtitle("Throughput")
}

plot.throughput.bars <- function(data) {
  data %>%
    mutate(Algorithm=reorder(Algorithm, -Throughput.Compression)) %>%
    gather(key, value, Throughput.Compression, Throughput.Decompression) %>%
    ggplot(aes(x=Algorithm, y=value*1e3, fill=key)) +
      geom_bar(stat="identity", position="dodge") +
      labs(x="Algorithm", y="Throughput (MB/sec)") +
      scale_y_log10(breaks=10^(0:10), labels=function(x) comma(x/1e3)) +
      scale_fill_discrete(name="", labels=c("Compression", "Decompression")) +
      theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5),
            legend.position="top")
}

plot.ratio <- function(data) {
  data %>%
    mutate(Throughput=Throughput.Compression) %>%
    filter(Algorithm != "NONE") %>%
    ggplot(aes(x=reorder(Algorithm, -Ratio), y=Ratio)) +
      geom_bar(aes(fill=Throughput), stat="identity") +
      labs(x="Algorithm", y="Compression Ratio") +
      theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5))
}

theme_set(theme_bw())
options(scipen=1e6)

data <- ingest(file("stdin"))
dump <- function(filename, plot) { ggsave(filename, plot, height=10, width=10) }
dump("tradeoff.png", plot.tradeoff(data))
dump("throughput-scatter.png", plot.throughput.scatter(data))
dump("throughput-bars.png", plot.throughput.bars(data))
dump("compression-ratio.png", plot.ratio(data))
