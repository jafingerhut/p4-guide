# Introduction

The program `demo1.p4_16.p4` in this directory is identical to the one
in the `demo1` directory, except table `ipv4_da_lpm` has a key that is
a bit slice, as shown in the exerpt below:

```
    table ipv4_da_lpm {
        key = {
            // In demo1 directory, there is no [23:8] bit slice
            hdr.ipv4.dstAddr[23:8]: lpm;
        }
        // rest of table definition is omitted
    }
```

On a system with open source `p4c`, `simple_switch_grpc`, and `ptf`
installed, the following commands will run a few simple automated
tests that use P4Runtime API from Python to add table entries to this
table, and send packets through that match them.

```
sudo ../bin/veth_setup.sh
./runptf.sh
```

In the compiler-generated file `demo1.p4_16.p4info.txtpb` checked into
this directory, you can see that the name of the match field for table
`ipv4_da_lpm` is `hdr.ipv4.dstAddr[23:8]`, and that name is also used
in the PTF test `ptf/demo1.py` to find the information about this
match field.

The P4Runtime controller must install entries into this table as if
the match field is exactly 16 bits long, i.e. the width of the
expression that is the result of `hdr.ipv4.dstAddr[23:8]`.

The search key in the data plane when the table `ipv4_da_lpm` is
`apply`ed is also 16 bits long.  This can be observed by examining the
`simple_switch_grpc` log file recorded in file `ss-log.txt` produced
as a result of running the commands shown above.

In all ways except for the name of the match field, the behavior is
exactly as if the table `ipv4_da_lpm` had a key defined as the
expression `foo`, where `foo` was declared as type `bit<16>` and the
assignment `foo = hdr.ipv4.dstAddr[23:8];` occurred before
`ipv4_da_lpm.apply();` was done.
