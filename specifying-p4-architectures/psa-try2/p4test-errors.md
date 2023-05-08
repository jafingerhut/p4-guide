I have made many changes from an older version of psa-try1.p4 so that
its current version almost compiles with the open source `p4test`
program, using this version:

```bash
$ p4test --version
p4test
Version 1.2.3.9 (SHA: bee193967 BUILD: DEBUG)
```

That corresponds to p4c source code as of this commit:

```
commit bee193967522b2bd835a1792571977897eed0c38 (HEAD -> main, origin/main, origin/HEAD)
Author: Han Wang <han2.wang@intel.com>
Date:   Sat May 6 22:43:51 2023 +1200

    Allowing local_copyprop to propagate MethodCallExpression into table … (#4003)
    
    * Allowing local_copyprop to propagate MethodCallExpression into table key.
    * do not propagate union.isValid() to table key
```

The errors with psa-try2.p4 with that version of p4test that remain are:

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

There are several #ifdef's in psa-try2.p4 that effectively comment out
some lines of code that cause more errors for p4test, for the
following reasons:

+ ARRAY_OF_QUEUES_SUPPORTED - The definition of tmq is a
  two-dimensional array of Queue extern instances, which P4-16 does
  not support.
  + I work around this temporarily by putting all packets into a
    single tmq, but to me that seems like a strange restriction on
    writing specifications of traffic managers, overly limiting the
    possible orders that packets can be transmitted out of the device.
+ P4C_SUPPORTS_LONGER_BIT_VECTORS - p4test gives an error if one
  attempts to declare a type `bit<W>` with W > 2048.
+ PROCESS_SUPPORTED - P4-16 does not define a `process` construct as
  used in psa-try2.p4, because I made it up.
