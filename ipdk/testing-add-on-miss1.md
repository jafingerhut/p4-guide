# Running P4 program `add_on_miss1.p4` and testing it from a PTF test

(Verified this section is updated and working on 2024-Feb-03)

Prerequisites: You have started the container, and followed the steps
described in the section [Useful extra software to install in the
container](general-ipdk-notes.md#useful-extra-software-to-install-in-the-container).

P4 program `add_on_miss1.p4` has different logic for deciding whether
to add an entry to table `ct_tcp_table`.  It also uses the extern
function `set_entry_expire_time` in the hit action for `ct_tcp_table`
to set the expire time of an entry when a packet matches an existing
entry, depending upon the TCP flags of the packet, which has the
additional side effect of restarting the expire timer of the entry.
Thus data packets continuing to match the entry will keep it from
being deleted, unlike `add_on_miss0.p4`.

In the base OS:
```bash
cp -pr ~/p4-guide/ipdk/add_on_miss1/ ~/.ipdk/volume/
```

This only needs to be run in the container once:
```bash
source $HOME/my-venv/bin/activate
```

In the container:
```bash
cd /tmp/add_on_miss1
/tmp/bin/compile-in-cont.sh -p . -s add_on_miss1.p4 -a pna
cd /tmp/add_on_miss1/out
/tmp/bin/tdi_pipeline_builder.sh -p . -s add_on_miss1.p4
/tmp/bin/setup_tapports_in_default_ns.sh -n 8
/tmp/bin/load_p4_prog.sh -p add_on_miss1.pb.bin -i add_on_miss1.p4Info.txt
cd /tmp/add_on_miss1/ptf-tests
./runptf.sh
```
