#! /bin/bash

# Tested on Ubuntu 20.04

if [ ! -r /etc/os-release ]
then
    1>&2 echo "No file /etc/os-release.  Cannot determine what OS this is."
    linux_version_warning
    exit 1
fi
source /etc/os-release

if [ "${ID}" = "ubuntu" ]
then
   sudo apt-get install --yes automake
elif [ "${ID}" = "fedora" ]
then
   sudo dnf install -y automake
fi

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

if [ "${ID}" = "ubuntu" ]
then
    sudo apt-get purge -y autoconf automake
    sudo apt-get install --yes libtool-bin
elif [ "${ID}" = "fedora" ]
then
    sudo dnf remove -y autoconf automake
    sudo dnf install -y libtool
fi
# I learned about the fix-up commands below in an answer here:
# https://superuser.com/questions/565988/autoconf-libtool-and-an-undefined-ac-prog-libtool
for file in /usr/share/aclocal/*.m4
do
    b=`basename $file .m4`
    sudo ln -s /usr/share/aclocal/$b.m4 /usr/local/share/aclocal/$b.m4
done
