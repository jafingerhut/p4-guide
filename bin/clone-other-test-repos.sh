#! /bin/bash

# Get copies of other repositories that I use to test an open source
# P4 development tool installation.

set -x

git clone https://github.com/p4pktgen/p4pktgen

# Basic testing of p4pktgen functionality:

# cd p4pktgen
# ./tools/install.sh
# ./tools/pytest.sh

git clone https://github.com/p4lang/tutorials

# Basic testing of functionality for tutorials repo:

# cd tutorials/exercises/basic
# cp solutions/basic.p4 .
# make run

# at mininet prompt:
# h1 ping h2
# Ctrl-C after a few seconds
# h4 ping h3
# Ctrl-C after a few seconds
# Ctrl-D to exit mininet


# fairly extensive testing of p4c functionality, and some of
# behavioral-model.

# cd $HOME/p4c/build
# make check
