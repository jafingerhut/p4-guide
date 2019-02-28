# Introduction 

There are several P4_16 programs written for the PSA architecture in
this directory.  As of 2019-Feb-18, the latest version of p4c produces
p4info files that do not include the names of `type` declarations from
the P4 source code.  It is intended for purposes of P4Runtime API
generation, and runtime numeric translation of some PSA types like
`PortId_t`, that the p4info file _should_ contain indications of all
values that have these types.

# References

+ Portable Switch Architecture specification, version 1.1, especially:
  + Section 4.1 "PSA type definitions"
  + Section 4.4 "Data plane vs. control plane data representations"

+ P4Runtime Specification, version 1.0, especially:
  + Section 8.5.6 "User-defined types"
  + Section 8.5.7 "Trade-off for v1.0 Release"
  + Section 17.1 "PSA Metadata Translation"

Inside the file `p4info.proto` at
`p4runtime/proto/p4/config/v1/p4info.proto` and `p4types.proto` at
`p4runtime/proto/p4/config/v1/p4types.proto`.

+ For custom types of table search keys, which are restricted in
  P4Runtime v1.0 to have a base type of `bit<W>`, see:
  + message `MatchField`, field `type_name` with type `P4NamedType`

+ For custom types of action parameters, which are restricted in
  P4Runtime v1.0 to have a base type of `bit<W>`, see:
  + message `Action`, then the message named `Param` inside of
    `Action`, field `type_name` with type `P4NamedType`

+ For custom types of register array elements, and digest messages,
  which are _not_ restricted in P4Runtime v1.0 to have only base types
  of `bit<W>`, but which can be any type in the P4_16 language, see:
  + message `Register`, field `type_spec` with type `P4DataTypeSpec`
  + message `Digest`, field `type_spec` with type `P4DataTypeSepc`

+ For register array indexes, indexes for indexed counters and indexed
  meters, I believe that the intent in P4Runtime v1.0 is that they can
  have custom types, but those types are restricted to have a base
  type of `bit<W>`.  See:
  + message `Counter`, field `index_type_name` with type `P4NamedType`
  + message `Meter`, field `index_type_name` with type `P4NamedType`
  + message `Register`, field `index_type_name` with type `P4NamedType`

Issues on Github:

+ https://github.com/p4lang/p4c/issues/1461
+ https://github.com/p4lang/p4runtime/issues/184


# Current vs. expected contents of generated P4Info files

Assume for the moment that the question in this issue:
https://github.com/p4lang/p4runtime/issues/184 is resolved such that
answer (a) is what we choose to go forward with.

In that case, this group of lines in the psa.p4 include file: 
https://github.com/p4lang/p4c/blob/master/p4include/psa.p4#L77-L85

```
@p4runtime_translation("p4.org/psa/v1/PortId_t", 32)
type PortIdUint_t         PortId_t;
type MulticastGroupUint_t MulticastGroup_t;
type CloneSessionIdUint_t CloneSessionId_t;
@p4runtime_translation("p4.org/psa/v1/ClassOfService_t", 8)
type ClassOfServiceUint_t ClassOfService_t;
type PacketLengthUint_t   PacketLength_t;
type EgressInstanceUint_t EgressInstance_t;
type TimestampUint_t      Timestamp_t;
```

will be changed to something like this:

```
@p4runtime_translation("p4.org/psa/v1/PortId_t", 32)
type PortIdUint_t         PortId_t;
@p4runtime_translation("p4.org/psa/v1/MulticastGroup_t", 32)
type MulticastGroupUint_t MulticastGroup_t;
@p4runtime_translation("p4.org/psa/v1/CloneSessionId_t_t", 16)
type CloneSessionIdUint_t CloneSessionId_t;
@p4runtime_translation("p4.org/psa/v1/ClassOfService_t", 8)
type ClassOfServiceUint_t ClassOfService_t;
@p4runtime_translation("p4.org/psa/v1/PacketLength_t_t", 16)
type PacketLengthUint_t   PacketLength_t;
@p4runtime_translation("p4.org/psa/v1/EgressInstance_t_t", 16)
type EgressInstanceUint_t EgressInstance_t;
@p4runtime_translation("p4.org/psa/v1/Timestamp_t_t", 64)
type TimestampUint_t      Timestamp_t;
```

