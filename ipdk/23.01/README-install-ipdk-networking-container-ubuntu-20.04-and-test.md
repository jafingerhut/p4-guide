# Introduction

These instructions are one specific, tested way to install IPDK using
its networking container instructions on an Ubuntu 20.04 Linux system.
The IPDK instructions and build scripts come from this repository:

+ https://github.com/ipdk-io/ipdk

The `infrap4d` program compiled and installed using the steps below is
a combination of at least the following parts:

+ The DPDK data plane, or software switch.  You may compile P4
  programs and load the binaries into it to execute them.
+ A P4Runtime API server, by default listening on TCP port 9559 for
  incoming connection requests from P4Runtime API clients
  (i.e. controller programs).
+ A gNMI server

Source: The figure on this page shows the above parts, and also some
other software components included within the `infrap4d` process:

+ https://ipdk.io/p4cp-userguide/overview/overview.html#infrap4d


# Installing IPDK using the networking docker build steps

The Ubuntu 20.04 Linux system that I have tried these steps with was
an x86_64 architecture CPU with 8 GB of RAM, and a little over 40
GBytes of free disk space.  It had 4 virtual CPU cores, and at its
most consumed a little bit under 9 GBytes of disk space out of
whatever free space existed when starting.

Aside: I did try once on 2024-Jan-15 to follow these steps on an
Ubuntu 20.04 system running on an aarch64 (aka arm64) CPU, but it
failed.  I believe the root cause is that some executable programs are
downloaded at some step, and they were not aarch64 executables,
probably x86_64.

Note: If you try to build on a system with more than 4 virtual CPU
cores, the build scripts may try to run more compilations in parallel,
and thus may require more than 8 GB of RAM to succeed, failing if you
do not have enough RAM to run all of those processes simultaneously.

My success occurred while running in a VM created using VirtualBox on
an x86_64 macOS host system, but hopefully that part should be
irrelevant for others following these steps.

Start logged in as a non-root user `$USER`.

To install docker:

```bash
cd $HOME
git clone https://github.com/jafingerhut/p4-guide
~/p4-guide/bin/install-docker.sh
```

As recommended in the output, reboot your system.  After that, you
should be able to run docker commands such as `docker run hello-world`
in any terminal window you create without having to prefix them with
`sudo`.

The following steps for installing IPDK are inspired by those given on
this page:
https://github.com/ipdk-io/ipdk/blob/main/build/networking/README_DOCKER.md

If you already have one of these directories in your command PATH
before starting the steps below, the `./ipdk install` command will add
a new symbolic link named `ipdk` to it, and the `export` command below
is unnecessary.

+ `$HOME/.local/bin`
+ `$HOME/bin`

If you do not already have one of those directories in your command
PATH, then no symbolic link `ipdk` will be created, and you should
ensure that the command `export PATH=$HOME/ipdk/build:$PATH` is
executed every time you start a new shell where you wish to run the
`ipdk` command in the future.

I was not behind a proxy, so I did not attempt to do any of the proxy
configuration steps described in the IPDK repo instructions.  See
there if you are behind a proxy.

All of the commands immediately below except the one beginning `ipdk
build` should complete very quickly.  The `ipdk build` command took 33
mins on a 2019-era MacBook Pro with a 1 Gbps Internet connection, but
almost 80 minutes on the same laptop with a download speed ranging
between 1.5 to 2 MBytes per second.

```bash
cd $HOME
git clone https://github.com/ipdk-io/ipdk.git
cd ipdk/build
./ipdk install
export PATH=$HOME/ipdk/build:$PATH
cd ..
ipdk install ubuntu2004    # if base OS is Ubuntu
ipdk install fedora33      # if base OS is Fedora
ipdk build --no-cache |& tee $HOME/log-ipdk-build.txt
```

At this point, you should see that a new docker image has been created
with the name `ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64`, as shown in
the sample command output below:

```bash
$ docker images -a
REPOSITORY                               TAG           IMAGE ID       CREATED         SIZE
ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64   sha-c38906d   8de06103d9f3   27 hours ago    1.69GB
hello-world                              latest        feb5d9fea6a5   16 months ago   13.3kB
```

The creation of the container is now complete.  All later instructions
are for starting instances of this container, installing some
additional software packages in the container, and running the DPDK
software switch inside of it.


# Running commands in the base OS vs. running commands in the container

Every time the instructions say to run a command "in the base OS",
that means you should have some command shell that is running in the
base Ubuntu 20.04 operating system.  You should _not_ have run `ipdk
connect` or `docker exec it ...` in this shell.

