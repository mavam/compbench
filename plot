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
  data <- read.table(filename, header=TRUE)
  tbl_df(data)
}

plot.tradeoff <- function(data) {
  data %>%
    mutate(Algorithm=factor(algorithm), Compression=packed/raw,
           Speed=(compression+decompression)/1e6) %>%
    ggplot(aes(x=Compression, y=Speed, color=Algorithm, shape=Algorithm)) +
      geom_point(size=4) +
      scale_shape_manual(values=1:nrow(data)) +
      scale_y_log10(breaks=10^(0:10), labels=comma) +
      labs(x="Compression", y="Speed (ms)") +
      ggtitle("Compression vs. Speed")
}

plot.ratio <- function(data) {
  data %>%
    mutate(Ratio=packed/raw) %>%
    ggplot(aes(x=reorder(algorithm, Ratio), y=Ratio, fill=algorithm)) +
      geom_bar(stat="identity") +
      guides(fill=FALSE) +
      labs(x="Algorithm", y="Compression Ratio") +
      theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5))
}

plot.speed.scatter <- function(data) {
  ggplot(data, aes(x=compression/1e6, y=decompression/1e6,
                   color=algorithm, shape=algorithm)) +
    geom_point(size=4) +
    scale_x_log10(breaks=10^(0:10), labels=comma) +
    scale_y_log10(breaks=10^(0:10), labels=comma) +
    scale_shape_manual(values=1:nrow(data)) +
    labs(x="Compression (ms)", y="Decompression (ms)") +
    ggtitle("Speed: Compression vs. Decompression")
}

plot.speed.bar <- function(data) {
  data %>%
    gather(key, value, compression, decompression) %>%
    ggplot(aes(x=algorithm, y=value/1e3, fill=key)) +
      geom_bar(stat="identity", position="dodge") +
      labs(x="Algorithm", y="Speed (us)") +
      scale_y_log10(breaks=10^(0:10), labels=comma) +
      scale_fill_discrete(name="", labels=c("Compression", "Decompression")) +
      theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5),
            legend.position="top")
}

theme_set(theme_bw())
options(scipen=1e6)

data <- ingest(file("stdin"))
dump <- function(filename, plot) { ggsave(filename, plot, height=10, width=10) }
dump("tradeoff.png", plot.tradeoff(data))
dump("speed-scatter.png", plot.speed.scatter(data))
dump("speed-bar.png", plot.speed.bar(data))
dump("ratio.png", plot.ratio(data))
