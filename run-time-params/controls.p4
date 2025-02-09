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
control C1();
control C2();
control C3();
package S(C3 c3);

// User Program
control MyC1() {
    apply { }
}
control MyC2(C1 c1) {
    // README
    // 2017-Aug-16 version of p4test gives the following error on the
    // line above:
    //
    // controls.p4(13): error: c1: parameter cannot have type control C1
    // control MyC2(C1 c1) {
    //                 ^^
    // controls.p4(4)
    // control C1();
    //         ^^
    apply {
        c1.apply();
    }
}
control MyC3() {
    MyC1() c1;
    apply {
        MyC2.apply(c1);
    }
}

S(MyC3()) main;
