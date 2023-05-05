I have made many changes from an older version of psa-try1.p4 so that
its current version almost compiles with the open source `p4test`
program, using this version:

```bash
$ p4test --version
p4test
Version 1.2.3.5 (SHA: 1f34073a3 BUILD: DEBUG)
```

That corresponds to p4c source code as of this commit:

```
commit 1f34073a3245b8a37dbfe377f8477e25adadffd8 (HEAD -> main, origin/main, origin/HEAD)
Author: Fabian Ruffy <5960321+fruffy@users.noreply.github.com>
Date:   Thu Jan 26 10:38:16 2023 -0500

    Fix flawed code in up4.p4 and the pins switch models. (#3857)
```

The errors with psa-try1.p4 with that version of p4test that remain are:

+ p4test does not support declaring variables of type `packet_in` or
  `packet_out`.  I am guessing it would if the extern definitions for
  `packet_in` and `packet_out` in core.p4 had constructor methods
  defined for those externs, but it does not.  I believe that core.p4
  does not declare such constructor methods by design, in order to
  prevent people from declaring variables of these types in P4
  programs.
  + Supporting evidence: The P4-16 language spec says in Section 13.8
    "Data Extraction" the following "The packet_in extern is special:
    it cannot be instantiated by the user explicitly."
  + I cannot think of any straightforward way to write a P4-16
    architecture specification without being able to create objects of
    type packet_in and packet_out.
+ p4test does not support declaring structs with members that are
  extern types.

There are several #ifdef's in psa-try1.p4 that effectively comment out
many lines of code that cause more errors for p4test, for the
following reasons:

+ ARRAY_OF_QUEUES_SUPPORTED - The definition of tmq is a
  two-dimensional array of Queue extern instances, which P4-16 does
  not support.
  + We could work around this temporarily by putting all packets into
    a single tmq, but to me that seems like a strange restriction on
    writing specifications of traffic managers, overly limiting the
    possible orders that packets can be transmitted out of the device.
+ EXTERN_CAN_USE_SELF_TYPE_IN_DEFINITIONS - p4test gives an error if
  you try to define an extern object where a method takes a parameter
  whose type is the same extern type that is currently being defined.
+ EXTERN_SUPPORTED_IN_STRUCT - p4test gives an error if you try to
  declare a struct type with a member that is an extern object type.
  It is not explicitly stated in the P4-16 language spec whether this
  is supported or not, but it makes sense if the answer is "no, it is
  not supported".
  + The only extern that psa-try1.p4 currently uses as members of a
    struct are instances of my made-up `packet` extern.  We could
    replace the `packet` extern with a struct type containing a
    maximum-packet-length bit vector and a packet length field, which
    would work around this restriction.
+ FOR_LOOP_SUPPORTED - There is no for loop construct in P4-16.
  + This is currently only used for packet replication for multicast
    groups and clone sessions.  I have a way to avoid the need of a
    for loop, by creating a process that only creates one copy of a
    packet each time the process is executed, then puts the packet in
    a queue that feeds back into the same process until that process
    exhausts all copies required, in case that idea is useful to
    anyone.
+ LIST_SUPPORTED_INSIDE_STRUCT - p4test gives an error if you try to
  declare a struct type with a member with type `list`.  The latest
  P4-16 language spec explicitly disallows this.
  + This is currently only used for multicast and clone session
    replication lists, which I know a way to work around as mentioned
    above, but long term it does seem very convenient if struct
    members could have type list.
+ PROCESS_SUPPORTED - P4-16 does not define a `process` construct as
  used in psa-try1.p4, because I made it up.
