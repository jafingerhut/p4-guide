// Copyright 2022 Andy Fingerhut
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
    @name(".foo") action act1() {
        hdr.ethernet.etherType = hdr.ethernet.etherType >> 2;
    }
    @name(".foo") action act2() {
        hdr.ethernet.etherType = hdr.ethernet.etherType << 3;
    }
    table t1 {
        key = { hdr.ethernet.etherType : exact; }
        actions = { act1; act2; NoAction; }
        const default_action = NoAction;
    }
    apply {
        t1.apply();
    }
}

#include "after-ingress.p4"
