#
# Make a giant PDF out of an upload.
#
# To get a list of uploads:
#
#    Rscript --vanilla lots-of-data.R
#
# To make a pdf from one of those uploads:
#
#    Rscript --vanilla lots-of-data.R name-of-upload-shown-in-list
#

source("viewperf.R")
require(ggplot2, quietly=TRUE)

prettySize <- function(s, fmt="%.2f") {
  sizes <- c('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB')
  e <- floor(log(s, 1024))
  suffix <- sizes[e+1]
  prefix <- sprintf(fmt, s/(1024 ^ floor(e)))
  paste(prefix, suffix, sep="")
}

buildComparison <- function(df, field, value) {
  dfsub <- df[df[,field] == value,]
  colnames(dfsub)[7] <- 'comptime'
  rv <- merge(df, dfsub[,-(1:3)])
  rv <- transform(rv, xtime=time / comptime)
  rv[order(rv$build, rv$vbuckets, decreasing=TRUE),]
}

makeOne <- function(r, filename) {
  pdf(filename)

  r$software_v <- paste(r$build, r$vbuckets)
  r$software_v <- factor(r$software_v, levels=unique(r$software_v), ordered=TRUE)

  for(items in unique(r$items)) {
    for(item_size in unique(r$size)) {
      for(label in unique(r$label)) {
        d <- r[r$items == items  & r$label == label & r$size == item_size,]
        d$item_size <- d$size
        if (length(d[,1]) > 1) {
          cat("Doing", label, "over", comma(items), prettySize(item_size), "items\n")
          p <- ggplot(data=d, aes(software_v, time, fill=build)) +
            geom_bar(stat='identity', position='dodge') + coord_flip() +
            opts(legend.position = "none") +
            opts(title=paste(comma(items), " items -", label)) +
            facet_wrap(~nodes, ncol=1, scales='free') +
            labs(y='Seconds', x='')

          if (! is.na(d$comptime[[1]])) {
            p <- p + geom_text(aes(y = time, size=2, hjust=1,
                                   label=sprintf("%.2fx", xtime)))
          }

          print(p)
        } else {
          cat("Skipping", comma(items), label, "\n")
        }
      }
    }
  }
  dev.off()
}

uploadName <- commandArgs(TRUE)

if (length(uploadName) > 0) {
  df <- getUpload(uploadName)
  df[df$nodes == 0,]$nodes <- 1
  df.relative <- buildComparison(df, 'build', 'mongodb-64-2.0.0-rc1')

  makeOne(df.relative, paste(uploadName, '.pdf', sep=''))
} else {
  cat("Please choose an upload:\n\n * ")
  cat(listUploads(), sep="\n * ")
  cat("\n")
}

