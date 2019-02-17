# Introduction

This document is a collection of a few thoughts on how the PSA
architecture could be implemented in the open source p4c and
behavioral-model code repositories:

+ https://github.com/p4lang/p4c
+ https://github.com/p4lang/behavioral-model


# Background on P4_16 v1model architecture

p4c can compile a P4_16 source program that included the v1model.p4
header file, which defines at least the interface to the features that
are specific to the v1model architecture.

When you run a command like:

```bash
p4c-bm2-ss myprog.p4 -o myprog.json
```

If there are no errors found, the compiler output is written to the
file `myprog.json`.  JSON is a widely used data file format, and
`myprog.json` uses that syntax, but over and above the syntax
requirements of JSON, such a file has a particular "schema" of keys
and values that can appear in that file, that the behavioral-model
`simple_switch` process expects to find there.

Many of these requirements and expectations are documented here, but
not everything one needs to know to create a PSA implementation:
https://github.com/p4lang/behavioral-model/blob/master/docs/JSON_format.md

I will call such a file a BMv2 JSON file, where BMv2 is an
abbreviation for Behavioral Model version 2, because a BMv2 JSON file
is a very limited subset of what is possible to represent in a JSON
data file.

I will use "v1model BMv2 JSON" or "PSA BMv2 JSON" to refer to the
contents of files specifically for the v1model architecture, or the
PSA architecture, when that distinction is important.

Note that _most_ of the "schema" of a BMv2 JSON file should be
identical between the v1model and PSA architectures.  For example,
there is probably no reason to change how parsers, arithmetic
expressions, actions, tables, and the ingress and egress controls are
represented in a simple_switch BMv2 JSON file, in a PSA BMv2 JSON
file.  These are at least 95% the same between v1model and PSA, and if
any changes are needed there at all, they will probably be very minor
tweaks from the existing v1model BMv2 JSON schema.

This document exists to try to focus on and describe the 5% or so that
should be different in a PSA BMv2 JSON file.


# 'Standard' or 'intrinsic' metadata

The terms "standard metadata" or "intrinsic metadata" seem to be used
interchangably in P4, to denote the metadata fields that are either
provided as inputs with a packet to be processed e.g.

+ the packet's ingress port
+ packet length,
+ whether the  was recirculated or not

or metadata fields that should be assigned a value by the user's P4
program and are thus outputs from their P4 code, e.g.

+ whether the packet should be dropped
+ if a packet should be unicast, to which output port it should be sent
+ whether the packet should be multicast replicated, and if so, which
  group of output ports it should be replicated to
+ whether the packet should be cloned

There may be some such metadata fields that are both an input and an
output, but no such example springs to mind as I am writing this.


## v1model standard metadata

In this section, I will simply say "JSON file" to mean "v1model BMv2
JSON file", unless explicitly qualified otherwise.

When you compile a P4_16 program using one of these commands:

```bash
% p4c-bm2-ss myprog.p4 -o myprog.json
% p4c --target bmv2 --arch v1model myprog.p4
```

When `simple_switch` executes a P4 program by reading and effectively
interpreting its JSON file, it looks for fields with specific field
names that are hard-coded at compile time into the `simple_switch`
program.  I believe you can find all of them by searching for
occurrences of `get_field` in this source file:
https://github.com/p4lang/behavioral-model/blob/master/targets/simple_switch/simple_switch.cpp

Many of these `get_field` calls are preceded by `has_field` calls, in
order to first check whether the JSON file even defines such a field.
I believe this is because there was a time when `simple_switch` did
not require such fields to be present, but wished to take advantage of
them if they were present, to be backwards compatible with earlier
JSON files that did not include definitions for those fields.

There is a (small) run-time cost to call `has_field` in addition to
`get_field`, so to avoid some `has_field` calls, `simple_switch`
checks for the presence of some of these fields while reading the JSON
file, and immediately quits with an error message if they are not
present.  You can find a list of those here:
https://github.com/p4lang/behavioral-model/blob/master/targets/psa_switch/psa_switch.cpp#L93


## PSA standard metadata

In this section, I will say "JSON file" to mean "PSA BMv2 JSON file",
unless explicitly qualified otherwise.

For the PSA architecture, I would suggest that _none_ of the v1model
standard metadata names should be required in a JSON file, and instead
_all_ of the PSA-specific standard metadata fields listed below should
be required when `psa_switch` reads a JSON file.  This will avoid the
need to call `has_field` after the JSON file has been read.  There is
no need at this time to support backwards compatibility with older
JSON files, because there are no such files.  If PSA is extended in
the future by adding new such fields, we will consider when adding
them to `psa_switch` whether to make them required or optional.

Below is the part of the psa.p4 include file that defines structs that
the user's P4 program is not allowed to change the definition of.

