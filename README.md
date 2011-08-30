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

The output files will appear in the ./out subdirectory.

To upload those to a couchdb for further analysis, use...

    ./results-store http://HOST:5984/COUCHDB RUN_NAME OUT0 [OUT1 ... OUTN]

For example:

    ./results-store http://single.couchbase.net/viewperf physical out/*/*

## Notes on prerequisites

Required gem's...

    gem install memcache dalli

On Amazon Default Linux EC2 nodes, you'll need to get the right openssl...

    sudo yum install openssl098e

On ubuntu...

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



