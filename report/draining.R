source("viewperf.R")
require(ggplot2, quietly=TRUE)


prettySize <- function(s, fmt="%.2f") {
  sizes <- c('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB')
  e <- floor(log(s, 1024))
  suffix <- sizes[e+1]
  prefix <- sprintf(fmt, s/(1024 ^ floor(e)))
  paste(prefix, suffix, sep="")
}


#listUploads()
uploadName <- commandArgs(TRUE)
cat(uploadName)
pdf(paste(uploadName,sep="",".pdf"))
#uploadName = "rampup-single-node-memcachetest-3m"
df <- getUpload(uploadName)
steps = c("loading-docs","loading-persisted")
for(label in steps) {
			d <- df[df$label == label,]
			p <- ggplot(data=d,aes(x=build,y=time,fill=build))
			p <- p + labs(y='Seconds', x="Build Number") 
			p <- p + geom_bar(stat='identity', position='stack') 
			p <- p + geom_text(aes(y = time,vjust=0,hjust=0,size=10,label=paste(sprintf("%.0f",time)," sec")))
			p <- p + opts(title=paste(comma(d$items),prettySize(d$size, "%d"),"items -", label))
			print(p)
}
dev.off()
