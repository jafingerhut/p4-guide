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

#include "before-ingress.p4"

{
    bit<8> tmp1;
    bit<8> tmp2;

    counter((bit<32>)1024, CounterType.packets) cntr1;
    counter((bit<32>)1024, CounterType.packets) cntr2;

    apply {
        tmp1 = hdr.ethernet.srcAddr[7:0];
        tmp2 = hdr.ethernet.dstAddr[7:0];
        cntr1.count((bit<32>) tmp1);
        cntr2.count((bit<32>) tmp2);
    }
}

#include "after-ingress.p4"
