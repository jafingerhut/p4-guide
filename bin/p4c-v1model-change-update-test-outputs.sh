#! /bin/bash
# Copyright 2019 Andy Fingerhut
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


# Run this script from inside of the p4c/build directory, if you add
# or remove lines in the p4c/p4include/v1model.p4 include file.  The
# tests below cause p4c to print error messages that contain line
# numbers within the v1model.p4 file, so passing 'make check' tests
# requires updating these line numbers in the expected output files.

./p4/testdata/p4_16_samples/issue841.p4.test -f
./err/testdata/p4_16_errors/issue1541.p4.test -f
./err/testdata/p4_16_errors/issue513.p4.test -f
