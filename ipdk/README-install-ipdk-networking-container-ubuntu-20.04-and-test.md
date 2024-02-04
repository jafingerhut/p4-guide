# Introduction

These instructions are one tested way to install IPDK using its
networking container instructions on an Ubuntu 20.04 Linux system.
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
probably x86_64.  I do not know how to change the IPDK installation
scripts to avoid this problem (please let me know if you find out
how).

Note: If you try to build on a system with more than 4 virtual CPU
cores, the build scripts may try to run more compilations in parallel,
and thus may require more than 8 GB of RAM to succeed, failing if you
do not have enough RAM to run all of those processes simultaneously.

I successfully followed these steps using a VM created using
VirtualBox on an x86_64 macOS host system, but any Ubuntu 20.04
system, whether VM or running on the bare hardware, should also work.

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

I was not behind a web proxy, so I did not attempt to do any of the
proxy configuration steps described in the IPDK repo instructions.
See there if you are behind a proxy.

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


# What to try next?

See this [outline of other articles](README.md) for other tasks that
have step-by-step instructions you can try out after IPDK has been
installed on your system.


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
container](general-ipdk-notes.md#useful-extra-software-to-install-in-the-container).


## Making a P4Runtime API connection from Python program running in the container, to infrap4d

Copy the test Python P4Runtime client program `test-client.py` from
the base OS into the container, by running these commands.

In the base OS:
```bash
cp ~/p4-guide/ipdk/test-client.py ~/.ipdk/volume
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
