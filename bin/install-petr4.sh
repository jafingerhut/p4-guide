#! /bin/bash

# Copyright 2019-present Cisco Systems, Inc.

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


echo "------------------------------------------------------------"
echo "Time and disk space used before installation begins:"
date
df -h .
df -BM .

# Install Ubuntu packages needed for a C compiler, which `opam init`
# command requires.
sudo apt-get --yes install curl build-essential

curl --output opam https://github.com/ocaml/opam/releases/download/2.0.4/opam-2.0.4-x86_64-linux
sudo /bin/cp opam /usr/local/bin/opam
sudo chmod 755 /usr/local/bin/opam
/bin/rm opam

echo "------------------------------------------------------------"
echo "Time and disk space used when installation was complete:"
date
df -h .
df -BM .
