#! /bin/bash

# Copyright 2024 Andy Fingerhut, andy.fingerhut@gmail.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# This script takes a single file name as parameter, assumed to
# contain the output of a `p4testgen` command that generates a PTF
# test.  It makes two small modifications to the PTF test that, in my
# testing, enable it to work when run inside of an IPDK networking
# container.

FNAME="$1"

grep -v "^sys\.path\.append(str(BASE_TEST_PATH))$" ${FNAME} | sed 's/^PIPELINE_PUSHED = False/PIPELINE_PUSHED = True/'
