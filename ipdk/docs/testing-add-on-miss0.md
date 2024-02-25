# Running P4 program `add_on_miss0.p4` and testing it from a PTF test

(Verified this section is updated and working on 2024-Feb-03)

Prerequisites: You have started the container, and followed the steps
described in the section [Useful extra software to install in the
container](general-ipdk-notes.md#useful-extra-software-to-install-in-the-container).

Here we give steps for running a PTF test with program
`add_on_miss0.p4` loaded.

Note: The only way I have successfully installed and run the PTF
package in the container so far is in a Python virtual environment.
If someone finds a way to successfully run a PTF test without creating
a virtual environment, I would not mind knowing how.

Also note that these instructions use the script
`setup_tapports_in_default_ns.sh`, not `setup_2tapports.sh` as some
other examples have done.  This makes it easier for the PTF test to
send packets on the TAP ports and check output packets on the TAP
ports, because those TAP interfaces are in the same network namespace
where the PTF process is running.

In base OS:
```bash
cp -pr ~/p4-guide/ipdk/add_on_miss0/ ~/.ipdk/volume/
```

This only needs to be run in the container once:
```bash
source $HOME/my-venv/bin/activate
export PYPKG_TESTLIB="/tmp/testlib"
```

In the container:
```bash
BASENAME="add_on_miss0"
cd /tmp/${BASENAME}
/tmp/bin/compile-in-cont.sh -p . -s ${BASENAME}.p4 -a pna
cd /tmp/${BASENAME}/out
/tmp/bin/start-infrap4d-and-load-p4-in-cont.sh ${BASENAME} ${BASENAME}
cd /tmp/${BASENAME}/ptf-tests
./runptf.sh
```

Note: The DPDK software switch will fail to load a P4 program unless
it currently has a number of ports that is a power of 2.  The
`setup_tapports_in_default_ns.sh` script should check this restriction
and give an explanatory error message if you try to violate this
restriction.
