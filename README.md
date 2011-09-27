# View Merging Tests

First...

    git clone git://github.com/couchbaselabs/rampup.git
    cd rampup

## To run...

First, clear out the out directory or move old results out of the way...

    rm -rf out/*

To run a test...

    ./runtests $package $ram_quotas,csv $replica_counts,csv $num_items,csv $nodes,csv $vbucket-range $val-size,csv

For example...

    ./runtests couchbase-server-community_x86_64_2.0.0r-12-g9ef46c9.rpm 5000 0 100000,1000000 1 1-64 128,1024,10240

The above will run a matrix of...

    ram quota: 5000 mb
    replica count: 0
    num items: 100000, 1000000
    num nodes: 1
    vbuckets, 1,2,4,8,16,32,64
    min item size: 128, 1024, 10240 bytes

It takes quite awhile on one of our physical perf box. You could cut
down the matrix inputs to make it faster.

So, to run something quick, cut down the test matrix to use less data
and dimensions...

    ./runtests couchbase-server-community_x86_64_2.0.0r-12-g9ef46c9.rpm 5000 0 100000 1 64-64 128,10240

The output files will appear in the ./out subdirectory.

To upload those to a couchdb for further analysis, use...

    ./results-store http://HOST:5984/COUCHDB RUN_NAME OUT0 [OUT1 ... OUTN]

For example:

    ./results-store http://single.couchbase.net/viewperf physical out/test-*/*.out

## Notes on prerequisites

Required gem's...

    gem install memcache dalli

### On Amazon Default Linux

You'll need the right openssl...

    sudo yum install openssl098e

### On centos...

Get git.  Along the way, you might need...

    yum install gcc gcc-c++ zlib zlib-devel

Get a recent ruby (1.8.7 or greater).

Get rubygems (from rubygems.org).

### On ubuntu...

    apt-get install git-core
    apt-get install ruby irb

Then...

    apt-get install rubygems1.8

Or...

    wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.7.tgz
    tar -xzvf rubygems-1.8.7.tgz
    cd rubygems-1.8.7
    ruby setup.rb

### Testing mongo

If you also want to test mongo...

    gem install mongo
    gem install bson
    gem install bson_ext
    gem install SystemTimer

# Cluster testing

The runtests tool has the ability to test a cluster of nodes, via a
"$nodes.csv" parameter that's > 1.  For example...

    ./runtests some-victim.rpm 5000 0 100000 2,4,10 64-64 128 \
       cluster.user=root,cluster.hosts=$LIST_OF_HOSTS,cluster.package-url-base=$HTTP_BASE

The $LIST_OF_HOSTS should be '+' separated.

The $HTTP_BASE should be the URL prefix where runtests can download the some-victim.rpm.

Fake example...

    ./runtests couchbase-server-community_x86_64_2.0.0r-12-g9ef46c9.rpm \
       5000 0 100000,1000000 4,2,1 1-64 128,1024,10240 \
       cluster.user=root,cluster.hosts=10.2.1.14+10.2.1.13+10.2.1.12+10.2.1.11,cluster.package-url-base=http://couchbase.net/dev-builds

The cluster tests also depend on ssh access to remote machines, so you
might want to ssh-add and use ssh agent forwarding ("ssh -A joe@10.2.1.15")
so that runtests's attempts to ssh to other boxes will work.

# Testing other software

You can also use runtests against old versions of membase (although
the view-related measurements should be ignored), couchbase-single,
and mongo.  The ram quota, number of vbuckets and number of nodes
parameters, also, won't make sense depending on what you're testing.

Examples...

    ./runtests mongodb-linux-x86_64-2.0.0-rc2.tgz 0 0 10000,1000000 1 1 128,1024,10240
    ./runtests couchbase-single-server_x86_64_2.0.0r-22-gd69ec57.rpm 0 0 100000 0 1-64 128,1024,10240

# Fire and forget

If you're running a long test run, considering using nohup with
backgrounding the job or equivalent, so that your terminal/tty can die
without killing the run.  Like...

    nohup ./runtests ../couchbase-single-server_x86_64_2.0.0r-22-gd69ec57.rpm 0 0 100000,1000000 0 16-64 128,1024,10240 &

NOTE: The nohup approach might not work well with cluster testing due
to ssh interactions.

# Monitoring progress

Monitoring the output of the out subdir can be helpful to see progress...

    watch -d "ls -alt out/test*/*"

And...

    watch -d "ls -at out/test*/*.out | head -n 1 | xargs tail -n 30"

Hint: check that "items/sec" isn't too crazy (unbelievably fast, or
greater than 100,000 items/sec), as that might indicate some weird
issue with data loading or accessing.

# R

To generate nice PDF graphs, we use the R tool.  Please see the report
subdirectory.

To get R, see r-project.org / CRAN, and if you're running on a mac,
favor R64.app.

