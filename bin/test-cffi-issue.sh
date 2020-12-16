#! /bin/bash

set -x

lsb_release -a
find /usr | grep cffi
large-pkgs.py | grep cffi
git clone https://github.com/p4lang/behavioral-model
./behavioral-model/travis/install_nnpy.sh
