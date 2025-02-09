#! /bin/bash
# Copyright 2020 Andy Fingerhut
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
