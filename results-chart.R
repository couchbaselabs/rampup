require(ggplot2)

# Exported the thing as a CSV because it was slightly easier to load
mongo <- read.csv('~/Desktop/out.csv')
# Factored the combination of the software and vbuckets as a pivot point
m <- mongo[order(mongo$software, mongo$vbuckets, decreasing=TRUE),]
v <- paste(m$software, m$vbuckets)
mongo$software_v <- factor(paste(mongo$software, mongo$vbuckets), levels=unique(v), ordered=TRUE)
rm(m)
rm(v)

# Rotate it into a long form thingy.
interesting <- c('loading.docs', 'loading.persisted',
                 'index.building', 'index.accessing', 'reading.docs')

mongo.melted <- melt(mongo, id.vars=c('software_v', 'items', 'min.item.size'),
                     measure.vars=interesting)

# Minor data fixup -- convert NAs to zero
mongo.melted$value <- ifelse(is.na(mongo.melted$value), 0, mongo.melted$value)

# Toss it up on the screen.
ggplot(data=mongo.melted, aes(software_v, value, fill=variable)) +
    facet_wrap(items ~ min.item.size, scales='free', ncol=2) +
    geom_bar(stat='identity') + coord_flip() + labs(x='', y='') +
    opts(title="Steve Tries MongoDB") +
    theme_bw()