Even if such a change is made, note that the 'translation' performed
on most of these types of values will be nothing more than adding or
removing leading 0 bits to increase or decrease the size of the value
between the P4Runtime messages and the smaller sizes that the P4
targets will typically use.

I believe that such a change should result in the following being
included as part of the `type_info` section of most P4_16 PSA
architecture P4Info files.

```
type_info {
  new_types {
    key: "PortId_t"
    value {
      translated_type {
        uri: "p4.org/psa/v1/PortId_t"
        sdn_bitwidth: 32
      }
    }
  }
  new_types {
    key: "MulticastGroup_t"
    value {
      translated_type {
        uri: "p4.org/psa/v1/MulticastGroup_t"
        sdn_bitwidth: 32
      }
    }
  }
  new_types {
    key: "CloneSessionId_t"
    value {
      translated_type {
        uri: "p4.org/psa/v1/CloneSessionId_t"
        sdn_bitwidth: 16
      }
    }
  }
  new_types {
    key: "ClassOfService_t"
    value {
      translated_type {
        uri: "p4.org/psa/v1/ClassOfService_t"
        sdn_bitwidth: 8
      }
    }
  }
  new_types {
    key: "PacketLength_t_t"
    value {
      translated_type {
        uri: "p4.org/psa/v1/PacketLength_t_t"
        sdn_bitwidth: 16
      }
    }
  }
  new_types {
    key: "EgressInstance_t_t"
    value {
      translated_type {
        uri: "p4.org/psa/v1/EgressInstance_t_t"
        sdn_bitwidth: 16
      }
    }
  }
  new_types {
    key: "Timestamp_t_t"
    value {
      translated_type {
        uri: "p4.org/psa/v1/Timestamp_t_t"
        sdn_bitwidth: 64
      }
    }
  }
}
```

Question: Is that true?

Question: Should the P4Info file only include a type in the
`new_types` section if the type is actually _used_ in some other part
of the P4Info file?  Or should it include all types defined via a
`type` declaration, even if it is not used elsewhere in the program?

The `type_info` message would also include any other type `bar` that a
programmer chooses to define via `type foo bar;` in their P4 program.


## Test program `psa-example-digest-bmv2.p4`

This program is a copy of the program with the same name from the
`p4c/testdata/p4_16_samples` directory, which was in turn copied from
the `p4-spec` repository `p4-16/psa/examples` directory.

It uses PSA-specific `type` `PortId_t` as a field of a struct
`mac_learn_digest_t`, which is used to send digest messages to the
control plane.

It also uses `PortId_t` as the type of an action parameter for action
`do_L2_forward`.

File `p4c-2019-02-18-v1/psa-example-digest-bmv2.psa.p4info.txt`
contains the p4info file generated by this command:

```
p4c-bm2-psa --p4runtime-files psa-example-digest-bmv2.psa.p4info.txt psa-example-digest-bmv2.p4
```

using the version of `p4c-bm2-psa` compiled from the source code
version described in `p4c-2019-02-18-v1/README.md`.

I believe that eventually we want it to generate a p4info file closer
to the one I have edited by hand and put in
`expected-p4info-files/psa-example-digest-bmv2.psa.p4info.txt`.  Note
that a correct p4info file could have its contents in a different
_order_ than shown in that expected output file, and still be correct.
I do not know when hand-editing these expected output files how to
predict what order the compiler will write them in, but am happy to
update them to match whatever a future `p4c-bm2-psa` produces, once
they match in the contents while ignoring the order.

In particular, the parameter `egress_port` for action `do_L2_forward`
should have `type_name: "PortId_t"`.

The `type_info` message should contain a `new_types` sub-message that
has entries for types `PortId_t`, `mac_learn_digest_t`, and probably
also the other 6 PSA-specific types.  I have only included
`ClassOfService_t` there right now.

Note that inside the definition of type `mac_learn_digest_t`, the type
of field `ingress_port` is specified via `type_spec { new_type { name:
"PortId_t" } }`.

There is no mention of the type `PortId_t`'s platform-specific bit
width, nor should there be.  The p4info file contents should be
identical across different PSA targets, even if their data plane width
for type `PortId_t` differs from each other.


## Test program `psa-example-counters-variant.p4`

This program is a modification of `psa-example-counters-bmv2.p4` from
the `p4c/testdata/p4_16_samples` directory, which was in turn copied
from the `p4-spec` repository `p4-16/psa/examples` directory.

