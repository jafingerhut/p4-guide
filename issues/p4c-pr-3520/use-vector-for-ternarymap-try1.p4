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

extern TernaryMap<K, V> {
    TernaryMap(int size, Vector<tuple<tuple<K,K>,V>> const_entries, V default_value);
    V lookup(in K key);
}

control c() {
    TernaryMap<bit<16>, bit<32>>(
        size = 1024,
        const_entries = [tuple<tuple<bit<16>,bit<16>>,bit<32>>;
            {{5, 0xffffff}, 10},  // ternary key with value 5, mask 0xffffff (exact match on least significant 24 bits), value 10
            {{6, 0xffffff}, 27},  // ternary key with value 6, mask 0xffffff, value 27
            {{10, 0x00ffff}, 2}   // ternary key with value 10, mask 0x00ffff (exact match on least significant 16 bits, wildcard on bits [23:16]), value 2
        ],
        default_value = 42)  // default value returned for all other keys
    t1;

    bit<16> k1 = 17;

    apply {
        t1.lookup(k1);
    }
}

control C();
package top(C _c);

top(c()) main;
