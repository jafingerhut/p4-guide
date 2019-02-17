# Introduction

The program `psa-example-drop-all.p4` is not quite the simplest P4_16
program for the PSA architecture, but it is close.

Its ingress parser extracts an Ethernet header, and then an IPv4
header if the Ethernet protocol is 0x0800.  Its ingress control block
does nothing at all, and its ingress deparser emits the two headers
that the ingress parser can extract.

Its egress parser extracts nothing, its egress control block does
nothing, and its egress deparser emits the ethernet and IPv4 headers,
although since the egress parser does nothing, they should always be
invalid, and those two emit statements will do nothing.


# Test results

Commit of https://github.com/p4lang/p4c last tested with:
3ed8915a899730c5a65a2cfdda363a9609d769df 2019-Feb-16

Commit of https://github.com/p4lang/behavioral-model last tested with:
bd92b9c0f019ca8350b38313f47f2e798edf62a9 2019-Feb-14

The command:
```bash
$ make compile
```

produced the output file `psa-example-drop-all.json`.  After that,
attempting to run the PSA version of BMv2 `psa_switch` using this
command produced the error message shown below:

```bash
$ make run
psa_switch --log-console -i 1@veth2 -i 2@veth4 psa-example-drop-all.json
Calling target program-options parser
Duplicate objects of type 'parser' with name 'parser'
Makefile:5: recipe for target 'run' failed
make: *** [run] Error 1
```

That error message looks correct to me.  It occurs because in the file
`psa-example-drop-all.json`, the value of the key "parsers" is a list
of two parsers, and both have the same name "parser".

For PSA, there should always be two parsers as the value of the
"parsers" key, but they should have distinct names.  The names chosen
are up to us, the implementers of PSA, but I would suggest
"ingress_parser" and "egress_parser".

Even if you hand-edit the JSON file to make those two names different,
and try again, you will get an error message that there are duplicate
objects of type 'deparser' with name 'deparser'.  Similar to the
above, the value of the key "deparsers" is a list of two objects, both
with the name "deparser".  Again it is up to us, the PSA implementers,
to choose two names for the two deparsers in PSA, but I would
recommend "ingress_deparser" and "egress_deparser".

The file `psa-example-drop-all.hand-edited2.json` is a copy of
`psa-example-drop-all.json`, except with the changes above made, using
a text editor.

If you run the command `make run2` it attempts to run `psa_switch`
with this hand-edited BMv2 JSON file, but it still produces an error
message, as shown below:

```bash
$ make run2
psa_switch --log-console -i 1@veth2 -i 2@veth4 psa-example-drop-all.hand-edited2.json
Calling target program-options parser
Field standard_metadata.clone_spec is required by switch target but is not defined
Makefile:8: recipe for target 'run2' failed
make: *** [run2] Error 1
```

This is an error message produced by this line of behavioral-model
code:
https://github.com/p4lang/behavioral-model/blob/master/src/bm_sim/P4Objects.cpp#L2411-L2413

I believe that `psa_switch` and `simple_switch` are sharing this part
of their implementation right now, and it makes sense for
`simple_switch` implementing the v1model architecture to require that
the JSON file must have a field named `standard_metadata.clone_spec`.

However, whether such a field should be required for `psa_switch` JSON
input files is for the PSA implementers to decide.  I suspect it would
be best _not_ to require such a field to be present in the JSON input
file for `psa_switch`.  If any fields with particular names are
required to be present in the JSON input file for `psa_switch`, they
should be the names of PSA standard metadata fields defined in the PSA
specification, and `clone_spec` is not one of these.

As a quick hack, I created another file
`psa-example-drop-all.hand-edited3.json` that I copied and pasted a
definition of the v1model `standard_metadata` struct from the BMv2
JSON file for a simple_switch v1model program, just to see what might
go wrong next.  It starts up fine, but as soon as you send a packet in
for it to process, it crashes, I believe because like simple_switch it
is looking for a parser named "parser" in the JSON file, not
"ingress_parser" as I have changed it to.
