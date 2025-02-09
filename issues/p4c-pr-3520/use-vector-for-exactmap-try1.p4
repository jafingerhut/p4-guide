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

#include <core.p4>

extern ExactMap<K, V> {
    ExactMap(int size, Vector<tuple<K,V>> const_entries, V default_value);
    V lookup(in K key);
}

control c() {
    ExactMap<bit<16>, bit<32>>(
        size = 1024,
        const_entries = [tuple<bit<16>,bit<32>>;
            {5, 10},  // key 5, value 10
            {6, 27},  // key 6, value 27
            {10, 2}   // key 10, value 2
        ],
        default_value = 42)  // default value returned for all other keys
    e1;

    bit<16> k1 = 17;

    apply {
        e1.lookup(k1);
    }
}

control C();
package top(C _c);

top(c()) main;
