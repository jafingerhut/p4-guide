# Small design notes on P4_16, `type`, and casts

See also the References section of [this
document](../p4runtime/README-p4info-and-type.md) for more details on
the `type` declaration in P4_16, and how it is inteded to be used in
the PSA architecture for "marking" in the auto-generated P4Runtime API
file called "p4info" all values that need runtime translation between
the control plane software and the data plane, like values of type
`PortId_t`, representing a port id in the data plane.

When you define a `type` in P4_16, e.g. `type bit<32> IPv4Address_t;`,
you can define variales, struct fields, and header fields with type
`IPv4Address_t`, and they will be 32-bit wide unsigned integers, but
the only way you are allowed to assign their values to values declared
as `bit<32>` is via an explicit cast, and the same is true in the
opposite direction.

```
type bit<32> IPv4Address_t;

control ingress (
                 // ... parameters omitted
                )
{
    bit<32> x;
    IPv4Address_t y;

    apply {
        x = y;   // compiler gives error for this
        y = x;   // and also this

        x = (bit<32>) y;   // this is legal, and causes no change in the 32 bits
        y = (IPv4Address_t) x;  // also legal
    }
}
```

A perfectly reasonable question to ask is "Why not just automatically
cast these values to each other?  It looks easy enough for a compiler
to figure out on its own."

I believe that perhaps there might not be as much of a worry about
adding such casts automatically, except perhaps for one thing: table
search key fields can be pretty much arbitrary arithmetic expressions.
It is true that most people write simple names of header or struct
fields as search key fields, but the following syntax is legal P4_16,
too:

```

// Something similar to this is in the psa.p4 include file for the PSA
// architecture.

type bit<9> PortId_t;
struct something_t {
    PortId_t ingress_port;
    // ... other fields here
}

// Suppose you wrote this in your P4_16 program that included psa.p4:

control ingress (
                 // ... parameters omitted
                )
{
    something_t istd;
    bit<9> foo;

    table t1 {
        key = {
            istd.ingress_port + foo : exact @name("srcAddr");
        }
        // ... actions, etc. here
    }
    apply {
        t1.apply();
    }
}
```

As defined above, Both `istd.ingress_port` and `foo` are 9 bits wide,
and unsigned.

Today P4_16 as defined makes the expression `istd.ingress_port + foo`
illegal, because the type `PortId_t` cannot be mingled with values of
type `bit<9>`.

You obviously jump to the question: But what if I don't want to
require programmers to include a cast for that expression to work?  I
want an implicit cast!

OK, let us explore the idea for a minute.  What implicit cast should
be added?

Should the resulting type be `bit<9>`, or `PortId_t`?

If you picked `bit<9>`, why not `PortId_t`?

If you picked `PortId_t`, why not `bit<9>`?

The answer to those questions could lead to what some might think of
as semi-arbitrary looking rules for what implicit casts to add.  Even
if they are completely 100% deterministic and defined by the language,
do you want to impose the cognitive overhead on P4 programmers to
remembering what those rules are?  Sure, explicit casts can be
annoying, but they are also easy to remember and understand what is
going on.
