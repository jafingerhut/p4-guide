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
export PYPKG_TESTLIB="/tmp/testlib"
```

In the container:
```bash
BASENAME="add_on_miss1"
cd /tmp/${BASENAME}
/tmp/bin/compile-in-cont.sh -p . -s ${BASENAME}.p4 -a pna
cd /tmp/${BASENAME}/out
/tmp/bin/start-infrap4d-and-load-p4-in-cont.sh ${BASENAME} ${BASENAME}
cd /tmp/${BASENAME}/ptf-tests
./runptf.sh
```
