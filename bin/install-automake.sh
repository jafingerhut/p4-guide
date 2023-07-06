#! /bin/bash

# Tested on Ubuntu 20.04

sudo apt-get install -y automake

wget https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.gz
tar xkzf automake-1.16.5.tar.gz
cd automake-1.16.5
./configure
make
sudo make install
cd ..

wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz
tar xkzf autoconf-2.71.tar.gz
cd autoconf-2.71
./configure
make
sudo make install
cd ..

sudo apt purge -y autoconf automake
sudo apt install -y libtool-bin
for file in /usr/share/aclocal/*.m4
do
    b=`basename $file .m4`
    sudo ln -s /usr/share/aclocal/$b.m4 /usr/local/share/aclocal/$b.m4
done
