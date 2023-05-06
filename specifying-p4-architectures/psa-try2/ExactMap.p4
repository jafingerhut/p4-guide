// ExactMap is an extern defined here:
// https://github.com/p4lang/pna/pull/52

struct exactmap_const_entry_t<K,V> {
    K key;
    V val;
}

struct exactmap_initial_entry_t<K,V> {
    bool const_entry;
    K key;
    V val;
}

/**
 * The type K must be a struct type.  Each of its members becomes a
 * separate key field of the ExactMap instance, with the member name
 * as its control plane API name.
 *
 * The type V may be a struct type, or a scalar type.
 */
extern ExactMap<K, V> {
    /**
     * Create a table with match kinds all 'exact' and the specified
     * size (number of entries).  The default value returned when a
     * lookup experiences a miss is given by default_value.
     */
    ExactMap(int size, V default_value);

    /**
     * The same as the constructor with an explicit default_value,
     * except the default_value is the default value for the type V as
     * defined in the section "Default values" of the P4_16 language
     * specification.
     */
    ExactMap(int size);

    /**
     * Create a table with match kinds all 'exact' and the specified
     * size (number of entries).  The default value returned when a
     * lookup experiences a miss is given by default_value.
     * const_entries is a list of entries, similar to the 'const
     * entries' table property for tables.  This set of entries cannot
     * be removed or modified by the control plane, and also, the
     * control plane is not allowed to add any entries to an ExactMap
     * instance created using this constructor.  Duplicate key values
     * are not allowed.
     *
     * Example where key is type emap1_key and value is type bit<16>:
     *
     *     struct emap1_key {
     *         bit<8> my_field;
     *     }
     *
     *     ExactMap<emap1_key, bit<16>>(
     *         size = 1024,
     *         const_entries = {
     *             {{5}, 10},  // key my_field=5, value 10
     *             {{6}, 27},  // key my_field=6, value 27
     *             {{10}, 2}   // key my_field=10, value 2
     *         },
     *         default_value = 42)  // default value returned for all other keys
     *     emap1;
     */
    ExactMap(int size,
        list<exactmap_const_entry_t<K,V>> const_entries,
        V default_value);

    /**
     * The same as the ExactMap constructor with a parameter named
     * `const_entries`, except that the control plane is allowed to
     * add entries to an ExactMap instance constructed using this
     * constructor (subject to capacity constraints, as usual), and
     * the control plane can modify or remove any entries that has a
     * `const_entry` field equal to false.  Any entries with a
     * `const_entry` field value equal to true cannot be modified or
     * removed by the control plane.
     */
    ExactMap(int size,
        list<exactmap_initial_entry_t<K,V>> initial_entries,
        V default_value);

    /**
     * Look up the key in the table.  Every call to lookup() returns a
     * value of type V, because either the search will match an entry,
     * or if no entry matches, the default_value will be returned.
     */
    V lookup(in K key);
}
