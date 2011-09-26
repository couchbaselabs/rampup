#!/bin/sh -e
#
# First, launch an EC2 instance...
#
# * Basic 64-bit Amazon Linux AMI 2011.02.1 Beta (AMI Id: ami-8e1fece7)
# * m1.large or better
# * Name it appropriately, and also add a Key of
#   "Creator" -> "your email address" so you can find it later for killing.
#
# After it launches, ssh into it and run the following...
#
sudo yum install openssl098e
sudo yum install gcc gcc-c++ zlib zlib-devel make
sudo yum install irb ruby-devel rdoc
sudo yum install git
wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.7.tgz
tar -xzvf rubygems-1.8.7.tgz
cd rubygems-1.8.7
sudo ruby setup.rb
cd ~
sudo gem install memcache dalli
git clone git://github.com/couchbaselabs/rampup.git
