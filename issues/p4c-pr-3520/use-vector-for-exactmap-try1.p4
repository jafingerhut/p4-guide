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
