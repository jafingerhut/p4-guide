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
      representation {
        translated_type {
          uri: "p4.org/psa/v1/PortId_t"
          sdn_bitwidth: 32
        }
      }
    }
    key: "MulticastGroup_t"
    value {
      representation {
	translated_type {
          uri: "p4.org/psa/v1/MulticastGroup_t"
          sdn_bitwidth: 32
	}
      }
    }
    key: "CloneSessionId_t"
    value {
      representation {
	translated_type {
          uri: "p4.org/psa/v1/CloneSessionId_t"
          sdn_bitwidth: 16
	}
      }
    }
    key: "ClassOfService_t"
    value {
      representation {
	translated_type {
          uri: "p4.org/psa/v1/ClassOfService_t"
          sdn_bitwidth: 8
	}
      }
    }
    key: "PacketLength_t_t"
    value {
      representation {
	translated_type {
          uri: "p4.org/psa/v1/PacketLength_t_t"
          sdn_bitwidth: 16
	}
      }
    }
    key: "EgressInstance_t_t"
    value {
      representation {
	translated_type {
          uri: "p4.org/psa/v1/EgressInstance_t_t"
          sdn_bitwidth: 16
	}
      }
    }
    key: "Timestamp_t_t"
    value {
      representation {
	translated_type {
          uri: "p4.org/psa/v1/Timestamp_t_t"
          sdn_bitwidth: 64
	}
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
p4c/testdata/p4_16_samples directory, which was in turn copied from
the p4-spec repository p4-16/psa/examples directory.

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
`expected-p4info-files/psa-example-digest-bmv2.psa.p4info.txt`.

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
