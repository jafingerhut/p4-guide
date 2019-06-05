# Introduction

The P4_16 programs in this directory are intended to clarify how
instantiation works.  They are not intended to do anything useful in
terms of forwarding packets.

`extern-ref.p4` was written as a test of passing references to externs
to see if the open source P4 compiler would handle it, and since it
gave an error, Github issue https://github.com/p4lang/p4c/issues/794
was created with a copy of that program.  The issue was fixed in 2017,
and from my comment on the issue that year appears to have been fixed
then, but in 2019 it wasn't working again, so created another issue
https://github.com/p4lang/p4c/issues/1958 with `extern-ref-2.p4`,
which only uses v1model.p4, not an early prototype version of the
psa.p4 include file


# General rules for P4_16 instantiations

_Declarations_ of externs, parsers, and controls must always be done
at the top level in your P4_16 program.

P4_16 grammar rules: `externDeclaration`, `controlDeclaration`,
`parserDeclaration`

Examples of declarations:

```
// example externDeclaration
extern Register<T, S> {
  Register(S size);
  T    read  (in S index);
  void write (in S index, in T value);
}

// example parserDeclaration
parser ParserImpl(packet_in buffer,
                  out headers parsed_hdr)
{
    // This is the 'top level' inside the parser
    state start {
        transition parse_ethernet;
    }
}

// example controlDeclaration
control ingress(inout headers hdr,
                inout metadata user_meta)
{
    // This is the 'top level' inside the control
    apply { }
}
```

Declarations do _not_ automatically cause any _instances_ of those
things to be constructed.  Only _instantiations_ do that.

Examples of instantiations:

```
// The next line is a Register instantiation for an instance named
// reg0.  It is instantiated at the top level of the program, so
// globally accessible everywhere after it is instantiated.  It is
// legal to make method calls on this instance from both ingress and
// egress control blocks, for example.  Whether a particular P4 target
// device can actually implement that is up to the target.

// Extern instantiations at the top level are instantiated regardless
// of which parsers or controls are instantiated in your program.
Register<bit<48>, bit<6>>(50) reg0;

control ingress(inout headers hdr,
                inout metadata user_meta,
                PacketReplicationEngine pre,
                in  psa_ingress_input_metadata_t  istd,
                out psa_ingress_output_metadata_t ostd)
{
    // The next line is a Register instantiation for an instance named
    // reg1, that is local to the ingress control.  It is instantiated
    // at the 'top level inside of the control', so is visible
    // everywhere inside the control after the point where it is
    // instantiated.

    // This instantiation occurs once every time the enclosing control
    // is instantiated.  The ingress control block is typically
    // instantiated exactly one time, but you can create controls that
    // are instantiated multiple times.
    Register<bit<32>, bit<7>>(64) reg1;

    apply {
        bit<32> tmp;
        tmp = reg1.read((bit<7>) istd.ingress_port[5:0]);
        tmp = tmp + 0xdeadbeef;
        reg1.write((bit<7>) istd.ingress_port[5:0], tmp);
    }
}

// ParserImpl() is an instantiation of the parser ParserImpl above
// ingress() is an instantiation of the control ingress above
// The entire expression is an instantiation of the package PSA_Switch
// named 'main'.

PSA_Switch(ParserImpl(),
           verifyChecksum(),
           ingress(),
           egress(),
           computeChecksum(),
           DeparserImpl()) main;
```