Every time the instructions say to run a command "in the container",
that means you should have some shell at a prompt reached by running
the `ipdk connect` or `docker exec it ...` command below.

The file system contents (and thus which software packages are
available for use), the Linux networking namespaces, and probably many
other things, are different when running commands in the base OS
vs. running commands in the container.

You will likely find it convenient to have at least two command shell
windows open at the same time, one at a prompt in the base OS, and the
other at a prompt in the container.

Note: Every time you run `ipdk connect`, a script run in the container
creates new cryptographic authentication keys for the `infrap4d`
server in the directory `/usr/share/stratum/certs` (or perhaps
`/var/stratum/certs` in older versions of IPDK).  You want this to
happen once per container process that you start.  One way to achieve
this is to only do `ipdk connect` exactly once each time you run `ipdk
start`.  If you then want additional terminals to be at a shell prompt
within that same container process, you can use the following command
instead of `ipdk connect`:

```bash
docker exec -it -w /root 8e0d6ad594af /bin/bash
```

Replace `8e0d6ad594af` with the value in the `CONTAINER ID` column in
the output of `docker ps`, for the container with IMAGE name like
`ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:<something>`.


# Sharing files between the base OS and container

The following two directories are different 'views' of one underlying
directory:

+ In the base OS: `$HOME/.ipdk/volume`
+ In the container: `/tmp`

Thus, in the base OS, if you copy files to the directory
`$HOME/.ipdk/volume`, they will be visible in directory `/tmp` in the
container, and vice versa.


# Useful extra software to install in the base OS

If you like using Wireshark, or the tshark variant of that program, in the base OS for viewing the contents of pcap files that contain packets recorded during a test run, you can install it as follows.

In the base OS:
```bash
sudo apt-get install --yes tshark wireshark
```


# Useful extra software to install in the container

Every time the container is started on a system, via some variant of
the `ipdk start` command, its file system is in the same initial state
as every other time it is started.

Commands like `git`, `tcpdump`, and `tcpreplay` are not installed in
the container when it is first built.  Thus every time you start
another instance of the container, those commands will not be
available.

A simple bash script is included in this repository that will install
those commands, and a few other useful software packages, in the
container.

In the base OS:
```bash
cp -pr ~/p4-guide/ipdk/23.01/*.sh ~/p4-guide/pylib ~/.ipdk/volume/
```

In the container:
```bash
/tmp/install-ipdk-container-extra-pkgs.sh
```


# Notes on running `ipdk` commands

There is an `ipdk start` command to start an instance of the
container, an `ipdk connect` command that gets you to a bash prompt
running in of the container, and several other `ipdk` sub-commands
that are useful for various purposes.

If you run one of these commands, and you see an error message like
`fatal: not a git repository` followed later by `Unable to find image
'<some-name>' locally`, as shown in the example output below:

```
$ ipdk start -d
fatal: not a git repository (or any of the parent directories): .git
Loaded /home/andy/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
Can't find update-binfmts.
Using docker run!
Unable to find image 'ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:sha-none' locally
docker: Error response from daemon: manifest unknown.
See 'docker run --help'.
```

This is most likely because you are trying to run the command when the
current directory is not one that is inside of your cloned copy of the
`ipdk` repository.  To avoid this error, simply `cd $HOME/ipdk` and
try the command again.

Note: The docker image name is created containing a string of hex
digits at the end.  This hex string is part of the commit SHA of the
ipdk git repository at the time the docker image was created, so if
that changes because you updated your clone of the `ipdk` repo, you
may need to rebuild the docker image.


# What to try next?

