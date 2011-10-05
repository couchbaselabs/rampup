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
}


args <- commandArgs(TRUE)
cat(paste("args : ",args,""),sep="\n")
args <- unlist(strsplit(args," "))
uploadName <- args[1]
#uploadName = "3m-moxi-oct-03"
cat(paste("upload name : ",uploadName),sep="\n")
pdf(paste(uploadName,sep="",".pdf"))
df <- getUpload(uploadName)
steps = c("loading-docs","loading-persisted")
df <- transform(df,build=paste(gsub("couchbase-","",build)))
df <- transform(df,build=paste(gsub("membase-","",build)))
if (length(args) > 1) {
	#there is a baseline
	baseline <- args[2]
#	baseline = "1.7.1r-68"
	cat(paste("baseline : ",baseline),sep="\n")
	df <- buildComparison(df, 'build', baseline)
	for(label in steps) {
				d <- df[df$label == label,]
				p <- ggplot(data=d,aes(x=build,y=time,fill=build))
				p <- p + labs(y='Seconds', x="Build Number") 
				p <- p + geom_bar(stat='identity', position='stack') 
				p <- p + geom_text(aes(y = time,vjust=0,hjust=1,label=paste(sprintf("%.2f",xtime)," X")))
				p <- p + opts(legend.position = "none")
				p <- p + opts(title=paste(comma(d$items),prettySize(d$size, "%d"),"items ", label))
				p <- p + coord_flip()
				p <- p + theme_bw()
				print(p)
	}
	
} else {
	for(label in steps) {
				d <- df[df$label == label,]
				p <- ggplot(data=d,aes(x=build,y=time,fill=build))
				p <- p + labs(y='Seconds', x="Build Number") 
				p <- p + geom_bar(stat='identity', position='stack') 
				p <- p + geom_text(aes(y = time,vjust=0,hjust=1,label=paste(sprintf("%.0f",time)," sec")))
				p <- p + opts(legend.position = "none")
				p <- p + opts(title=paste(comma(d$items),prettySize(d$size, "%d"),"items ", label))
				p <- p + coord_flip()
				p <- p + theme_bw()
				print(p)
	}
}
dev.off()