```
struct psa_ingress_parser_input_metadata_t {
  PortId_t                 ingress_port;
  PSA_PacketPath_t         packet_path;
}

struct psa_egress_parser_input_metadata_t {
  PortId_t                 egress_port;
  PSA_PacketPath_t         packet_path;
}

struct psa_ingress_input_metadata_t {
  // All of these values are initialized by the architecture before
  // the Ingress control block begins executing.
  PortId_t                 ingress_port;
  PSA_PacketPath_t         packet_path;
  Timestamp_t              ingress_timestamp;
  ParserError_t            parser_error;
}
// BEGIN:Metadata_ingress_output
struct psa_ingress_output_metadata_t {
  // The comment after each field specifies its initial value when the
  // Ingress control block begins executing.
  ClassOfService_t         class_of_service; // 0
  bool                     clone;            // false
  CloneSessionId_t         clone_session_id; // initial value is undefined
  bool                     drop;             // true
  bool                     resubmit;         // false
  MulticastGroup_t         multicast_group;  // 0
  PortId_t                 egress_port;      // initial value is undefined
}
// END:Metadata_ingress_output
struct psa_egress_input_metadata_t {
  ClassOfService_t         class_of_service;
  PortId_t                 egress_port;
  PSA_PacketPath_t         packet_path;
  EgressInstance_t         instance;       /// instance comes from the PacketReplicationEngine
  Timestamp_t              egress_timestamp;
  ParserError_t            parser_error;
}

/// This struct is an 'in' parameter to the egress deparser.  It
/// includes enough data for the egress deparser to distinguish
/// whether the packet should be recirculated or not.
struct psa_egress_deparser_input_metadata_t {
  PortId_t                 egress_port;
}
// BEGIN:Metadata_egress_output
struct psa_egress_output_metadata_t {
  // The comment after each field specifies its initial value when the
  // Egress control block begins executing.
  bool                     clone;         // false
  CloneSessionId_t         clone_session_id; // initial value is undefined
  bool                     drop;          // false
}
```

Here are proposed names that should appear in all PSA BMv2 JSON files,
to represent the fields above.

For those fields that are type `enum` in P4_16, there is already a
convention for the JSON file to define a name-to-numeric-value mapping
for the possible named values that a variable of type `enum` can have,
and these should be included in all PSA BMv2 JSON files and used by
`psa_switch`.  By having `psa_switch` use the values read from the
JSON file, it makes it somewhat easier to add new values to these
`enum` types in the future, if that becomes useful.

By making these names "hierarchical", they cause only one top-level
name "psa_stdmeta" to become "special" or "reserved" in the
implementation.  This seems preferable to making multiple such top
level names become reserved.

```
psa_stdmeta.psa_ingress_parser_input_metadata.ingress_port
psa_stdmeta.psa_ingress_parser_input_metadata.packet_path

psa_stdmeta.psa_egress_parser_input_metadata.egress_port
psa_stdmeta.psa_egress_parser_input_metadata.packet_path

psa_stdmeta.psa_ingress_input_metadata.ingress_port
psa_stdmeta.psa_ingress_input_metadata.packet_path
psa_stdmeta.psa_ingress_input_metadata.ingress_timestamp
psa_stdmeta.psa_ingress_input_metadata.parser_error

psa_stdmeta.psa_ingress_output_metadata.class_of_service
psa_stdmeta.psa_ingress_output_metadata.clone
psa_stdmeta.psa_ingress_output_metadata.clone_session_id
psa_stdmeta.psa_ingress_output_metadata.drop
psa_stdmeta.psa_ingress_output_metadata.resubmit
psa_stdmeta.psa_ingress_output_metadata.multicast_group
psa_stdmeta.psa_ingress_output_metadata.egress_port

psa_stdmeta.psa_egress_input_metadata.class_of_service
psa_stdmeta.psa_egress_input_metadata.egress_port
psa_stdmeta.psa_egress_input_metadata.packet_path
psa_stdmeta.psa_egress_input_metadata.instance
psa_stdmeta.psa_egress_input_metadata.egress_timestamp
psa_stdmeta.psa_egress_input_metadata.parser_error

psa_stdmeta.psa_egress_deparser_input_metadata.egress_port

psa_stdmeta.psa_egress_output_metadata.clone
psa_stdmeta.psa_egress_output_metadata.clone_session_id
psa_stdmeta.psa_egress_output_metadata.drop
```

Note that in a user's P4_16 program, the name of the `in` parameter to
the ingress parser can be any legal identifier name that does not
conflict with other names.  That is, when a user defines their ingress
parser, which will start with lines of code similar to the following:

```
parser IngressParser<H, M, RESUBM, RECIRCM>(
    packet_in buffer,
    out H parsed_hdr,
    inout M user_meta,
    in psa_ingress_parser_input_metadata_t istd,
    in RESUBM resubmit_meta,
    in RECIRCM recirculate_meta);
```

the user is free to use the name `istd` where it is shown in that
example, or to use any other name they wish.

TBD: Is it straightforward in `p4c` to accomodate any such name,
whether `istd` or some other name, and replace all occurrences of such
fields with the fixed names proposed above?  How exactly should p4c do
this?  Note that there is a similar issue with references to
`standard_metadata` fields in P4_16 programs for the v1model
architecture today, so hopefully this is a solved problem that merely
needs some small changes in `p4c`.

The of the type of the parameter `resubmit_meta` above is user-defined
in PSA.  It will typically be a `struct` type defined by the user,
perhaps with 0 fields in it, but can have any number of fields.  As
for `istd`, the name `resubmit_meta` could be any other legal P4_16
identifier name in a user's P4_16 program.

TBD: Should all occurrences of "resubmit_meta.<field_name>" be
replaced with a fixed prefix instead "resubmit_meta." in a JSON file?
It seems that there must be _some_ kind of naming convention in place
in order for `psa_switch` to know the contents of `resubmit_meta`,
vs. the contents of `recirculate_meta`, vs. the contents of other
fields that are outside of either of those.

If a fixed name in the JSON file is judged to be a good idea here, I
would propose these names:

```
psa_stdmeta.resubmit.<user_defined_field_name>
psa_stdmeta.recirculate.<user_defined_field_name>
psa_stdmeta.normal.<user_defined_field_name>
psa_stdmeta.clone_i2e.<user_defined_field_name>
psa_stdmeta.clone_e2e.<user_defined_field_name>
```
