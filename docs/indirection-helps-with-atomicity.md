# Building "effectively atomic" updates from non-atomic updates

Sandesh Kumar Sodhi and Surya Nimmagadda describe a scenario in a
short document titled "Dataplane-atomic flag in Write batch: Use case
for TRIO", added to this [P4-API Google
doc](https://docs.google.com/document/d/16gvs3Y196ptz38ujEc9tCGMSm_Elv2I5WdrtEUU3jd0).

There it is claimed that that this scenario demonstrates a case where
a certain kind of dataplane _requires_ a dataplane-atomic batch update
message in the P4 Runtime API, in order to make a certain kind of
update atomic in the dataplane.

In the scenario, a programmable dataplane device named TRIO has a
single table containing two table entries.  One entry causes some
packets to be directed to a device called PIC1.  Another entry causes
other packets to be directed to a device called PIC2.

The scenario does not say exactly what criteria are used to choose
which packets go to PIC1 vs. those which go to PIC2, but for the sake
of writing a specific P4 program to represent this scenario, I will
imagine that the key of that table is a hash function calculated from
the contents of the packet, stored in "meta.hash1".  See the partial
P4 program in control "ingress_1_table" below (written using the
syntax of the P4_16 dialect of P4).

```
control ingress_1_table {
    action set_pic (bit<8> pic_id) {
        meta.pic_id = pic_id;
    }
    table choose_pic {
        key = {
             meta.hash1 : ternary;
        }
        actions = { set_pic; }
    }
    apply {
        // Code here that calculates a value for meta.hash1

        // Using meta.hash1, select a target PIC
        choose_pic.apply();

        // Code here that uses meta.pic_id to send the packet to
        // that PIC
    }
}
```

The scenario describes a current state of the device containing these
table entries:

```
Original entries in table choose_pic:
meta.hash1=K1 -> set_pic with pic_id=1
meta.hash1=K2 -> set_pic with pic_id=2
```

In the scenario, we want to change from the current state to a new
state, where in the new state all packets matching K1 go to pic_id 2
instead of 1, and all packets matching K2 to go to pic_id 1 instead of
2.  That is:

```
New desired entries in table choose_pic:
meta.hash1=K1 -> set_pic with pic_id=2
meta.hash1=K2 -> set_pic with pic_id=1
```

In that document, the following claim is made: "No sequence of
NON-dataplane-atomic updates will be able to achieve the minimum
packet loss numbers that dataplane-atomic write batch update will be
able to achieve."

I agree that without a dataplane-atomic write batch request, the
example scenario could not be done in an atomic way _with only a
single P4 table in the TRIO device_.

However, if the TRIO device is fully P4 programmable, there is no
fundamental reason why it should be restricted to contain only a
single P4 table.  By adding only one more small table, it becomes
straightforward to achieve the desired atomic update, _without using a
P4 Runtime API batch write request that has the dataplane-atomic
option_.  The atomic update can be done, using only write batch
requests without that option.

Consider the slightly modified partial P4 program in control
"ingress_2_tables" below.

```
control ingress_2_tables {
    // Table assign_color is new in this example.  There is
    // nothing corresponding to it in control ingress_1_table.
    action set_color (bit<1> color) {
        meta.color = color;
    }
    table assign_color {
        actions = { set_color; }
    }
    
    // Table choose_pic is the same as that in control
    // ingress_1_table, except that it has an additional field
    // "meta.color" in the key.
    action set_pic (bit<8> pic_id) {
        meta.pic_id = pic_id;
    }
    table choose_pic {
        key = {
             meta.color : exact;     // new field
             meta.hash1 : ternary;
        }
        actions = { set_pic; }
    }

    apply {
        // Code here that calculates a value for meta.hash1

        // Assign a value of meta.color to all packets
        assign_color.apply();
        
        // Using meta.color and meta.hash1, select a target PIC
        choose_pic.apply();

        // Code here that uses meta.pic_id to send the packet to
        // that PIC
    }
}
```

The controller installs the following original table entries:

```
assign_color entry:
set_color with color=0

choose_pic entries:
meta.color=0, meta.hash1=K1 -> set_pic with pic_id=1
meta.color=0, meta.hash1=K2 -> set_pic with pic_id=2
```

To make the update, the controller will send 3 batch write messages,
all of which perform non-atomic updates in the device.

The first write message is:

```
add entry to choose_pic with meta.color=1, meta.hash1=K1 -> set_pic with pic_id=2
add entry to choose_pic with meta.color=1, meta.hash1=K2 -> set_pic with pic_id=1
```

If that write batch succeeds, the contents of the ASIC table entries
are now:

```
assign_color entry:
set_color with color=0

choose_pic entries:
meta.color=0, meta.hash1=K1 -> set_pic with pic_id=1
meta.color=0, meta.hash1=K2 -> set_pic with pic_id=2
meta.color=1, meta.hash1=K1 -> set_pic with pic_id=2
meta.color=1, meta.hash1=K2 -> set_pic with pic_id=1
```

Note that it is impossible for any data packets flowing through to
match these new added entries, so the order they are added does not
matter, and it does not matter if an arbitrary number of packets are
processed after the first of the new entries is added, and before the
second is added.

The second write message is:

```
modify entry in assign_color to: set_color with color=1
```

If that write batch succeeds, the contents of the ASIC table entries
are now:

```
assign_color entry:
set_color with color=1

choose_pic entries:
meta.color=0, meta.hash1=K1 -> set_pic with pic_id=1
meta.color=0, meta.hash1=K2 -> set_pic with pic_id=2
meta.color=1, meta.hash1=K1 -> set_pic with pic_id=2
meta.color=1, meta.hash1=K2 -> set_pic with pic_id=1
```

This write only modified a single table entry, which by the rules of
the PSA must be atomic relative the data packet processing.  Thus
every packet is either assigned meta.color=0, before the update to
table assign_color, or it is assigned meta.color=1, after the update.

Now no packet can match any of the original choose_pic entries that
have a key matching meta.color=0.  The controller can now remove them,
in an arbitrary order, without needing a dataplane-atomic batch.

The third write message is:

```
remove entry from choose_pic with meta.color=0, meta.hash1=K1
remove entry from choose_pic with meta.color=0, meta.hash1=K2
```

If that write batch succeeds, the contents of the ASIC table entries
are now:

```
assign_color entry:
set_color with color=1

choose_pic entries:
meta.color=1, meta.hash1=K1 -> set_pic with pic_id=2
meta.color=1, meta.hash1=K2 -> set_pic with pic_id=1
```


## Generalizations

This same idea can work with a field like "meta.color" with multiple
bits.  There is no reason why it must be restricted to only 1 bit.
The table assigning a value to a multi-bit field like "meta.color"
could do so for a subset of the arriving packets, rather than all of
them.  See slides 12 through 14 of
[Thoughts on batch operations](https://github.com/jafingerhut/p4-guide/blob/master/docs/p4runtime%20api%20batch%20operations.pptx)
for an example of this, where the field is called "acl_id" instead of
"meta.color".

This technique can be used for the entire data plane P4 program,
spanning with an arbitrary number of tables, or for only one as shown
above.  Using a single such field for all tables is potentially
expensive in table space required, and control plane updates required,
but it is very general in the kinds of updates that can be made in an
effectively atomic way.  It was described on slide 9 of
[Thoughts on batch operations](https://github.com/jafingerhut/p4-guide/blob/master/docs/p4runtime%20api%20batch%20operations.pptx),
send to the p4-api group email list on Feb 22 2018.  I am not the
originator of the idea, and suspect it is very old.  Something like it
was probably proposed as a way to implement transactions in software
databases decades ago.

There can also be multiple fields like "meta.color", each one used to
control access to a subset of tables in a programmable device.  Such
things have been in use in non-programmable ASICs for decades.

It can also be generalized to have more than one "set" of entries in
table choose_pic that are in active use by different packets, as
opposed to the example above where either only the entries with
meta.color=0 are in use, or only the entries with meta.color=1 are in
use.  This generalization is used in the
[SilkRoad paper](https://eastzone.bitbucket.io/paper/sigcomm17-silkroad.pdf),
for example.  The critical factor is that there is at least one value
for this field that is not currently in use, in order to add new table
entries that no data packets currently flowing through the system can
match.

It can be generalized to an entire network of devices.  See:

"Abstractions for Network Update", M. Reitblatt, N. Foster,
J. Rexford, C. Schlesinger, D. Walker, SIGCOMM 2012

Note that the technique can achieve a number of updates required in
the data plane that is at most 2 times the number of updates required
if the technique is not used.  This can be done by starting with the
"red" and "blue" sets of rules equal to each other.

If it takes K table updates to change the red set from the current
state to the desired next state, then if that is successful, after we
switch from the blue to the red set, do the corresponding K table
updates to the blue set to make them equal to the red set.  Over an
arbitrary sequence of updates, we will do twice as many table updates
as would be required if there were only one set of rules.
