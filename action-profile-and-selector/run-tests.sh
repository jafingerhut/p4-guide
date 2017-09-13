#! /bin/bash

# VPP_P4_INSTAL_DIR should be the directory where you have cloned a
# copy of this repository:

#     https://github.com/jafingerhut/VPP_P4

# It contains some Python code import'd by action-profile-tests.py

VPP_P4_INSTALL_DIR=${HOME}/p4-docs/VPP_P4

export PYTHONPATH=${VPP_P4_INSTALL_DIR}:${PYTHONPATH}
./action-profile-tests.py --json action-profile.json
