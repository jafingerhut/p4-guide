# Introduction

The P4 files in this directory are intended to demonstrate by example
one way that a multi-pipeline PSA (Portable Switch Architecture)
device could be made explicit in P4_16 code, rather than implicit.


# Normal 1-pipeline version of the code

There is nothing special about this version of the example code.  It
is included in this repository to make it convenient to run `diff`
against this version and the one below.

The file `psa-1pipeline.p4` is exactly the same as the draft version
of `psa.p4` that is the latest one checked in here as of 2017-Jul-24:

    https://github.com/p4lang/p4-spec/blob/master/p4-16/psa/psa.p4

The file `example-1pipeline.p4` includes `psa-1pipeline.p4`, and
defines one parser, and the 5 control blocks expected by the package
declaration in `psa-1pipeline.p4` (verifyChecksum, ingress, egress,
computeChecksum, deparser).

It instantiates 2 `Counter` externs named `port_bytes_in` and
`port_bytes_out`, a `Register` named `reg1`, and a `Meter` named
`meter1`.  Note that none of these are instantiated globally, at the
top level of the code.  Instead, all of them are instantiated inside
of the ingress or egress control block where they are used.  I believe
this has two effects that are important for the purposes of this
example:

+ The instance can only be accessed, i.e. have method calls performed
  on it, from within that control block.

+ If the control block itself is instantiated multiple times, each
  such instance will have its own separate instantiation of the
  externs, with independent state inside of each copy.

The control blocks `ingress` and `egress` are only instantiated 1 time
each by the instantiation of the package `PSA_Switch` at the end of
the file.


# Possible 4-pipeline version of the code

The file `psa-multipipe.p4` is not much different from
`psa-1pipeline.p4`.  Grab a copy of these files and `diff` them
yourself to verify, but everything is the same except that
`psa-multipipe.p4` defines a macro named `NUM_PIPELINES`, and based
upon its value, performs one of 4 slightly different package type
declarations for `PSA_Switch`.  The only difference between them is
the number of parsers, ingress, egress, etc. that they take as
arguments.

As a simple aid to using this different `PSA_Switch` package type
declaration from inside of a P4_16 program, `psa-multipipe.p4` also
has a `#define` for a macro named `PSA_SWITCH_MULTIPIPE`.  It takes
exactly 1 parser, ingress, egress, etc. blocks, and then instantiates
`PSA_Switch` with 1, 2, 3, or 4 copies of those arguments.


The file `example-multipipe.p4` is identical to
`example-1pipeline.p4`, except that it includes `psa-multipipe.p4`,
and it invokes the macro `PSA_SWITCH_MULTIPIPE` near the end.

If I haven't made any mistakes, `example-multipipe.p4` can be compiled
on a PSA implementation that has any number of pipelines that is
supported by the file `psa-multipipe.p4` that it includes, and when
compiled it will automatically instantiate the correct number of
copies of each parser and control block for the target device.
