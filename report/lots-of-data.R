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
require(multicore, quietly=TRUE)

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
}

sortComparison <- function(rv) {
  rv[order(rv$build, rv$vbuckets, decreasing=TRUE),]
}

makeFootnote <- function(footnoteText=format(Sys.time(), "%d %b %Y"),
                         size=.7, color=grey(.5)) {
  if (length(footnoteText) > 0) {
   require(grid)
   pushViewport(viewport())
   lines <- strwrap(footnoteText, width=120)
   lapply(1:length(lines),
          function(linenum)
             grid.text(label=lines[[linenum]],
                 x=unit(1,"npc") - unit(2, "mm"),
                 y=unit(2 + (length(lines) - linenum) * 12, "pt"),
                 just=c("right", "bottom"),
                 gp=gpar(cex=size, col=color)))
   popViewport()
 }
}

makeOne <- function(r, filename) {
  pdf(filename)

  r$software_v <- paste(r$build, r$vbuckets)
  r$software_v <- factor(r$software_v, levels=unique(r$software_v), ordered=TRUE)

  for(label in levels(r$label)) {
    for(items in unique(r$items)) {
      for(item_size in unique(r$size)) {
        d <- r[r$items == items & r$label == label & r$size == item_size,]
        d$item_size <- d$size

        if (length(d[,1]) > 1) {
          cat("Doing", label, "over", comma(items), prettySize(item_size), "items\n")
          p <- ggplot(data=d, aes(software_v, time, fill=build)) +
            geom_bar(stat='identity', position='dodge') + coord_flip() +
            opts(legend.position = "none") +
            opts(title=paste(comma(items),
                             prettySize(item_size, "%d"),
                             "items -", label)) +
            opts(plot.margin=unit(c(0, 0, 30, 0), "pt")) +
            facet_wrap(~nodes, ncol=1, scales='free') +
            labs(y='Seconds', x='')

          if (length(d$comptime[[1]]) > 0) {
            p <- p + geom_text(aes(y = time, size=2, hjust=1,
                                   label=sprintf("%.2fx", xtime)))
          }

          print(p)
          makeFootnote(d[1,'description'])
        } else {
          cat("Skipping", comma(items), prettySize(item_size, "%d"), label, "\n")
        }
      }
    }
  }
  dev.off()
}

uploadName <- commandArgs(TRUE)

if (length(uploadName) > 0) {
  df <- getUpload(uploadName)
  if (nrow(df[df$nodes == 0,]) > 0) {
    df[df$nodes == 0,]$nodes <- 1
  }

  makeOne(df, paste(uploadName, 'pdf', sep='.'))

  comparisions <- c('mongodb-64-2.0.0-rc1', 'membase-1.7.1.1')
  kinds <- getKinds()
  mclapply(comparisions,
           function(relto)
             makeOne(sortComparison(merge(buildComparison(df, 'build', relto), kinds)),
                     paste(uploadName, relto, 'rel.pdf', sep='.')))
} else {
  cat("Please choose an upload:\n\n * ")
  cat(listUploads(), sep="\n * ")
  cat("\n")
}

