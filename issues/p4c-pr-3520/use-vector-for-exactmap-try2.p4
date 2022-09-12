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
