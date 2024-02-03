# Attempt to compile and load DASH P4 program into DPDK

Note: This article has not been updated since mid-2023.  There have
been some issues in P4 DPDK fixed since it was written, including
issue #3928 linked below, but there are other issues that remain that
prevent DASH P4 code from running successfully on it.

See the issues labeled "dash-blockers" in the p4c issue tracker here:
https://github.com/p4lang/p4c/issues?q=is%3Aopen+is%3Aissue+label%3Adash-blocker



In the base OS:
```bash
cp -pr ~/p4-guide/ipdk/dash/ ~/.ipdk/volume/
```

In the container:
```bash
cd /tmp/dash
./compile-alternate.sh
```

TODO: As of 2023-Mar-15, the compilation step above fails.  Below is
an example of the error message that occurs:

```bash
terminate called after throwing an instance of 'Util::CompilerBug'
  what():  In file: /root/P4C/backends/dpdk/dpdkContext.cpp:221
Compiler Bug: unable to find id for dash_ingress.outbound_ConntrackOut_conntrackOut
```

There appears to be a bug in how p4c-dpdk attempts to generate the
output file `context.json`.  See this issue for when it is resolved:

+ https://github.com/p4lang/p4c/issues/3928

Until that bug is fixed, as a workaround I have included the compiler
output files in my p4-guide git repo, including the
`dash_pipeline.pb.bin` file, which I created with this command:

```bash
pushd /tmp/dash
/tmp/tdi_pipeline_builder.sh -p /tmp/dash -s dash_pipeline.p4
```

Now start the DPDK software switch and load the compiled DASH P4
program into it:

```bash
/tmp/setup_tapports_in_default_ns.sh -n 2
/tmp/load_p4_prog.sh -p /tmp/dash/out/dash_pipeline.pb.bin -i /tmp/dash/out/dash.p4Info.txt
```

As of 2023-Mar-23, every time I try to load this DPDK binary in this
way, I see this error message:

```bash
Error: P4Runtime RPC error (INTERNAL): 'bf_pal_device_add(dev_id, &device_profile)' failed with error message: Unexpected error. 
```

I am checking with DPDK developers to see why this occurs, and if
there is a way to prevent it.
