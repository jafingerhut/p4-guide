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

Most of these names begin with `"standard_metadata."`,
e.g. "standard_metadata.egress_spec".  The `"header_types"` section
(example
[here](https://github.com/jafingerhut/p4-guide/blob/master/psa-examples/v1model-unicast-or-drop.json#L2))
of the JSON file contains a header type named `"standard_metadata"` (see
[here](https://github.com/jafingerhut/p4-guide/blob/master/psa-examples/v1model-unicast-or-drop.json#L8-L35)),
and the `"headers"` section (example
[here](https://github.com/jafingerhut/p4-guide/blob/master/psa-examples/v1model-unicast-or-drop.json#L46))
of the JSON file contains a header called `"standard_metadata"` with
type `"standard_metadata"` (example
[here](https://github.com/jafingerhut/p4-guide/blob/master/psa-examples/v1model-unicast-or-drop.json#L54-L60)).
Yes, it allows header names and header_type names to be the same.

As an implementation detail, there are also fields like `"mcast_grp"`
defined in the standard_metadata struct in the `v1model.p4` include
file, which have "aliases" to them in a section of the JSON file
called `"field_aliases"` (example
[here](https://github.com/jafingerhut/p4-guide/blob/master/psa-examples/v1model-unicast-or-drop.json#L319)).

Why are there aliases?  I do not know the full history, but P4_14
program compiled using `p4c` have been recommended to define a header
called `"intrinsic_metadata"` that contains fields such as
`"mcast_grp"`, in addition to the header named `"standard_metadata"`.
In P4_16 v1model programs, all fields inside of `"intrinsic_metadata"`
have been moved into `"standard_metadata"`.  For `simple_switch` to
work with both, an alias named `"intrinsic_metadata.mcast_grp"` is
created in the JSON file, which 'points at' the name
`"standard_metadata.mcast_grp"` (example
[here](https://github.com/jafingerhut/p4-guide/blob/master/psa-examples/v1model-unicast-or-drop.json#L348-L351)).

For the v1model architecture, the "standard_metadata" header always
appears in the "headers" section of the v1model BMv2 JSON file, and
simple_switch.cpp expects to be able to look up field names using C++
get_field calls with constant strings like
"standard_metadata.egress_spec" and, for some v1model programs, field
names like "intrinsic_metadata.mcast_grp".

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

For the PSA architecture, all of the "standard metadata" fields and
structs are different than v1model.  They support pretty much the same
_features_, e.g. drop or do not drop the packet, unicast to this
output port, multicast to this group of output ports, clone the packet
or not, etc., but the group of people designing PSA had an opportunity
for a fresh start, and we believe we may have cleaned up a few things
and made the behavior more precise than some earlier systems were
documented.

Thus for JSON files compiled from PSA programs, there is no reason at
all to have a header type, nor a header, named `"standard_metadata"`.
If there were, it would not be used.

Instead, we recommend that such JSON files include the following
header types in the `"header_types"` section.  The numeric id values
are shown as "TBD" because it is perfectly fine for those to vary from
one run of the p4c compiler to another, generated at compile time.
These type names and field names come from the psa.p4 include file
[here](https://github.com/p4lang/p4c/blob/master/p4include/psa.p4#L282-L336).

Notes on the bit widths below:

Some of the bit widths given could be different than shown below.  For
example, if there is a good reason to make the timestamps 48 bits
instead of 64, I can't think of any strong objection there.

Values that have type `enum` in the P4_16 source code can perfectly
reasonably be implemented using 32-bit wide values in the JSON file,
but less is reasonable, too.  32 bits have been used for such values
in v1model JSON files so far without problems.  There is no strong
need in BMv2 to optimize the bit width of such values to the minimum
possible.

I have used 1 for the bit width of values that have type `bool` in the
P4_16 source code.  Antonin may recommend more bits there for
efficiency of software in `psa_switch`.

If a P4_16 type has a bit width defined in a `p4runtime_translation`
annotation in the psa.p4 include file, Antonin Bas has recommended
that width be used in the JSON file, to avoid the need to numerically
translate those values in the control plane code.  They still _may_ be
translated, but it is not necessary in a first implementation.

```
  // ... earlier parts of JSON file here, if any
  "header_types" : [
    {
      "name" : "psa_ingress_parser_input_metadata_t",
      "id" : TBD,
      "fields" : [
        ["ingress_port", 32, false],
        ["packet_path", 32, false]
      ]
    },
    {
      "name" : "psa_ingress_input_metadata_t",
      "id" : TBD,
      "fields" : [
        ["ingress_port", 32, false],
        ["packet_path", 32, false]
        ["ingress_timestamp", 64, false]
        ["parser_error", 32, false]
      ]
    },
    {
      "name" : "psa_ingress_output_metadata_t",
      "id" : TBD,
      "fields" : [
        ["class_of_service", 8, false],
        ["clone", 1, false],
        ["clone_session_id", 16, false],
        ["drop", 1, false],
        ["resubmit", 1, false],
        ["multicast_group", 32, false],
        ["egress_port", 32, false]
      ]
    },
    {
      "name" : "psa_egress_parser_input_metadata_t",
      "id" : TBD,
      "fields" : [
        ["egress_port", 32, false],
        ["packet_path", 32, false]
      ]
    },
    {
      "name" : "psa_egress_input_metadata_t",
      "id" : TBD,
      "fields" : [
        ["class_of_service", 8, false],
        ["egress_port", 32, false],
        ["packet_path", 32, false],
        ["instance", 16, false],
        ["egress_timestamp", 64, false],
        ["parser_error", 32, false]
      ]
    },
    {
      "name" : "psa_egress_deparser_input_metadata_t",
      "id" : TBD,
      "fields" : [
        ["egress_port", 32, false]
      ]
    },
    {
      "name" : "psa_egress_output_metadata_t",
      "id" : TBD,
      "fields" : [
        ["clone", 1, false],
        ["clone_session_id", 16, false],
        ["drop", 1, false]
      ]
    }
    // ... other user-defined header types go here, or mingled with
    // the above header types.  The order in the JSON file is not
    // important.
  ],
  // ... later parts of JSON file here, if any
}
```

The `"headers"` section of a PSA JSON file should contain at least
these headers shown below.

Again the id values are shown as TBD, since they can be generated by
p4c, and need not be the same from one p4c run to the next.

TBD: I do not know what the `"pi_omit"` field signifies, and so am not
sure whether it is important what its value is here.

```
  // ... earlier parts of JSON file here, if any
  "headers" : [
    {
      "name" : "psa_ingress_parser_input_metadata",
      "id" : TBD,
      "header_type" : "psa_ingress_parser_input_metadata_t",
      "metadata" : true,
      "pi_omit" : true
    },
    {
      "name" : "psa_ingress_input_metadata",
      "id" : TBD,
      "header_type" : "psa_ingress_input_metadata_t",
      "metadata" : true,
      "pi_omit" : true
    },
    {
      "name" : "psa_ingress_output_metadata",
      "id" : TBD,
      "header_type" : "psa_ingress_output_metadata_t",
      "metadata" : true,
      "pi_omit" : true
    },
    {
      "name" : "psa_egress_parser_input_metadata",
      "id" : TBD,
      "header_type" : "psa_egress_parser_input_metadata_t",
      "metadata" : true,
      "pi_omit" : true
    },
    {
      "name" : "psa_egress_input_metadata",
      "id" : TBD,
      "header_type" : "psa_egress_input_metadata_t",
      "metadata" : true,
      "pi_omit" : true
    },
    {
      "name" : "psa_egress_deparser_input_metadata",
      "id" : TBD,
      "header_type" : "psa_egress_deparser_input_metadata_t",
      "metadata" : true,
      "pi_omit" : true
    },
    {
      "name" : "psa_egress_output_metadata",
      "id" : TBD,
      "header_type" : "psa_egress_output_metadata_t",
      "metadata" : true,
      "pi_omit" : true
    }
    // ... other header variables here, or mingled with the above.  As
    // for header_types, the order of header instances in the JSON
    // file is not important.
  ],
  // ... later parts of JSON file here, if any
```

Note: By the design choice above, those 7 header names become
"reserved" in the PSA architecture, at least in the JSON file.  If a
P4 source program defines headers with those variable names, they
might conflict.  TBD: Perhaps p4c code already avoids such name
conflicts by auto-renaming the user variables if they happen to be the
same.  A quick test of that would be trying to create a user-defined
struct in a P4_16 v1model architecture program named
"standard_metadata" and see what the v1model BMv2 JSON file contained.
I would not consider it critical to add such auto-renaming if it is
not already there, since it seems unlikely users would pick the names
above for their own variables, but it would be good to document this
somewhere if it is or isn't done.

I would recommend that _all_ of the PSA-specific standard metadata
fields listed above should be required when `psa_switch` reads a JSON
file.  This will avoid the need to call `has_field` after the JSON
file has been read.  There is no need at this time to support
backwards compatibility with older JSON files, because there are no
such files.  If PSA is extended in the future by adding new such
fields, we will consider when adding them to `psa_switch` whether to
make them required or optional.

At the very least, an initial implementation should probably require a
few of these fields, as a sanity check that the JSON file was compiled
from a PSA architecture program, rather than v1model architecture
program.

In a user's P4_16 program that includes the psa.p4 file, they can
define their own parameter names for the parameters of each of the
above types, and can even choose different names for the Ingress and
IngressDeparser controls for parameters with the same type.  For
example:

```
control cIngress(inout headers_t hdr,
                 inout metadata_t user_meta,
                 in    psa_ingress_input_metadata_t  istd,
                 inout psa_ingress_output_metadata_t ostd)
{
    // ... more code here
}

control IngressDeparserImpl(packet_out buffer,
                            out empty_metadata_t clone_i2e_meta,
                            out empty_metadata_t resubmit_meta,
                            out empty_metadata_t normal_meta,
                            inout headers_t hdr,
                            in metadata_t meta,
                            in psa_ingress_output_metadata_t istd)
{
    // ... more code here
}
```

The struct of type `psa_ingress_output_metadata_t` that is called
`ostd` when a parameter to the `cIngress` control, is called `istd`
when a parameter to the `IngressDeparserImpl` control.  There is
currently no restriction on these parameter names, other than no two
parameter names to the _same_ control can be identical.  Across
different controls, parameter names can be reused, just as they can in
other programming languages for function or method definitions.

So since the struct with type `psa_ingress_output_metadata_t` has a
field `drop` with type `bool`, that field is called `ostd.drop` in the
P4_16 source code of control `cIngress`, but `istd.drop` in the source
code of the control `IngressDeparserImpl`.

The recommendation here is that `p4c`, when it uses this field in the
BMv2 JSON 'code', like arithmetic expressions, for these two controls,
both should refer to the header named `"psa_ingress_output_metadata"`,
field `"drop"`.  The parameter names like `istd` and `ostd` should not
appear in those field references at all.

Aside: It appears that for p4c compiling v1model architecture
programs, the parameter names are already not included in the JSON
file when referencing standard_metadata fields.  I do not know the
precise mechanism by which this occurs, but I suspect it is in the p4c
bmv2 back end code for v1model, because the P4_16 code emitted after
the last midend pass of the compiler still includes these parameter
names.

`istd` and `ostd` _may_ appear in the JSON file in strings that are
the values of `"source_fragment"` fields, but those strings are only
used to print logging information for a developer to read.  There is
no reason to avoid including such parameter names in those strings.
It is good if they are there, since it more closely matches the
developer's source code.


### Optional extra aliases for the benefit of p4dbg

The recommendations in this section are not needed in order to forward
packets in `psa_switch`.  They are optional extra niceties that
Antonin Bas says would be useful for the `p4dbg` debugger.

In the `"field_aliases"` section, for every PSA standard metadata
field, create one alias to it for each distinct name of the form
`"<parser_or_control_name>.<parameter_name>"` that it is named in the
source program.

For this example code snippet:

```
control cIngress(inout headers_t hdr,
                 inout metadata_t user_meta,
                 in    psa_ingress_input_metadata_t  istd,
                 inout psa_ingress_output_metadata_t ostd)
{
    // ... more code here
}

control IngressDeparserImpl(packet_out buffer,
                            out empty_metadata_t clone_i2e_meta,
                            out empty_metadata_t resubmit_meta,
                            out empty_metadata_t normal_meta,
                            inout headers_t hdr,
                            in metadata_t meta,
                            in psa_ingress_output_metadata_t istd)
{
    // ... more code here
}
```

There should be these aliases created for the struct of type
`psa_ingress_output_metadata_t`:

```
  // ... earlier parts of JSON file here, if any
  "field_aliases" : [
    // one alias for each of the 7 fields of psa_ingress_output_metadata,
    // with a prefix of "cIngress.ostd."
    [
      "cIngress.ostd.class_of_service",
      ["psa_ingress_output_metadata", "class_of_service"]
    ],
    [
      "cIngress.ostd.clone",
      ["psa_ingress_output_metadata", "clone"]
    ],
    [
      "cIngress.ostd.clone_session_id",
      ["psa_ingress_output_metadata", "clone_session_id"]
    ],
    [
      "cIngress.ostd.drop",
      ["psa_ingress_output_metadata", "drop"]
    ],
    [
      "cIngress.ostd.resubmit",
      ["psa_ingress_output_metadata", "resubmit"]
    ],
    [
      "cIngress.ostd.multicast_group",
      ["psa_ingress_output_metadata", "multicast_group"]
    ],
    [
      "cIngress.ostd.egress_port",
      ["psa_ingress_output_metadata", "egress_port"]
    ],
    // one alias for each of the 7 fields of psa_ingress_output_metadata,
    // with a prefix of "IngressDeparserImpl.istd."
    [
      "IngressDeparserImpl.istd.class_of_service",
      ["psa_ingress_output_metadata", "class_of_service"]
    ],
    [
      "IngressDeparserImpl.istd.clone",
      ["psa_ingress_output_metadata", "clone"]
    ],
    [
      "IngressDeparserImpl.istd.clone_session_id",
      ["psa_ingress_output_metadata", "clone_session_id"]
    ],
    [
      "IngressDeparserImpl.istd.drop",
      ["psa_ingress_output_metadata", "drop"]
    ],
    [
      "IngressDeparserImpl.istd.resubmit",
      ["psa_ingress_output_metadata", "resubmit"]
    ],
    [
      "IngressDeparserImpl.istd.multicast_group",
      ["psa_ingress_output_metadata", "multicast_group"]
    ],
    [
      "IngressDeparserImpl.istd.egress_port",
      ["psa_ingress_output_metadata", "egress_port"]
    ]
  ],
  // ... later parts of JSON file here, if any
```

Other aliases should be created for the struct of type
`psa_ignress_input_metadata_t`, too, with a prefix of
`"cIngress.istd."` in the alias names, but those are not shown above.
Hopefully their contents should be straightforward to understand,
following from the example above.


## User-defined metadata and headers in the PSA BMv2 JSON file

The main issue to note here is that unlike the v1model architecture,
where the user-defined metadata struct was required to be the same
type for both ingress and egress code, PSA allows the ingress
user-defined metadata struct to be a different type (or the same type)
as the egress user-defined metadata struct.

Similarly for the struct containing headers.  v1model required ingress
and egress to be the same there.  PSA allows them to be different, or
the same.

Also, in PSA, neither the user-defined metadata nor headers are
automatically copied from ingress to egress for unicast and multicast
packets.  In the v1model architecture, it is.  In PSA, when a unicast
or multicast replicated copy starts egress processing, all of its
header variables are invalid, and all user-defined metadata fields are
uninitialized.  The egress parser parses the packet emitted by the
ingress deparser, and makes its own decisions, independent of the
ingress parser code, on what headers are extracted and made valid.

Because these user-defined header and metadata structs can have
completely different types, it is recommended that in the JSON file,
the header variables created in the `"headers"` section have different
names for ingress vs. egress, to avoid them sharing state or having
conflicting fields with the same field name but different types.
Using distinct header names for ingress vs. egress should also help
prevent "accidentally" preserving the ingress values of these things
when a packet starts egress processing.

It is recommended that all user-defined header and metadata variables
have a prefix of `"ig."` for ingress, and `"eg."` for egress.  There
is no reason to have separate prefixes for ingress parser vs. ingress
control vs. ingress deparser, since the type of user-defined metadata
is requires to be the same for those 3 things in PSA, and it is
desired and expected that the values modified by the ingress parser
are visible and available to the ingress control, and if they are
modified in the ingress control, those values are visible and
available in the ingress deparser.

TBD: Document recommendations for the user-defined structs with these
types:

```
RESUBM
RECIRCM
CI2EM
CE2EM
NM
```


## PSA enum types in the psa.p4 include file

For those fields that are type `enum` in P4_16, there is already a
convention for the JSON file to define a name-to-numeric-value mapping
for the possible named values that a variable of type `enum` can have,
and these should be included in all PSA BMv2 JSON files and used by
`psa_switch`.  By having `psa_switch` use the values read from the
JSON file, it makes it somewhat easier to add new values to these
`enum` types in the future, if that becomes useful.

For the v1model architecture, p4c never generates such `"enum"`
definitions in the v1model JSON file for enum's defined in the
v1model.p4 include file.  See this issue for some details as to why:
https://github.com/p4lang/p4c/issues/1779

For the enum types defined in v1model.p4, all of them are expected
_not_ to be the types of user-defined run-time variables.  All of them
are only expected to be used as compile-time constant parameter values
to extern calls, e.g. when calling the constructor for a meter or
counter.  Thus it is not a significant problem that p4c does not
support declaring a run-time variable with one of those enum types.

For PSA, we _do_ expect at least some P4 programs to declare and use
run-time variables with type `PSA_PacketPath_t` and
`PSA_MeterColor_t`.  It would not be a problem if p4c supported
run-time variables of other enum types declared in the psa.p4 include
file, but it is not necessary, as they are also most commonly expected
only to be used as compile-time constant parameters to constructor
calls.

For the two enum types `PSA_PacketPath_t` and `PSA_MeterColor_t`, the
recommendation is that p4c assign numeric values for each of the
possible values, and use a 32-bit integer value in the generated JSON
for those variables.  This might seem unnecessarily large, but it has
been done for enums in v1model programs for a long time without
problem, and it can be optimized to smaller bit widths later if
desired.

The recommendation is also that the PSA BMv2 JSON file should always
include entries in the `"enums"` section defining the name to number
mapping for those two PSA enum types.  It is likely that these values
will be consistent from one compilation run to another, but as long as
the name to number mapping is in the JSON file, it does not matter
much whether it is consistent across compilation runs or not.

`psa_switch` should always look for the name to numeric value mapping
for those 2 enum types in a JSON file it is given, and _use_ those
values whenever necessary.

For example `psa_switch.cpp` will have code to assign values to fields
of standard metadata structs with a field named `packet_path` that has
this type.  The numeric values that this C++ code must assign to these
values should be determined from the numeric value associated with the
correct enum member name.  For example, if some code in
`psa_switch.cpp` wants to assign a value of
`PSA_PacketPath_t.RESUBMIT` to a field while a packet is being
processed, it must _not_ pick a hard-coded numeric value.  It must use
the numeric value associated with the `RESUBMIT` enum member from the
JSON file.  For efficiency, it is perfectly fine and expected if
`psa_switch` does not do a string lookup every time it wants to find
this numeric value.

The code in `psa_switch` for executing meters has likely been copied
from the corresponding code for `simple_switch`, and uses hard-coded
numeric values for the 3 meter colors RED, GREEN, and YELLOW.  For
`psa_switch`, it is perfectly fine to continue using those 3
hard-coded values internally in the C++ code, but before a value is
stored in a variable visible to the user's field, it must be converted
to the numeric value for the appropriate named color as stored in the
JSON file.
