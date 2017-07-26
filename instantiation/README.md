# Introduction

The P4_16 programs in this directory are intended to clarify how
instantiation works.  They are not intended to do anything useful in
terms of forwarding packets.



# General rules for P4_16 instantiations

_Declarations_ of externs, parsers, and controls must always be done
at the top level in your P4_16 program (they are allowed in the
architecture definition, e.g. v1model.p4 or psa.p4).

TBD: What is the difference between grammar symbols
`controlTypeDeclaration` and `controlDeclaration`?

- For one, a `controlDeclaration` contains a `controlTypeDeclaration`.

- A `controlTypeDeclaration` consists only of optional annotations,
  the keyword 'control', a name, optional type paramters, and a
  parameter list enclosed in parentheses.  It does _not_ include
  `optConstructorParameters` and a control body enclosed in braces.

TBD: Similarly for `parserTypeDeclaration` vs. `parserDeclaration`.

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

package PSA_Switch<H, M>(Parser<H, M> p,
                         VerifyChecksum<H, M> vr,
                         Ingress<H, M> ig,
                         Egress<H, M> eg,
                         ComputeChecksum<H, M> ck,
                         Deparser<H> dep);
```

Declarations do _not_ automatically cause any _instances_ of those
things to be constructed.  Only _instantiations_ do that.

Examples of instantiations:

```

// ParserImpl() is an instantiation of the parser ParserImpl above
// ingress() is an instantiation of the control ingress above
// The entire expression is an instantiation of 
PSA_Switch(ParserImpl(),
           verifyChecksum(),
           ingress(),
           egress(),
           computeChecksum(),
           DeparserImpl()) main;
```

TBD: Is there any expected use case for having a package instantiation
other than 'main' in a P4_16 program, even if such a thing is not
expected to be used in v1model.p4 or psa.p4?

Instantations are only allowed these places:

* externs can be instantiated at the top level.  These are effectively
  "global", i.e. visible everywhere in your P4_16 program after they
  are instantiated.  It is legal in P4_16 to perform method calls on
  such an extern instance in any parser or control of your program,
  although an architecture like PSA might impose additional
  restrictions on where such method calls may be made.

* externs can be instantiated at "the top level within a control or
  parser", i.e. outside of any other syntactic elements inside of the
  enclosing parser or control.  These are only accessible within the
  parser or control where they are instantiated.  P4_16 does _not_
  support passing of anything like a reference or pointer to an
  instance between control blocks as parameters, for example.

* 2017-Jul-19 version of p4test and p4c-bm2-ss both give an error if
  you attempt to instantiate an extern inside of a parser state,
  action, or control `apply` block.

* 


TBD: Is it possible to pass some kind of reference to a control or
parser instance as any kind of a parameter, _except_ to a package
instantiation?

v1model.p4 and psa.p4 both use the ability to pass a reference to an
_extern_ as a parameter to a control, e.g. the extern
`PacketReplicationEngine pre` is an argument to the `Ingress` control
type in psa.p4, and the extern `packet_in` is an argument to the
`Parser` parser type in both.

Those passing of extern types seems like it must be 'by reference'?
Copy in/copy out doesn't seem to make sense for an extern state that
is hidden from the P4 program.
