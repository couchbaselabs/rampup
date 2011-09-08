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
  df.m <- df[df[,field] == value,]

  for (v in unique(df$vbuckets)) {
    for (i in unique(df$items)) {
      for (s in unique(df$size)) {
        for (l in unique(df$label)) {
          replacement <- df.m[df.m$items == i &
                              df.m$size == s &
                              df.m$label == l, 'time']
          if (length(replacement) == 0) {
            replacement = NA
          }
          df[df$items == i &
             df$size == s &
             df$label == l &
             df$vbuckets == v, 'comptime'] <- replacement
        }
      }
    }
  }
  transform(df, xtime=time / comptime)
}

buildComparison2 <- function(df, field, value) {
  df.m <- df[df[,field] == value,]
  df$comptime <- join(df[,c('items', 'size', 'label')],
                      df.m, by=c('items', 'size', 'label'))$time
  df
}

makeOne <- function(r, filename) {
  pdf(filename)

  r$software_v <- paste(r$build, r$vbuckets)
  r$software_v <- factor(r$software_v, levels=unique(r$software_v), ordered=TRUE)

  for(items in unique(r$items)) {
    for(label in unique(r$label)) {
      d <- r[r$items == items  & r$label == label,]
      d$item_size <- d$size
      if (length(d[,1]) > 1) {
        cat("Doing", comma(items), label, "\n")
        p <- ggplot(data=d, aes(software_v, time, fill=build)) +
          geom_bar(stat='identity', position='dodge') + coord_flip() +
            opts(legend.position = "none") +
              opts(title=paste(comma(items), " items -", label)) +
                facet_wrap(nodes ~ item_size ~ items, ncol=1, scales='free') +
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
  dev.off()
}

uploadName <- commandArgs(TRUE)

if (length(uploadName) > 0) {
  df <- getUpload(uploadName)
  df.relative <- buildComparison(df, 'build', 'mongodb-64-2.0.0-rc1')

  makeOne(df.relative, paste(uploadName, '.pdf', sep=''))
} else {
  cat("Please choose an upload:\n\n * ")
  cat(listUploads(), sep="\n * ")
  cat("\n")
}

