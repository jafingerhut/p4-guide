#! /bin/bash
# Copyright 2017 Andy Fingerhut
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


# VPP_P4_INSTAL_DIR should be the directory where you have cloned a
# copy of this repository:

#     https://github.com/jafingerhut/VPP_P4

# It contains some Python code import'd by action-profile-tests.py

VPP_P4_INSTALL_DIR=${HOME}/p4-docs/VPP_P4

export PYTHONPATH=${VPP_P4_INSTALL_DIR}:${PYTHONPATH}
./action-profile-tests.py --json action-profile.json