It uses PSA-specific type `PortId_t` as a table search key field named
`istd.ingress_port` for table `port_pkts_bytes_in_per_protocol`.
P4Runtime v1.0 restricts table search key fields to be of type
`bit<W>` or `int<W>`, but `PortId_t`'s base type is `bit<W>`, and this
is also supported by P4Runtime v1.0.  The p4info file should have
`type_name: "PortId_t"` in the `match_fields` message for field
`istd.ingress_port`.

The file
`p4c-2019-02-18-v1/psa-example-counters-variant.psa.p4info.txt` was
generated by commenting out the line with the field
`istd.ingress_port` for table `port_pkts_bytes_in_per_protocol`,
because that version of `p4c-bm2-psa` does not generate a p4info file
due to an error of not yet handing a table search key of this type.

The program also uses PSA-specific type `PortId_t` as an index of an
indexed `Counter` named `port_bytes_out`.  The p4info file should have
a field `index_type_name: "PortId_t"` in the `counters` message that
describes this counter.


# Proposed p4c rules for generating types in p4info files

The P4Runtime v1.0 specification restricts the types that it supports
for the following kinds of things:

+ table search key fields, defined in the P4Info file in a
  `MatchField` message
+ fields of a ValueSet, also defined in the P4Info file in a
  `MatchField` message
+ parameters specified by the control plane for a table action,
  defined in the P4Info file in a `Param` message
+ metadata fields in a header sent from data plane to controller, or
  from controller to the data plane, defined in the P4Info file in a
  `Metadata` message, if a recently proposed PR is merged in [1].


[1] https://github.com/p4lang/p4runtime/pull/188

Later in this section, I will say "bit-constrained values" for
brevity, instead of repeating all of those kinds of objects.  For such
values, the P4Runtime v1.0 supports all of the following types, but
currently no others:

+ `bit<W>`
+ an `enum` with an underlying type of `bit<W>`
+ a `typedef` or `type` name that, when "followed back" to the lowest
  base type, is one of the above.

P4Info `MatchField`, `Param`, and probably soon also `Metadata`
messages may optionally contain the following two fields:

+ `int32 bitwidth`
+ `P4NamedType type_name`

Below we will describe what values these fields should have.

Consider a single bit-constrained value `x`.  Create a list of types
`type_list(x)` using the pseudocode shown below.

```
type_list(x) {
    ret = [];    // ret initialized to empty list
    T = declared type of object x in the P4 program;
    while (true) {
        if (T is declared as "type B T") {
            ret = ret + [T];   // append T to end of ret
            T = B;
        } else if (T is declared as "typedef B T") {
            T = B;
        } else {
            ret = ret + [T];   // append T to end of ret
            return ret;
        }
    }
}

// Note that type_list(x) always starts with zero or more `type`
// names, and always ends with one type that is neither a `type` nor
// `typedef` name, e.g. `bit<W>`, a header type, struct type, etc.
```

The p4c compiler signals an error if you attempt to create a cycle of
type names.  In order to create such a cycle, the first `type` or
`typedef` that appears in the program would have to refer to a later
type name, and this is not allowed.

If the last type is not `bit<W>` or `enum bit<W>`, that is an error
for P4Runtime v1.0.  The "base" type must always be one of those for
every bit-constrained value.


### `type_name` field

Let `first_type` be the first element of the list `type_list(x)`.

If `first_type` is a `type` name (i.e. not `bit<W>` or `enum bit<W>`),
then the value of the P4Info `type_name` field should be `{name =
"first_type_name"}`, where `first_type_name` is the name of
`first_type`.

Otherwise, the `type_name` field should be unset in the P4info
message.


### `bitwidth` field

If `first_type` is a `type` name, _and_ if the `type` definition for
this type has a `p4runtime_translation(uri_string, n)` annotation in
the source code, then the P4Info `bitwidth` field should be assigned
the value `n` that is the second parameter of that
`p4runtime_translation` annotation.

Otherwise, `bitwidth` should be equal to `W` where `bit<W>` or `enum
bit<W>` is the last element of `type_list(x)`.


## Example 1

```
bit<10> f1;

type_list(f1) -> [bit<10>]

no type_name in P4Info message
bitwidth: 10

Based on the P4 code snippet above, there is no need to set any fields
inside of the type_info field of the P4Info message, because there are
no named types in that code.
```


## Example 2

