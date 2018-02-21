# Introduction

The P4_16 programs in this directory are intended to clarify how
instantiation works.  They are not intended to do anything useful in
terms of forwarding packets.

`extern-ref.p4` was written as a test of passing references to externs
to see if the open source P4 compiler would handle it, and since it
gave an error, Github issue https://github.com/p4lang/p4c/issues/794
was created with a copy of that program.


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

+ externs can be instantiated in these places:
  + At the top level, visible every later globally in your program, or
  + Within a parser or control, visible everywhere later within that
    parser or control only.
  + _Not_ within a parser state, action, table, or control `apply`
    block.
+ parsers can be instantiated only within other parsers, not at the
  top level, and not within a control.
+ controls can be instantiated only within other controls, not at the
  top level, and not within a parser.
+ TBD: Is it legal to pass references to externs as parameters from
  one control to another?  From one parser to another?
  https://github.com/p4lang/p4-spec/issues/361
+ TBD: Is it legal to pass references to controls as parameters from
  one control to another?
+ TBD: Is it legal to pass references to parsers as parameters from
  one parser to another?

Controls can be instantiated in these two places: within other
controls, and as a parameter to a package instantiation.

If they cannot be instantiated in any other ways, and cannot be passed
as references in any way, then it appears that it is not possible to
apply() the same instance of a control block from both the ingress and
egress control blocks, or in general from any two different control
blocks.  Every control block is either 'owned' by one other control,
or by the package instantiation.

It is legal in P4_16 for one control to call apply() on a single
control instance multiple times.  TBD: Verify with a P4 program and
see if p4test compiles it, and the bigger challenge: whether
p4c-bm2-ss compiles it to something that simple_switch simulates with
that behavior.

Similarly it appears legal for one parser to call apply() on a single
parser instance multiple times.  TBD: Same as above.


TBD: Is there any expected use case for having a package instantiation
other than 'main' in a P4_16 program, even if such a thing is not
expected to be used in v1model.p4 or psa.p4?

Instantations are only allowed these places:

+ externs can be instantiated at the top level.  These are effectively
  "global", i.e. visible everywhere in your P4_16 program after they
  are instantiated.  It is legal in P4_16 to perform method calls on
  such an extern instance in any parser or control of your program,
  although an architecture like PSA might impose additional
  restrictions on where such method calls may be made.

+ externs can be instantiated at "the top level within a control or
  parser", i.e. outside of any other syntactic elements inside of the
  enclosing parser or control.  These are only accessible within the
  parser or control where they are instantiated.

+ 2017-Jul-19 version of p4test and p4c-bm2-ss both give an error if
  you attempt to instantiate an extern inside of a parser state,
  action, or control `apply` block.


TBD: What is the difference between grammar symbols
`controlTypeDeclaration` and `controlDeclaration`?

- For one, a `controlDeclaration` contains a `controlTypeDeclaration`.

- A `controlTypeDeclaration` consists only of optional annotations,
  the keyword 'control', a name, optional type paramters, and a
  parameter list enclosed in parentheses.  It does _not_ include
  `optConstructorParameters` and a control body enclosed in braces.

TBD: Similarly for `parserTypeDeclaration` vs. `parserDeclaration`.

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

Its parameters can be instantiations of 0 or more controls and
parsers.  TBD: Can a package instantiation also take extern
instantiations as parameters?

Every time a control is instantiated, it causes:

+ 1 instantiation of each of table defined within it.
+ Every extern and control instantiation that is in the control source
  code at its top level is instantiated 1 time.

Every time a parser is instantiated, it causes:

+ Every extern and parser instantiation that is in the parser source
  code at its top level is instantiated 1 time.

----------------------------------------------------------------------

% cd ~/p4c/testdata/p4_16_samples
% egrep 'control.*\).*\(' *.p4
generic1.p4:control c<T>()(T size) {
inline-control1.p4:control c(out bit<32> x)(Y y) {
inline-control.p4:control c(out bit<32> x)(Y y) {
issue496.p4:control C()(D d) {
pipe.p4:control T_host(inout TArg1 tArg1, in TArg2 aArg2)(bit<32> t2Size) {
pipe.p4:control P_pipe(inout TArg1 pArg1, inout TArg2 pArg2)(bit<32> t2Size) {
table-entries-exact-bmv2.p4:control deparser(packet_out b, in Header_t h) { apply { b.emit(h.h); } }
table-entries-exact-ternary-bmv2.p4:control deparser(packet_out b, in Header_t h) { apply { b.emit(h.h); } }
table-entries-lpm-bmv2.p4:control deparser(packet_out b, in Header_t h) { apply { b.emit(h.h); } }
table-entries-priority-bmv2.p4:control deparser(packet_out b, in Header_t h) { apply { b.emit(h.h); } }
table-entries-priority-bmv2.p4:            0x1111 &&& 0xF    : a_with_control_params(1) @priority(3);
table-entries-priority-bmv2.p4:            0x1181 &&& 0xF00F : a_with_control_params(3) @priority(1);
table-entries-range-bmv2.p4:control deparser(packet_out b, in Header_t h) { apply { b.emit(h.h); } }
table-entries-ternary-bmv2.p4:control deparser(packet_out b, in Header_t h) { apply { b.emit(h.h); } }
table-entries-valid-bmv2.p4:control deparser(packet_out b, in Header_t h) { apply { b.emit(h.h); } }

Manually trim that set of lines to remove those that are clearly
within parser state definitions, or are otherwise clearly not a
control with constructor parameters:

generic1.p4:control c<T>()(T size) {
inline-control1.p4:control c(out bit<32> x)(Y y) {
inline-control.p4:control c(out bit<32> x)(Y y) {
issue496.p4:control C()(D d) {
pipe.p4:control T_host(inout TArg1 tArg1, in TArg2 aArg2)(bit<32> t2Size) {
pipe.p4:control P_pipe(inout TArg1 pArg1, inout TArg2 pArg2)(bit<32> t2Size) {


----------------------------------------------------------------------

This Github issue comment:

https://github.com/p4lang/p4-spec/issues/361#issuecomment-318778037

asks this question:

Given the P4_16 v1.0.0 definition,

True or false: Suppose control c1 is declared before control c2 in the
program. There is no way for an instance of c1 to call an instance of
c2.

I believe the answer is true, because: For c1 to call another control
c2, c1 must either instantiate c2 inside of c1's declaration, or it
must take an instance of c2 as a constructor parameter. c1 cannot name
or refer to an instance of c2 in any other way. To do either of those
things, c2 must be declared before c1, otherwise the type c2 is
undefined while c1 is being declared.

The same reasoning applies to parsers and their instances, too.

----------------------------------------------------------------------

Assume for the moment that the answer to the "True or false"
proposition above is "True".

Are there any ways to invoke the _same_ instance of a control block
more than one time per packet?

It would be easy if control blocks could be instantiated at the top
level, but they cannot.

Even so, I believe it should be possible using the fact that when
instantiating a control block, you can pass an instance of another
control as a contructor parameter.  Here is the skeleton of it:

control c1() { }

control c2() (control c1) {
    apply {
        c1.apply();
    }
}

control c3() (control c1) {
    apply {
        c1.apply();
    }
}

control c4() {
    c1() c1_inst;
    c2(c1_inst) c2_inst;
    c2(c1_inst) c3_inst;
    apply {
        c2_inst.apply();
        c3_inst.apply();
    }
}
