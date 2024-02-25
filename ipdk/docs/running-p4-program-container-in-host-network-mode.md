# Introduction

Most of the other instructions that I have written for running P4 DPDK
start the IPDK networking container in bridge network mode.  In this
mode, the container has its own network configuration that is separate
from the network configuration in the base OS.  For example, creating
TAP interfaces in the IPDK container makes those interface visible in
the output of an `ip link show` command that is run inside of the
container, but they do not show up in the output of `ip link show` run
in the base OS.  This is useful when you want to do networking
configurations inside of the container with no effect upon the base
OS.

In this article, we instead start the IPDK container in host network
mode.  In this mode, the container uses the base OS network
configuration.  Network interfaces created or modified in the base OS
are visible in the IPDK container, and vice versa.  This is useful if
you want to send packets to P4 DPDK, or receive packets from P4 DPDK,
from a program running in the base OS, e.g. a PTF test running in the
base OS.


# Prerequisites

You have installed the IPDK networking container as described
[here](README-install-ipdk-networking-container-ubuntu-20.04-and-test.md).

You _do not_ need to install any extra software inside of the
container, as is required for many of the other articles here.  It is
harmless if you have done so.

You need a slightly modified version of the `ipdk` command installed
in your base OS, which can be installed with these commands:

```bash
cd /tmp
curl -O -L https://raw.githubusercontent.com/jafingerhut/ipdk/add-host-network-option/build/scripts/ipdk.sh
chmod 755 ipdk.sh
/bin/cp -p ipdk.sh `which ipdk`
```


# Starting the container

You must do these steps in the base OS in every terminal you create:

```bash
export P4GUIDE="${HOME}/p4-guide"
export PYPKG_TESTLIB="${P4GUIDE}/testlib"
export IPDK_HOME="${HOME}/ipdk"
export PATH="${P4GUIDE}/ipdk/bin:${PATH}"
```

These steps are the same as for other ways of starting the IPDK
container, except that we add a new option `--host-network` to the
`ipdk start` command.  In base OS:

```bash
cd ${IPDK_HOME}
ipdk start -d --host-network
ipdk connect
```

Leave that terminal with its prompt in the container where it is, and
start a new terminal in the base OS for the commands below.

We will be describing an approach here where the P4Runtime API server
that is within the `infrap4d` process run within the container allows
unauthenticated, unencrypted connections from P4Runtime client
programs.  While this is not recommended in production use, it is fine
when simply testing on a single machine, and avoids the hassle of
ensuring that every client must have a copy of the cryptographic
credential files.

The Bash and Python programs I have written check whether the
necessary credential files exist in the directory
`/usr/share/stratum/certs`.  If the necessary files exist, they are
used to attempt to make a secure gRPC connection to the P4Runtime
server.  If they do not exist, the program automatically falls back to
making an insecure gRPC connection.

Because the `ipdk connect` command above creates new credential files
in `/usr/share/stratum/certs` inside of the container, one of the
first steps below will remove those files.

This only needs to be run once, in the base OS, for each time an IPDK
container is started:
```bash
/bin/cp -pr ${P4GUIDE}/ipdk/bin ~/.ipdk/volume
setup-for-insecure-grpc-connections-base-os.sh
```

These are example commands that you can try for compiling, loading,
and running a PTF test for the P4 program `sample.p4` included in this
repo:

```bash
BASENAME="sample"
/bin/cp -pr ${P4GUIDE}/ipdk/${BASENAME} ~/.ipdk/volume
cd ~/.ipdk/volume/${BASENAME}
compile-base-os.sh -a pna -s ${BASENAME}.p4
start-infrap4d-and-load-p4-base-os.sh ${BASENAME} ${BASENAME}
```

To run the PTF test from the base OS:
```bash
with-ptf-env ./runptf.sh
```
