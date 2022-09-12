#include <core.p4>

struct t1_key_mask_pair_t {
    bit<16> key;
    bit<16> mask;
}

struct t1_key_val_pair_t {
    t1_key_mask_pair_t key_spec;
    bit<32> val;
}

extern TernaryMap<K, V, KV> {
    TernaryMap(int size, Vector<KV> const_entries, V default_value);
    V lookup(in K key);
}

control c() {
    TernaryMap<bit<16>, bit<32>, t1_key_val_pair_t>(
        size = 1024,
        const_entries = [t1_key_val_pair_t;
            {{5, 0xffff}, 10},  // ternary key with value 5, mask 0xffff (exact match on all 16 bits), value 10
            {{6, 0xffff}, 27},  // ternary key with value 6, mask 0xffff, value 27
            {{10, 0x00ff}, 2}   // ternary key with value 10, mask 0x00ff (exact match on least significant 8 bits, wildcard on bits [15:8]), value 2
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
