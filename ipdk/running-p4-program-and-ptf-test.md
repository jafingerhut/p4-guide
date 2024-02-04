# Running a P4 program and testing it using a PTF test

(Verified this section is updated and working on 2024-Feb-03)

Prerequisites:

+ You have started the container, and followed the steps described in
  the section [Useful extra software to install in the
  container](general-ipdk-notes.mdgeneral-ipdk-notes.md#useful-extra-software-to-install-in-the-container).
+ You have a P4 source program that compiles successfully following
  the steps below.
  + If you want to test these steps on your system with a known-good
    example P4 program and PTF test, use the files in the directory
    `sample`.
+ You have written a PTF test in Python that you want to test it with.
  + TODO: Some time write details of how such a test should be
    written, e.g. what ports exist?

I will use example file names `sample.p4` for the P4 program, and
`ptf-test1.py` for the Python PTF test.  These steps will work even if
the P4 source code is spread over many files, but it is assumed here
(so far) that the Python source code for the PTF test is in a single
file.

These instructions use `p4c-dpdk` installed in the base OS for
compiling your P4 program.  I know how to update the `p4c-dpdk`
version in the base OS to the latest version, compiled from source
code, but I do not know how to do so for the version of `p4c-dpdk`
that is installed in the container.  This makes it easier to update to
a later version of `p4c-dpdk`, e.g. when issues in it are fixed.  Only
the output files from the compiler will be copied into the container
where the P4 DPDK data plane will execute it.


## Compiling the P4 program

In base OS:
```bash
BASENAME="sample"
DIR="sample"
cd ${DIR}
../bin/compile-base-os.sh -a pna -s ${BASENAME}.p4
```


## Copying the necessary files into the container

In base OS:
```bash
mkdir -p ~/.ipdk/volume/${BASENAME}
cp -pr ${DIR}/* ~/.ipdk/volume/${BASENAME}
```

If `runptf.sh` and the Python PTF source code files are not in
directory `${DIR}`, copy them into `~/ipdk/volume/${BASENAME}`, too.


## Running the P4 program with the PTF test

This only needs to be run in the container once:
```bash
source $HOME/my-venv/bin/activate
```

In container:
```bash
BASENAME="sample"
cd /tmp/${BASENAME}/out
/tmp/bin/tdi_pipeline_builder.sh -p . -s ${BASENAME}.p4
/tmp/bin/setup_tapports_in_default_ns.sh -n 8
/tmp/bin/load_p4_prog.sh -p ${BASENAME}.pb.bin -i ${BASENAME}.p4Info.txt
cd ..
./runptf.sh
```


## Copying output files recorded during the PTF test run back to the base OS

See these files in the directory `~/.ipdk/volume/${BASENAME}`:

+ `ptf.pcap`
+ `ptf.log`

The file `ptf.pcap` should contain a mix of all packets on all ports,
in time order.  Each should have a "PPI" header, which contains fields
like the ones shown below.  You can see the port number that the
packet was sent or received on in the first "Interface ID" field.  I
do not know why there are two "Aggregation Extension" and two
"Interface ID" fields, but from my experience it seems that the first
one is the one you should pay attention to.

```
PPI version 0, 24 bytes
    Version: 0
    Flags: 0x00
        .... ...0 = Alignment: Not aligned
        0000 000. = Reserved: 0x00
    Header length: 24
    DLT: 1
    Aggregation Extension
        Field type: Aggregation Extension (8)
        Field length: 4
        Interface ID: 1
    Aggregation Extension
        Field type: Aggregation Extension (8)
        Field length: 4
        Interface ID: 0
```
