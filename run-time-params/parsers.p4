// Copyright 2017 Andy Fingerhut
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

#include <core.p4>

// Architecture
parser P1();
parser P2();
parser P3();
package S(P3 p3);

// User Program
parser MyP1() {
    state start {
        transition accept;
    }
}
parser MyP2(P1 p1) {
    // README
    // 2017-Aug-16 version of p4test gives the following error on the
    // line above:
    //
    // parsers.p4(15): error: p1: parameter cannot have type parser P1
    // parser MyP2(P1 p1) {
    //                ^^
    // parsers.p4(4)
    // parser P1();
    //        ^^
    state start {
        p1.apply();
        transition accept;
    }
}
parser MyP3() {
    MyP1() p1;
    state start {
        MyP2.apply(p1);
        transition accept;
    }
}

S(MyP3()) main;
