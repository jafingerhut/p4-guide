// Copyright 2024 Andy Fingerhut
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

#include "before-parser.p4"

{
    value_set<bit<16>>(4) pvs1;
    value_set<bit<16>>(4) pvs2;
    
    state start {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.etherType) {
            pvs1: st1;
            pvs2: st2;
            default: accept;
        }
    }

    state st1 {
        transition accept;
    }

    state st2 {
        transition accept;
    }
}

#include "after-parser.p4"
