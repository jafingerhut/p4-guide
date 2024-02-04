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
`setup_tapports_in_default_ns.sh`, not `setup_2tapports.sh` as
previous examples above have done.  This makes it easier for the PTF
test to send packets on the TAP ports and check output packets on the
TAP ports, because those TAP interfaces are in the same network
namespace where the PTF process is running.

In base OS:
```bash
cp -pr ~/p4-guide/ipdk/add_on_miss0/ ~/.ipdk/volume/
```

This only needs to be run in the container once:
```bash
source $HOME/my-venv/bin/activate
```

In the container:
```bash
cd /tmp/add_on_miss0
/tmp/bin/compile-in-cont.sh -p . -s add_on_miss0.p4 -a pna
cd /tmp/add_on_miss0/out
/tmp/bin/tdi_pipeline_builder.sh -p . -s add_on_miss0.p4
/tmp/bin/setup_tapports_in_default_ns.sh -n 8
/tmp/bin/load_p4_prog.sh -p add_on_miss0.pb.bin -i add_on_miss0.p4Info.txt
cd /tmp/add_on_miss0/ptf-tests
./runptf.sh
```

Note: The DPDK software switch will fail to load a P4 program unless
it currently has a number of ports that is a power of 2.  The
`setup_tapports_in_default_ns.sh` script should check this restriction
and give an explanatory error message if you try to violate this
restriction.
