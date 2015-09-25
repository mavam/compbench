#!/usr/bin/env Rscript

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
