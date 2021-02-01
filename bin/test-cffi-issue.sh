#! /bin/bash

set -x

lsb_release -a
find /usr | grep cffi
large-pkgs.py | grep cffi
git clone https://github.com/p4lang/behavioral-model
python3 -V
pip3 -V
pip3 list
sudo apt-get --yes install python3-pip
python3 -V
pip3 -V
pip3 list
bash ./behavioral-model/travis/install-nnpy.sh
