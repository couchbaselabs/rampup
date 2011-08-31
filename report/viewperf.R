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

parseCPUCounters <- function(lines) {
  ## From the proc(5) man page

  fields <- c('pid', 'comm', 'state', 'ppid', 'pgrp', 'session', 'tty_nr', 'tpgid',
            'flags', 'minflt', 'cminflt', 'majflt', 'cmajflt', 'utime', 'stime',
            'cutime', 'cstime', 'priority', 'nice', 'num_threads', 'itrealvalue',
            'starttime', 'vsize', 'rss', 'rsslim', 'startcode', 'endcode',
            'startstack', 'kstkesp', 'kstkeip', 'signal', 'blocked', 'sigignore',
            'sigcatch', 'wchan', 'nswap', 'cnswap', 'exit_signal', 'processor',
            'rt_priority', 'policy', 'delayacct_blkio_ticks', 'guest_time',
            'cguest_time')

  s <- plyr::ldply(lines, function(r) unlist(strsplit(r, " ")))
  names(s) <-  fields[c(1:length(s[1,]))]
  s$comm <- factor(s$comm)
  ## Numberize the datas
  s[,-c(1:3)] <- as.numeric(as.matrix(s[,-c(1:3)]))

  ## Number the lines.
  s$rowid <- 1:nrow(procstuff)
  for (comm in levels(s$comm)) {
    s[s$comm == comm,]$rowid <- 1:nrow(s[s$comm == comm,])

    counters <- c('utime', 'stime', 'cutime', 'cstime')
    for (counter in counters) {
      name <- paste(counter, '_diff', sep='')
      counterdiff <- diff(s[s$comm == comm,counter])
      s[s$comm == comm, name] <- append(c(0), counterdiff)
    }
  }

  s
}

meltCPUStats <- function(cpudf) {
  melt(cpudf, id.vars=c('pid', 'comm', 'state', 'rowid'))
}
