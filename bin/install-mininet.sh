#! /bin/bash

# This script is just a tiny excerpt from install-p4dev-v4.sh for
# installing only Mininet.  My intent is to automate some extra
# visibility into how Mininet's installation is operating, in hopes of
# learning whether it is straightforward to stop it from installing
# Python2 when run on an Ubuntu 20.04 Desktop Linux system that
# doesn't already have Python2 installed.

set -x

lsb_release -a
python -V  || echo "No such command in PATH: python"
python2 -V || echo "No such command in PATH: python2"
python3 -V || echo "No such command in PATH: python3"
pip -V  || echo "No such command in PATH: pip"
pip2 -V || echo "No such command in PATH: pip2"
pip3 -V || echo "No such command in PATH: pip3"
pip list  || echo "No such command in PATH: pip"
pip2 list || echo "No such command in PATH: pip2"
pip3 list || echo "No such command in PATH: pip3"

find / | sort > files-1-before-mininet.txt

git clone git://github.com/mininet/mininet mininet
sudo ./mininet/util/install.sh -nwv

python -V  || echo "No such command in PATH: python"
python2 -V || echo "No such command in PATH: python2"
python3 -V || echo "No such command in PATH: python3"
pip -V  || echo "No such command in PATH: pip"
pip2 -V || echo "No such command in PATH: pip2"
pip3 -V || echo "No such command in PATH: pip3"
pip list  || echo "No such command in PATH: pip"
pip2 list || echo "No such command in PATH: pip2"
pip3 list || echo "No such command in PATH: pip3"

find / | sort > files-2-after-mininet.txt
diff files-1-before-mininet.txt files-2-after-mininet.txt > files-diff.txt
