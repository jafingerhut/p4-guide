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


#for j in /usr/lib/x86_64-linux-gnu/*

for j in "$@"
do
    if [ ! -d "$j" ]
    then
#        grep RSA_set0_key "$j"
#        if [ $? -eq 0 ]
#        then
#            echo $j " <------ grep found RSA_set0_key -------------------------"
#        fi
        nm -D "$j" | grep RSA_set0_key
        if [ $? -eq 0 ]
        then
            echo "$j" " <--- see previous line(s) for occurrences of RSA_set0_key in 'nm -D' output of this file"
        fi
    fi
done
