require(rjson)

getData <- function(subpath, urlBase='http://localhost:5984/viewperf/') {
  fromJSON(file=paste(urlBase, subpath, sep=''))$rows
}

getFlatData <- function(sub, n=NULL) {
  b <- plyr::ldply(getData(sub), unlist)
  if (!is.null(n)) {
    names(b) <- n
  }
  b
}

listTests <- function() {
  unlist(rbind(getFlatData('_design/rviews/_view/by_test?group_level=1')[,c(1)]))
}

listUploads <- function() {
  unlist(rbind(getFlatData('_design/rviews/_view/by_upload?group_level=1')[,c(1)]))
}

getRunData <- function(view, name) {
  sub <- paste(view, '?reduce=false&startkey=["',
               name, '"]&endkey=["', name, '",{}]', sep='')
  b <- getFlatData(sub, c('id', 'test', 'build', 'nodes',
                          'vbuckets', 'items', 'size', 'label', 'time'))
  b <- b[,!names(b) %in% c('id', 'test')]
  b <- transform(b, time=as.numeric(time),
                 size=as.numeric(size),
                 nodes=as.numeric(nodes),
                 vbuckets=as.numeric(vbuckets),
                 items=as.numeric(items),
                 label=factor(label),
                 build=factor(build, levels=unique(b$build), ordered=TRUE))
  b[order(b$build, b$vbuckets, decreasing=TRUE),]
}

getTest <- function(r) {
  getRunData('_design/rviews/_view/by_test', r)
}

getUpload <- function(r) {
  getRunData('_design/rviews/_view/by_upload', r)
}