All of the above has been documented in the P4_16 language
specification, Appendix F: "Restrictions on compile time and run time
calls" since version 1.1 of that specification was published, and
perhaps also since version 1.0.  See [here](https://p4.org/specs) for
the latest published version of the language specification.

+ externs can be instantiated in these places:
  + At the top level, visible everywhere later, globally in your program, or
  + Within a parser or control, visible everywhere later within that
    parser or control only.
  + Such instantiations need _not_ be supported within a parser state,
    action, table, or control `apply` block.
+ parsers can be instantiated only within other parsers, not at the
  top level, and not within a control.
+ controls can be instantiated only within other controls, not at the
  top level, and not within a parser.

+ It _is_ legal to pass 'references to' or 'names of' externs as
  parameters from one control to another, or from one parser to
  another.  See [p4-spec issue
  #361](https://github.com/p4lang/p4-spec/issues/361), and also the
  test program `extern-ref-3.p4` in this directory.  With latest open
  source p4c and behavioral-model as of 2019-May-23, `extern-ref-3.p4`
  does indeed update a packet counter 2 times for each processed
  packet, because the same counter object instance is passed twice to
  the same sub-control, and "each of them" (i.e. the same instance) is
  updated twice.
+ It _is_ legal to pass references to controls as _constructor_
  parameters from one control to another (i.e. at compile time, when
  all instantiations are being processed), but not as a run time
  parameter.  The same is true for passing parser instances to other
  parsers.

Controls can be instantiated in these two places: within other
controls, and as a parameter to a package instantiation.

Even so, it is still possible to have the same instance of an extern
object, control, or parser be used in multiple other places.  A
demonstration of this is in program `extern-ref-4.p4`.  See near the
end of that program for an "ASCII art" diagram of the "instantiation
graph".  That graph shows which instances can make calls on other
instances.  The basic idea is to create one of those things (extern
object, control, or parser) via instantiation, and give the
instantiation a name.  Then pass that name as a constructor parameter
to instantiations of more than one other thing, e.g. to more than one
control or parser instantiation.

----------------------------------------------------------------------

An architecture is probably allowed to have any number of
already-instantiated externs, controls, and parsers, that are always
part of every compiled P4 program for that architecture.  Those should
be documented as part of the architecture description.

There can be 0 or more top-level instantiations of externs in the P4
program.  Those occur first.  There can be references to these extern
instance names throughout the P4 program.

    Aside: I believe that effectively those occur, even if there are
    no uses of those instances later in the program.  If there are no
    uses of them, I can't think of any way in which they would be
    anything other than "dead code".  Perhaps they could "collude" or
    interact with other extern instantiations behind the scenes, but
    there is no way to see this in the P4 program source code
    directly.

The process of instantiation continues with the package instantiation
named "main".

Its parameters can be instantiations of 0 or more controls, parsers,
and/or extern objects.

Every time a control is instantiated, it causes:

+ 1 instantiation of each of table defined within it.
+ Every extern and control instantiation that is in the control source
  code at its top level is instantiated 1 time.

Every time a parser is instantiated, it causes:

+ Every extern and parser instantiation that is in the parser source
  code at its top level is instantiated 1 time.

----------------------------------------------------------------------

This Github issue comment:

https://github.com/p4lang/p4-spec/issues/361#issuecomment-318778037

asks this question:

Given the P4_16 v1.0.0 definition, is this conjecture true or false?

    Conjecture 1: Suppose control c1 is declared before control c2 in
    the program.  There is no way for an instance of c1 to call an
    instance of c2.

As a later comment on that issue shows via an example program, this is
false.  You can also see this in program `extern-ref-5.p4`, which is
identical to `extern-ref-4.p4`, except some control definitions have
been reordered.  The meaning of both programs `extern-ref-4.p4` and
`extern-ref-5.p4` is exactly the same.

Conjecture 1 _might_ be true in programs that do not use constructor
parameters for controls and parsers, but it is definitely false when
you can pass controls to other controls as constructor parameters,
which P4_16 allows.

I believe conjecture 2 is true:

    Conjecture 2: Suppose an instance c1_inst of control c1 is
    instantiated before an instance c2_inst of control c2 during the
    instantiation steps for the program, performed in the order
    described in the P4_16 language specification.  There is no way
    for c1_inst to call c2_inst.

I believe this is true because if an instantiation of a control,
parser, package, or extern object X refers to another instantiation Y,
then Y must fall into one of these cases:

+ Y was instantiated earlier, and is referred to by the name Y.  P4_16
  does not have any "forward declarations" of any kind, for instance
  names or any other kinds of names.

+ Y is instantiated within the instantiation of X itself.  It will be
  unnamed, but it is logically instantiated "just before" X is
  instantiated.