```
typedef bit<10> T1uint_t;
@p4runtime_translation("mycompany.com/psa/v1/T1_t", 32)
type T1uint_t T1_t;
type T1_t T2_t;
T2_t f2;

Execution trace for call to type_list(f2):
    T = declared type of object f2 in the P4 program = T2_t
    Evaluate condition (T2_t is declared as "type B T") -> true,
        because T2_t is declared as "type T1_t T2_t"
    ret = ret + [T] -> ret=[T2_t]
    T = B = T1_t
    Evaluate condition (T1_t is declared as "type B T") -> true,
        because T1_t is declared as "type T1uint_t T1_t"
    ret = ret + [T] -> ret=[T2_t, T1_t]
    T = B = T1uint_t
    Evaluate condition (T1uint_t is declared as "type B T") -> false
    Evaluate condition (T1uint_t is declared as "typedef B T") -> true,
        because T1uint_t is declared as "typedef bit<10> T1uint_t"
    T = B = bit<10>
    Evaluate condition (bit<10> is declared as "type B T") -> false
    Evaluate condition (bit<10> is declared as "typedef B T") -> false
    ret = ret + [T] -> ret=[T2_t, T1_t, bit<10>]
    return ret

type_list(f2) -> [T2_t, T1_t, bit<10>]

type_name: "T2_t"

    Reason: T2_t is the first type name in type_list(f2)

bitwidth: 10

    Reason: Type T2_t is the first type name in type_list(f2), but it
    has no p4runtime_translation on it, so even though T1_t does, that
    is ignored.  Use the width 10 from the last element of
    type_list(f2).
```

Based on the P4 code snippet above (copied below for easy reference),
the value below starting with `type_info {` should be in the P4Info
message describing the program, because of the `type` definitions.
There is never anything put into a P4Info message because of `typedef`
definitions in a P4 program.

Note that the bit width of 10 appears in the P4Info file for any
`type`s "built on top of" a `bit<10>`, _unless that type has its own
`p4runtime_translation` annotation_.

```
typedef bit<10> T1uint_t;
@p4runtime_translation("mycompany.com/psa/v1/T1_t", 32)
type T1uint_t T1_t;
type T1_t T2_t;
T2_t f2;
```

```
type_info {
  new_types {
    key: "T1_t"
    value {
      // translated_type for type T1_t because it has
      // p4runtime_translation annotation
      translated_type {
        uri: "mycompany.com/psa/v1/T1_t"
        sdn_bitwidth: 32
      }
    }
  }
  new_types {
    key: "T2_t"
    value {
      // original_type for type T2_t because it does not have
      // a p4runtime_translation annotation
      original_type {
        bitstring {
          bit {
            bitwidth: 10
          }
        }
      }
    }
  }
}
```


## Example 3

It is not clear whether there are strong use cases for declaring a
`type` based upon another `type` in a P4_16 program.

However, assuming that the language and compiler allows it, it seems
to be a good idea to have predictable rules to follow for what the
P4Info file contents should be, and how the resulting system should
behave.

In this proposal, the basic idea is to try to keep things fairly
straightforward to explain and understand if a P4_16 program does so.

If a bit-constrained value is declared with a `type` that has a
`p4runtime_translation` on it, that one is used.

In the absence of such an annotation on that `type`, no P4runtime
translation is done for that type, _even if a later type in
`type_list(x)` does have such an annotation_.  The final type in
`type_list(x)` is used.

Below is an example of a P4 code snippet that demonstrates one
example, but I do _not_ claim that it is useful for any actual
production P4 program to be written this way.

In the absence of a useful example of P4 code like this, it seems like
perhaps it may be a good idea for a P4 compiler to issue a warning or
error if such a `type_list` is found.

```
@p4runtime_translation("mycompany.com/psa/v1/T1_t", 32)
type bit<10> T1_t;
@p4runtime_translation("mycompany.com/psa/v1/T2_t", 18)
type T1_t T2_t;
T2_t f2;
```

```
type_info {
  new_types {
    key: "T1_t"
    value {
      // translated_type for type T1_t because it has
      // p4runtime_translation annotation
      translated_type {
        uri: "mycompany.com/psa/v1/T1_t"
        sdn_bitwidth: 32
      }
    }
  }
  new_types {
    key: "T2_t"
    value {
      // translated_type for type T2_t because it has
      // p4runtime_translation annotation
      translated_type {
        uri: "mycompany.com/psa/v1/T2_t"
        sdn_bitwidth: 18
      }
    }
  }
}
```
