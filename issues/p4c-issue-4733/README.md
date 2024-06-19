# p4c issue #4733

This directory is intended to do some simple exploration via
experimentation to attempt to answer questions raised by this issue:

+ https://github.com/p4lang/p4c/issues/4733

I took the code from that issue and made a modified version of my
`demo1.p4_16.p4` program that runs on the BMv2 v1model architecture,
so that I could pass packets through it to test it.  The resulting
program is in the file `issue4733-bmv2.p4`.

Compile it for BMv2, and also create the P4_16 programs that should be
equivalent to the input P4 program in the directory `tmp`:

```bash
mkdir -p tmp
p4c-bm2-ss --target bmv2 --arch v1model --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast --p4runtime-files issue4733-bmv2.p4.p4info.txtpb,issue4733-bmv2.p4.p4info.json issue4733-bmv2.p4
```

Look at this file in the `tmp` directory to see what the BMv2 back end
produced, just before converting to BMv2 JSON:

+ `issue4733-bmv2-0003-BMV2::SimpleSwitchMidEnd_44_MidEndLast.p4`

Use `p4testgen` to generate PTF tests for this program that run on
BMv2:

```bash
p4testgen --target bmv2 --arch v1model --max-tests 10 --out-dir out-p4testgen --test-backend ptf issue4733-bmv2.p4
```

You can see the test cases in the output file
`out-p4testgen/issue4733-bmv2.py`.  They can be a little bit tedious
to read, but the comments in each test case provide very detailed
walk-throughs of which sequence of cases they follow through the P4
program that they _should_ exercise.

To run these tests with BMv2:

```
../../bin/veth_setup.sh
./p4testgen-runptf.sh
```
