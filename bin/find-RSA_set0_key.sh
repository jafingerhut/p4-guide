#! /bin/bash
# Copyright 2018 Andy Fingerhut
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


find /usr/lib \! -type d -print0 | xargs -0 find-RSA_set0_key2.sh |& grep -v ' no symbols' | grep -v 'File format not recognized' | grep -v 'File truncated'

echo ""
echo "U in nm output means 'The symbol is undefined'"
echo "T in nm output means 'The sybmol is in the text (code) section'"
echo "Read 'man nm' output for meanings of other letters."
