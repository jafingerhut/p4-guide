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

It is straightforward in `p4c` to accomodate any such name, whether
`istd` or some other name.  Han Wang refers us to function
`isStandardMetadataParameter` in the p4c back end code here for an
example of how p4c recognizes the v1model-defined parameters today:
https://github.com/p4lang/p4c/blob/master/backends/bmv2/simple_switch/simpleSwitch.h#L72

Antonin Bas recommends keeping the original user-defined parameter
names from the source code in the JSON file, and then using the BMv2
JSON `"field_aliases"` feature to give these fields fixed names
proposed above, by which `psa_switch` can find them using `get_field`:
https://github.com/p4lang/behavioral-model/blob/master/docs/JSON_format.md#field_aliases

By following that approach, it may enhance debuggability by enabling
the user-defined names to appear in the JSON file, and thus also
logging/debug messages from `psa_switch`.

TBD: For P4_16 v1model architecture programs, as of 2019-Feb
p4c-bm2-ss produces v1model BMv2 JSON files that do not include the
parameter names _at all_, except in source_fragment strings, as far as
I can tell.  They appear in the last midend pass P4_16 program that
you can dump from p4c via debugging options, but then do not appear in
the JSON file.  I do not know if it is worth trying to _add_ them in a
PSA BMv2 JSON file if they are not present in the v1model BMv2 JSON
files.

The type of the parameter `resubmit_meta` above is user-defined in
PSA.  It will typically be a `struct` type defined by the user,
perhaps with 0 fields in it, but can have any number of fields.  As
for `istd`, the name `resubmit_meta` could be any other legal
identifier name in a user's P4_16 program.

Recommendation: Use the `"field_aliases"` feature, mentioned above, so
that the user-defined name `resubmit_meta.<rest_of_user_defined_name>`
is used in the BMv2 JSON file, but in addition aliases are created
with names mentioned below by which `psa_switch` can find them.

```
psa_stdmeta.resubmit.<rest_of_user_defined_name>
psa_stdmeta.recirculate.<rest_of_user_defined_name>
psa_stdmeta.normal.<rest_of_user_defined_name>
psa_stdmeta.clone_i2e.<rest_of_user_defined_name>
psa_stdmeta.clone_e2e.<rest_of_user_defined_name>
```

Note that the user's program could have the same parameter name,
e.g. `user_meta` for both the ingress and egress control block.  These
two parameters could have the same type, or different types from each
other.  Even if they do have the same types, the egress `user_meta`
contents must be determined by the egress parser, and should _never_
have their values carried over from an ingress packet processing
results, the way they are in the v1model architecture.  Since all
header names in BMv2 JSON files are effectively "global" for the
entire program, these parameter names should be uniquified, e.g. by
always prefacing all ingress parameter names with `ingress` and all
egress parameter names with `egres.`.

Also note that while it would be fairly odd for a programmer to do so,
a P4_16 source program could have an ingress parser and an ingress
control block with _different_ parameter names for the user-defined
metadata, e.g. `user_meta` for the ingress control block, but `foo`
for the ingress parser.

As mentioned in a note above, p4c appears as of 2019-Feb appears to
remove these parameter names while generateing the v1model BMv2 JSON
files.  This seems reasonable to continue to do with PSA, as long as
the `ingress` and `egress` prefixes are added to the names to keep
ingress and egress values separate.
