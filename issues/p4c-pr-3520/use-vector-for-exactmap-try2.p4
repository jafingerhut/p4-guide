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

struct e1_key_val_pair_t {
    bit<16> key;
    bit<32> val;
}

extern ExactMap<K, V, KV> {
    ExactMap(int size, Vector<KV> const_entries, V default_value);
    V lookup(in K key);
}

control c() {
    ExactMap<bit<16>, bit<32>, e1_key_val_pair_t>(
        size = 1024,
        const_entries = [e1_key_val_pair_t;
            {16w5, 32w10},  // key 5, value 10
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