If you have never installed IPDK before, and want to try out a fully
bash-scripted sequence of steps, go to [A quick test of the IPDK
installation](#a-quick-test-of-the-ipdk-installation).

To try compiling a P4 program using `p4c-dpdk` installed in the base
OS (not the one inside the container), and copy the fewest number of
files between the base OS and container while iteratively modifying
and testing your P4 program and PTF test, go to [Running a P4 program
and testing it using a PTF
test](#running-a-p4-program-and-testing-it-using-a-ptf-test).




# A quick test of the IPDK installation

You may skip this section.  It is NOT required for installing IPDK.

To start running an instance of the container:

In the base OS:
```bash
$ cd $HOME/ipdk
$ ipdk start -d
Loaded /home/andy/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
Missing QEMU.
Using docker run!
c75e8bbdcbac8e33c231a6f3348069089854d7f77ec6bf2f91373a98ea3ef42a
```

If this succeeds, there will now be a container process running, which
you can see in the output of the `docker ps` command as shown in the
example output below:

In the base OS:
```bash
$ docker ps
CONTAINER ID   IMAGE                                                COMMAND                  CREATED              STATUS              PORTS                                                                                  NAMES
c75e8bbdcbac   ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:sha-7978695   "/root/scripts/start…"   27 seconds ago   Up 27 seconds   0.0.0.0:9339->9339/tcp, :::9339->9339/tcp, 0.0.0.0:9559->9559/tcp, :::9559->9559/tcp   ipdk
```

The `ipdk connect` command starts a bash shell in the container and
leaves you at a prompt where you can enter commands for running in
that container.  Sample output of this command is shown below:

In the base OS:
```bash
$ ipdk connect
Loaded /home/andy/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env

WORKING_DIR: /root
Generating TLS Certificates...
Generating RSA private key, 4096 bit long modulus (2 primes)
...........................................................................................++++
...............................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................++++
e is 65537 (0x010001)
Generating RSA private key, 4096 bit long modulus (2 primes)
.++++
.....................................................................................................................................................................................................................++++
e is 65537 (0x010001)
Signature ok
subject=C = US, ST = CA, L = Menlo Park, O = Open Networking Foundation, OU = Stratum, CN = localhost
Getting CA Private Key
Generating RSA private key, 4096 bit long modulus (2 primes)
............................................................................................................................................++++
.++++
e is 65537 (0x010001)
Signature ok
subject=C = US, ST = CA, L = Menlo Park, O = Open Networking Foundation, OU = Stratum, CN = Stratum client certificate
Getting CA Private Key
Deleting old installed certificates
Certificates generated and installed successfully in  /usr/share/stratum/certs/
root@c75e8bbdcbac:~/scripts# 
```

The IPDK instructions suggest the command below to verify that there
is a process named `infrap4d` running.

In the container:
```bash
root@c75e8bbdcbac:~/scripts# ps -ef | grep infrap4d
root          47       1 99 12:35 ?        00:02:06 /root/networking-recipe/install/sbin/infrap4d
root         113      84  0 12:37 pts/1    00:00:00 grep --color=auto infrap4d
```

It looks like it is.  Now try running the demo bash script to see what
happens.

In the container:
```bash
root@c75e8bbdcbac:~/scripts# /root/scripts/rundemo_TAP_IO.sh

[ ... most of output omitted here.  See link below for file containing full example output when things are working as expected ... ]

Programming P4 pipeline


Ping from TAP0 port to TAP1 port

PING 2.2.2.2 (2.2.2.2) 56(84) bytes of data.
64 bytes from 2.2.2.2: icmp_seq=1 ttl=64 time=0.119 ms
64 bytes from 2.2.2.2: icmp_seq=2 ttl=64 time=0.121 ms
64 bytes from 2.2.2.2: icmp_seq=3 ttl=64 time=0.097 ms
64 bytes from 2.2.2.2: icmp_seq=4 ttl=64 time=0.126 ms
64 bytes from 2.2.2.2: icmp_seq=5 ttl=64 time=0.120 ms

--- 2.2.2.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4088ms
rtt min/avg/max/mdev = 0.097/0.116/0.126/0.010 ms
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=64 time=0.092 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=64 time=0.141 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=64 time=0.098 ms
64 bytes from 1.1.1.1: icmp_seq=4 ttl=64 time=0.094 ms
64 bytes from 1.1.1.1: icmp_seq=5 ttl=64 time=0.146 ms

--- 1.1.1.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4092ms
rtt min/avg/max/mdev = 0.092/0.114/0.146/0.024 ms
root@c75e8bbdcbac:~/scripts# 
```

That looks like success!  [Here](output-rundemo_TAP_IO.txt) is the
full example output from a working IPDK installation.

Note that very early in running the script `rundemo_TAP_IO.sh`, it
kills any `infrap4d` process that may be running, and also deletes the
network namespaces `VM0` and `VM1` if they exist.  Later in the script
it creates new network namespaces with those names.  Thus if you want
to do things like run `tcpdump` to capture packets into and/or out of
`infrap4d`, you need to run those `tcpdump` commands after the script
is started, but before the packets start flowing.

Even better, you should create your own script based upon the contents
of `rundemo_TAP_IO.sh` that sets things up like running infrap4d and
creating namespaces and interfaces, but doesn't send any packets.
Several such script have already been written that you can use for
this, descrbied below.


# A note on debugging P4 programs on the DPDK software switch

If you have used the BMv2 software switch before, i.e. the processes
called `simple_switch` or `simple_switch_grpc` compiled from source
code in this repository:

+ https://github.com/p4lang/behavioral-model

then you may have debugged P4 programs running on BMv2 by enabling
logging, e.g. via the `--log-console` or `--log-file` command line
options, and/or by adding `log_msg` extern function calls in the P4
program.

As of 2024-Feb-02, there is nothing like this available for debugging
of P4 programs running on the DPDK software switch.

As of this time, the best option available is to modify your P4
program in order to make key information that you care about for
learning the behavior of your program visible to you.  Some available
choices of making your program behavior visible are:

+ Change the output packet(s) in a way that makes it obvious which
  branches were taken in your code, or key intermediate values
  calculated inside your P4 code that you wish to observe.
  + One example of this can be seen in the program `add_on_miss0.p4`,
    where the P4 code assigns one numeric value to the least
    significant 8 bits of the packet's source Ethernet address if a
    table named `ct_tcp_table` gets a hit on a lookup, but assigns a
    different numeric value to those 8 bits if that table gets a miss
    on a lookup.  When you or some software observes the packets
    output by the DPDK software switch, you can look at those 8 bits
    of the source MAC address to learn whether that table lookup got a
    hit or a miss while processing that packet.
+ Update externs in your P4 program whose state can be read by control
  plane software after the packet has been processed, e.g.
  + Update P4 counters differently in different branches of your code.
  + Write to P4 register extern entries differently in different
    branches of your code, and/or write intermediate calculated values
    of header fields or metadata fields of interest to you into
    register entries.

Perhaps in the future other debugging options will be developed for P4
programs running on the DPDK software switch, but these are the best
known methods at present.


# Running a P4Runtime client program and connecting to DPDK software switch

All of the steps below were tested on an Ubuntu 20.04 system, after
following the IPDK networking container install steps successfully.

Start an instance of the container and connect to it using these
commands.

In the base OS:
```bash
cd $HOME/ipdk
ipdk start -d
ipdk connect
```

There are 9 cryptographic key/certificate files generated during
execution of the `ipdk connect` command.  These files are copied into
the directory `/usr/share/stratum/certs/` in the container's file
system.

Below is one way to successfully set things up so that a small Python
program can connect to TCP port 9559 of the `infrap4d` process in the
container, as a P4Runtime client, and send P4Runtime API read and
write request messages to `infrap4d`.

It shows how to run such a Python P4Runtime client program in the
container.  One advantage of doing it this way is that you can also
easily send packets to TAP interfaces from the same test client
program, and/or read packets output by the DPDK software switch on TAP
interfaces.

It is also possible to run such a Python P4Runtime client program in
the base OS.  I do not know of any straightforward way to enable such
a program running in the OS to send packets to or receive packets from
the DPDK software switch.  I consider this way mostly a curiosity at
this point, not a way to do much useful work, so that technique is not documented here.

Note: These instructions use the `p4runtime-shell` Python package,
which is only one of many ways to make a P4Runtime API connection from
a Python program to a P4-programmable network device that is running a
P4Runtime API server.  You need not install `p4runtime-shell` if you
do not want to use it, but these instructions do not give details on
any other ways to make a P4Runtime API connection.


## Installing `p4runtime-shell` and other software in the container

Follow the steps described in the section [Useful extra software to
install in the
container](#useful-extra-software-to-install-in-the-container).


## Making a P4Runtime API connection from Python program running in the container, to infrap4d

Copy the test Python P4Runtime client program `test-client.py` from
the base OS into the container, by running these commands.

In the base OS:
```bash
cp ~/p4-guide/ipdk/23.01/test-client.py ~/.ipdk/volume
```

In the container:
```bash
cp /tmp/test-client.py ~
```

After this setup, you should be able to run the test client program
with this command:

In the container:
```bash
source ~/my-venv/bin/activate
export PYTHON_PATH="/tmp/pylib"
~/test-client.py
```


### Troubleshooting: `No valid forwarding pipeline config has been pushed`

If you try to run the test client program and see an error message
like the one below:

In the container:
```bash
# ~/test-client.py
CRITICAL:root:Error when retrieving P4Info
CRITICAL:root:P4Runtime RPC error (FAILED_PRECONDITION): No valid forwarding pipeline config has been pushed for any node so far.
```

That is an indication that while `infrap4d` is running, no compiled P4
program has been loaded into it yet.

One way to load such a P4 program is to cause that to happen from your
P4Runtime API client program, which should result in sending a
`SetForwardingPipelineConfig` message from the client to `infrap4d`.
The `test-client.py` program does not attempt to do this.  It expects
there to already be a compiled P4 program and P4Info file loaded into
the device.

There is a command `p4rt-ctl` that can be run in the container to do
this.  A sample command line can be found within the
`rundemo_TAP_IO.sh` script, copied below (note that the two files
shown on this command line do not exist in the container when it is
first started -- they are created by a `p4c` P4 compilation command
that can also be found in the `rundemo_TAP_IO.sh` script):

In the container:
```bash
p4rt-ctl set-pipe br0 /root/examples/simple_l3/out/simple_l3.pb.bin /root/examples/simple_l3/out/simple_l3.p4Info.txt
```


### Troubleshooting: Do not try to run test client from `/tmp` directory

Normally you would think that in the container, you could simply run
`/tmp/test-client.py`, but for some reason I do not understand, doing
that fails when I try it on my system, with an error message like the
one below:

In the container:
```bash
# /tmp/test-client.py
Traceback (most recent call last):
  File "/tmp/test-client.py", line 5, in <module>
    import p4runtime_sh.shell as sh
  File "/usr/local/lib/python3.8/dist-packages/p4runtime_sh/shell.py", line 27, in <module>
    from p4runtime_sh.p4runtime import (P4RuntimeClient, P4RuntimeException, parse_p4runtime_error,
  File "/usr/local/lib/python3.8/dist-packages/p4runtime_sh/p4runtime.py", line 26, in <module>
    from p4.v1 import p4runtime_pb2
ImportError: dynamic module does not define module export function (PyInit_p4)
```

That error does not occur for me if I copy the `test-client.py` file
from `/tmp` to another directory, e.g. the `root` user's home
directory.

I get a similar error if, in the base OS, I try to run
`test-client.py` when it is stored in the directory `~/.ipdk/volume`.
Again, the workaround is to run that program with a copy of the file
in a directory that is not `~/.ipdk/volume`.


# Compiling a P4 program, loading it into infrap4d, sending packets in, and capturing packets out

Prerequisites: You have started the container, and followed the steps
described in the section [Useful extra software to install in the
container](#useful-extra-software-to-install-in-the-container).

The scripts below were adapted with minor variations from
`rundemo_TAP_IO.sh`, which is included with IPDK.  The scripts perform
these functions:

+ `setup_2tapports.sh` - Starts up an `infrap4d` process, creates a
  network namespace, and connects that namespace via two TAP
  interfaces to the `infrap4d` process.
+ `compile-p4.sh` - Compiles the source code of a P4 program to
  produce a P4Info file and a DPDK binary file.
+ `load_p4_prog.sh` - Loads a P4Info file and compiled DPDK binary
  file into into the running `infrap4d` process.

`rundemo_TAP_IO.sh` does very similar steps as all of the above
combined, one after the other, followed by running a couple of `ping`
commands to test packet forwarding through `infrap4d`.  These separate
scripts give a user a little bit more fine-grained control over when
they want to perform these steps.

Example command lines for these commands are described below.

In the base OS:
```bash
cp ~/p4-guide/ipdk/23.01/simple_l3.conf ~/.ipdk/volume
```

In the container:
```bash
/tmp/setup_2tapports.sh
```

For `compile-p4.sh`, `-p` specifies the directory where the source
file specified by `-s` can be found, and is also the directory where
the compiled output files are written if compilation succeeds.  The
`-a` option specifies whether to compile the program with the `pna` or
`psa` architecture, defaulting to `pna` if not specified.

In the container:
```bash
cp /tmp/simple_l3.conf /root/examples/simple_l3/
/tmp/compile-p4.sh -p /root/examples/simple_l3 -s simple_l3.p4 -a psa
```

For `load_p4_prog.sh`, `-p` specifies the compiled binary file to load
into the `infrap4d` process, which has a suffix of `.pb.bin` in place
of the `.p4` when created by the `compile-p4.sh` script.  The
option `-i` specifies the P4Info file, which when created by
`compile-p4.sh` always has the name `p4Info.txt`.

In the container:
```bash
/tmp/load_p4_prog.sh -p /root/examples/simple_l3/out/simple_l3.pb.bin -i /root/examples/simple_l3/out/simple_l3.p4Info.txt
```

Troubleshooting: In my testing, attempting to load a P4 program into
the same `infrap4d` process more than once fails after the first time
with an error message like this:

```
Error: P4Runtime RPC error (FAILED_PRECONDITION): Only a single forwarding pipeline can be pushed for any node so far.
```

This might be a restriction imposed by `infrap4d`.  A workaround is to
kill the `infrap4d` process, start a new one, and load the desired P4
program into the new `infrap4d` process.


## An exercise in using those scripts

Prerequisites: You have started the container, and followed the steps
described in the section [Useful extra software to install in the
container](#useful-extra-software-to-install-in-the-container).

Copy a modified version of the `simple_l3.p4` P4 program that we have
been using up to this point.

In the base OS:
```bash
cp -pr ~/p4-guide/ipdk/23.01/simple_l3_modecr/ ~/.ipdk/volume/
```

The directory `/root/examples/simple_l3_modecr` already contains a
pcap file that can be used for sending packets.  See the program
`gen-pcaps.py` in that directory for how it was created.

In the container:
```bash
source $HOME/my-venv/bin/activate
cp -pr /tmp/simple_l3_modecr/ /root/examples/
pushd /root/examples/simple_l3_modecr

/tmp/compile-p4.sh -p . -s simple_l3_modecr.p4 -a psa
/tmp/setup_2tapports.sh
/tmp/load_p4_prog.sh -p out/simple_l3_modecr.pb.bin -i out/simple_l3_modecr.p4Info.txt

# Run tiny controller program that adds a couple of table entries via
# P4Runtime API
PYTHON_PATH="/tmp/pylib" /root/examples/simple_l3_modecr/controller.py

# Check if table entries have been added
p4rt-ctl dump-entries br0
```

The output from the `p4rt-ctl dump-entries br0` command above should
look very similar to this if everything went well:

```bash
Table entries for bridge br0:
  table=ingress.ipv4_host hdr.ipv4.dst_addr=0x01010101 actions=ingress.send(port=0x00000000)
  table=ingress.ipv4_host hdr.ipv4.dst_addr=0x02020202 actions=ingress.send(port=0x00000001)
```

Set up `tcpdump` to capture packets coming out of the switch to the TAP1
interface:

In the container:
```bash
ip netns exec VM0 tcpdump -i TAP1 -w TAP1-try1.pcap &
```

Use `tcpreplay` to send packets into the switch on TAP0 interface:

In the container:
```bash
ip netns exec VM0 tcpreplay -i TAP0 /root/examples/simple_l3_modecr/pkt1.pcap
```

Kill the `tcpdump` process so it completes writing packets to the file
and stops appending more data to the file.

In the container:
```bash
killall tcpdump
```

You can copy the file `TAP1-try1.pcap` to the base OS and use
`tshark`, `wireshark`, or any program you like to examine it.

In the container:
```bash
cp TAP1-try1.pcap /tmp
```

Now use commands like one of those below.  There are many command line
options that cause `tshark` to generate different output formats
describing packets.

In the base OS:
```bash
tshark -V -r ~/.ipdk/volume/TAP1-try1.pcap
wireshark ~/.ipdk/volume/TAP1-try1.pcap
```


# Testing a P4 program for the PNA architecture using add-on-miss

I was especially interested in DPDK's implementation of this new
feature in the P4 Portable NIC Architecture
(https://github.com/p4lang/pna), where you can do an apply on a P4
table, and if it gets a miss, the miss action can optionally cause an
entry to be added to the table, without the control plane having to do
so.

Prerequisites: You have started the container, and followed the steps
described in the section [Useful extra software to install in the
container](#useful-extra-software-to-install-in-the-container).

In the base OS:
```bash
cp -pr ~/p4-guide/ipdk/23.01/add_on_miss0/ ~/.ipdk/volume/
```

In the container:
```bash
source $HOME/my-venv/bin/activate
export PYTHON_PATH="/tmp/pylib"
cp -pr /tmp/add_on_miss0/ /root/examples/

/tmp/compile-p4.sh -p /root/examples/add_on_miss0 -s add_on_miss0.p4 -a pna
/tmp/setup_2tapports.sh
/tmp/load_p4_prog.sh -p /root/examples/add_on_miss0/out/add_on_miss0.pb.bin -i /root/examples/add_on_miss0/out/add_on_miss0.p4Info.txt

# Run tiny controller program that adds a couple of table entries via
# P4Runtime API
/root/examples/add_on_miss0/controller.py

# Check if table entries have been added
p4rt-ctl dump-entries br0
```

The directory `/root/examples/add_on_miss0` already contains several
pcap files that can be used for sending packets.  See the program
`gen-pcaps.py` for how they were created.

Set up `tcpdump` to capture packets coming out of the switch to the
TAP1 interface.

In the container:
```bash
ip netns exec VM0 tcpdump -i TAP1 -w TAP1-try1.pcap &
```

Send TCP SYN packet on TAP0 interface, which should cause new entry to
be added to table `ct_tcp_entry`, and also be forwarded out the TAP1
port.  Immediately check the table entries.

In the container:
```bash
ip netns exec VM0 tcpreplay -i TAP0 /root/examples/add_on_miss0/tcp-syn1.pcap
p4rt-ctl dump-entries br0 ct_tcp_table
```

Note: I have asked the DPDK data plane developers, and confirmed that
for p4c-dpdk add-on-miss tables as of 2023-Mar-15, there is currently
no way to read the current set of entries from the control plane.  If
you try, you get back no entries.  That matches the behavior I have
seen.  I have confirmed using `add_on_miss0.p4`, which modifies output
packets differently depending upon whether a `ct_tcp_table` hit or
miss occurred, that I sometimes see misses, then hits for later
packets that are sent before the original table entry ages out.  I
have never seen any entries when trying to read `ct_tcp_table` from
the control plane.

Kill the `tcpdump` process so it completes writing packets to the file
and stops appending more data to the file.

In the container:
```bash
killall tcpdump
```

Attempting to add an entry to the add-on-miss table `ct_tcp_table`
from the control plane returns an error, as shown below:

In the container:
```bash
root@48ac7ef995ac:~/scripts# /root/examples/add_on_miss0/write-ct-tcp-table.py

[ ... some lines of output omitted here for brevity ... ]

Traceback (most recent call last):
  File "/root/examples/add_on_miss0/write-ct-tcp-table.py", line 41, in <module>
    add_ct_tcp_table_entry_action_ct_tcp_table_hit("1.1.1.1", "2.2.2.2",
  File "/root/examples/add_on_miss0/write-ct-tcp-table.py", line 39, in add_ct_tcp_table_entry_action_ct_tcp_table_hit
    te.insert()
  File "/usr/local/lib/python3.8/dist-packages/p4runtime_sh/shell.py", line 694, in insert
    self._write(p4runtime_pb2.Update.INSERT)
  File "/usr/local/lib/python3.8/dist-packages/p4runtime_sh/shell.py", line 688, in _write
    client.write_update(update)
  File "/usr/local/lib/python3.8/dist-packages/p4runtime_sh/p4runtime.py", line 124, in handle
    raise P4RuntimeWriteException(e) from None
p4runtime_sh.p4runtime.P4RuntimeWriteException: Error(s) during Write:
	* At index 0: INTERNAL, 'Error adding table entry with table_name: pipe.MainControlImpl.ct_tcp_table, table_id: 35731637, table_type: 2048, tdi_table_key { hdr.ipv4.src_addr { field_id: 1 key_type: 0 field_size: 32 value: 0x01010101 } hdr.ipv4.dst_addr { field_id: 2 key_type: 0 field_size: 32 value: 0x02020202 } hdr.ipv4.protocol { field_id: 3 key_type: 0 field_size: 8 value: 0x06 } hdr.tcp.src_port { field_id: 4 key_type: 0 field_size: 16 value: 0x0014 } hdr.tcp.dst_port { field_id: 5 key_type: 0 field_size: 16 value: 0x0050 } }, tdi_table_data { action_id: 17749373 }'
```


## A note on timeout durations in P4-DPDK

The PNA specification says that targets can have multiple timer
expiration profiles, typically numbered 0 through MAX_PROFILES-1,
where each profile has an independently configurable expiration time,
configurable by the control plane software.

I do not know if these expiration times are configurable via the
control plane software yet in the P4-DPDK implementatioon, but you can
see how many such timer expiration profiles there are, and what their
initial expiration times are, from looking at the `.spec` file
produced by the `p4c-dpdk` compiler.

Below is the portion of the `add_on_miss0.spec` file output by
`p4c-dpdk` for the P4 table `ct_tcp_table`:

```
learner ct_tcp_table {
	key {
		m.MainControlImpl_ct_tcp_table_ipv4_src_addr
		m.MainControlImpl_ct_tcp_table_ipv4_dst_addr
		m.MainControlImpl_ct_tcp_table_ipv4_protocol
		m.MainControlImpl_ct_tcp_table_tcp_src_port
		m.MainControlImpl_ct_tcp_table_tcp_dst_port
	}
	actions {
		ct_tcp_table_hit @tableonly
		ct_tcp_table_miss @defaultonly
	}
	default_action ct_tcp_table_miss args none
	size 0x10000
	timeout {
		10
		30
		60
		120
		300
		43200
		120
		120

		}
}
```

The `key`, `actions`, `default_action`, and `size` properties
correspond very closely with the corresponding definitions of those
table properties in the P4 source code.

The `timeout` part is not from the P4 source code, but is a default
value included for tables with idle timeout durations, I believe
corresponding with those having a supported value of
`pna_idle_timeout` or `idle_timeout_with_auto_delete` table
properties.

There are 8 integer values in a sequence there.  Each is a timeout
interval in units of seconds.  They are given in the order of expire
time profile id values from 0 up through 7.  Thus the initial
expiration time interval for expire time profile 0 is 10 seconds.
Until and unless these values are configurable from the control plane
software, you can use these default values, or hand-edit the `.spec`
file to customize these initial values selected by `p4c-dpdk`.

The program `add_on_miss0.p4` always provides a value of 1 to
`add_entry` extern function calls for the initial expire time profile
id of table entries it adds, and then it never modifies them after
that.  Thus the expire time for all entries created in `ct_tcp_table`
will always be 30 seconds for program `add_on_miss0.p4`.


# Running P4 program `add_on_miss0.p4` and testing it from a PTF test

Prerequisites: You have started the container, and followed the steps
described in the section [Useful extra software to install in the
container](#useful-extra-software-to-install-in-the-container).

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
cp -pr ~/p4-guide/ipdk/23.01/add_on_miss0/ ~/.ipdk/volume/
```

In the container:
```bash
source $HOME/my-venv/bin/activate
pushd /tmp/add_on_miss0

/tmp/compile-p4.sh -p . -s add_on_miss0.p4 -a pna
/tmp/setup_tapports_in_default_ns.sh -n 8
/tmp/load_p4_prog.sh -p out/add_on_miss0.pb.bin -i out/add_on_miss0.p4Info.txt
cd ptf-tests
./runptf.sh
```

Note: The DPDK software switch will fail to load a P4 program unless
it currently has a number of ports that is a power of 2.  The
`setup_tapports_in_default_ns.sh` script should check this restriction
and give an explanatory error message if you try to violate this
restriction.


# Running P4 program `add_on_miss1.p4` and testing it from a PTF test

Prerequisites: You have started the container, and followed the steps
described in the section [Useful extra software to install in the
container](#useful-extra-software-to-install-in-the-container).

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
cp -pr ~/p4-guide/ipdk/23.01/add_on_miss1/ ~/.ipdk/volume/
```

In the container:
```bash
source $HOME/my-venv/bin/activate
pushd /tmp/add_on_miss1

/tmp/compile-p4.sh -p . -s add_on_miss1.p4 -a pna
/tmp/setup_tapports_in_default_ns.sh -n 8
/tmp/load_p4_prog.sh -p out/add_on_miss1.pb.bin -i out/add_on_miss1.p4Info.txt
cd ptf-tests
./runptf.sh
```


# Running a P4 program and testing it using a PTF test

Prerequisites:

+ You have started the container, and followed the steps described in
  the section [Useful extra software to install in the
  container](#useful-extra-software-to-install-in-the-container).
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
compiling your P4 program.  This can make it easier to update it to
the latest version, or any version you wish.  Only the output files
from the compiler will be copied into the container where the P4 DPDK
data plane will execute it.


## Compiling the P4 program

In base OS:
```bash
BASENAME="sample"
DIR="<directory-with-P4-source-file>"
cd ${DIR}
compile.sh -a pna -s ${BASENAME}.p4
```


## Copying the necessary files into the container

In base OS:
```bash
mkdir -p ~/.ipdk/volume/${BASENAME}
cp -pr ${DIR}/out/* /path/to/{ptf-test1.py,runptf.sh} ~/.ipdk/volume/${BASENAME}
```


## Running the P4 program with the PTF test

In container:
```bash
BASENAME="sample"
source $HOME/my-venv/bin/activate
pushd /tmp/${BASENAME}
/tmp/tdi_pipeline_builder.sh -p . -s ${BASENAME}.p4
/tmp/setup_tapports_in_default_ns.sh -n 8
/tmp/load_p4_prog.sh -p ${BASENAME}.pb.bin -i ${BASENAME}.p4Info.txt
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


# Attempt to compile and load DASH P4 program into DPDK

In the base OS:
```bash
cp -pr ~/p4-guide/ipdk/23.01/dash/ ~/.ipdk/volume/
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


# Latest tested version of IPDK

Here is the version of the IPDK repo that I have tested these steps
with most recently:

```
$ cd $HOME/ipdk
$ git log -n 1
commit 8d49940dde4b8d59539006797146371a11a2009f
Merge: 0cad162 301a883
Author: Filip Szufnarowski <filip.szufnarowski@intel.com>
Date:   Wed Jun 28 14:35:54 2023 +0200

    Merge pull request #382 from intelfisz/update_recipe_environmentsetup
    
    adding kernel-headers and update
```
