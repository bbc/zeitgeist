#!/bin/sh
sudo yum install -y gcc gcc-c++ kernel-devel
sudo yum install -y openssl openssl-devel
sudo yum install -y readline-devel ncurses-devel

rm -rf /tmp/install

mkdir /tmp/install
cd /tmp/install
RUBY_VERSION=ruby-1.8.7-p249
GEMS_VERSION=rubygems-1.3.6

wget http://ftp.ruby-lang.org/pub/ruby/1.8/$RUBY_VERSION.tar.gz
wget http://production.cf.rubygems.org/rubygems/$GEMS_VERSION.tgz

tar zxvf $RUBY_VERSION.tar.gz
tar zxvf $GEMS_VERSION.tgz
cd $RUBY_VERSION
./configure --prefix=/usr
make
sudo make install
cd ../$GEMS_VERSION
sudo ruby setup.rb
