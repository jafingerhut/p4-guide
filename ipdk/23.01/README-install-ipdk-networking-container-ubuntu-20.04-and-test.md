# Introduction

These instructions are one specific, tested way to install IPDK using
its networking container instructions on an Ubuntu 20.04 Linux system.
The IPDK instructions and build scripts come from this repository:

+ https://github.com/ipdk-io/ipdk

It appears that the `infrap4d` program compiled and installed using
the steps below is a combination of at least the following parts:

+ The DPDK data plane that can have compiled P4 programs loaded into it.
+ A P4Runtime API server listening on TCP port 9559.
+ A gNMI server

The figure on this page seems to provide evidence that this is true,
and to explain some other software components included within the
`infrap4d` process:
https://github.com/ipdk-io/networking-recipe#infrap4d


# Installing IPDK using the networking docker build steps

The Ubuntu 20.04 Linux system that I have tried these steps with was
an x86_64 architecture CPU with 8 GB of RAM, and a little over 40
GBytes of free disk space.  It had 4 virtual CPU cores, and at its
most consumed a little bit under 9 GBytes of disk space out of
whatever free space existed when starting.

It was running in a VM inside of VirtualBox on a macOS host system, but
hopefully that part should be irrelevant for others following these steps.

Start logged in as a non-root user `$USER`.

To install docker:

```bash
cd $HOME
git clone https://github.com/jafingerhut/p4-guide
~/p4-guide/ipdk/23.01/install-docker-ubuntu-20.04.sh
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

All of the commands except the one beginning `ipdk build` should
complete very quickly.  The `ipdk build` command took 33 mins on a
2019-era MacBook Pro with a 1 Gbps Internet connection, but almost 80
minutes on the same laptop with a download speed ranging between 1.5
to 2 MBytes per second.

```bash
cd $HOME
git clone https://github.com/ipdk-io/ipdk.git
cd ipdk/build
./ipdk install
export PATH=$HOME/ipdk/build:$PATH
cd ..
ipdk install ubuntu2004
ipdk build --no-cache |& tee ipdk-build-out.txt
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

The creation of the IPDK container is now complete.  All later
instructions are for starting instances of this container, and running
the DPDK software switch inside of it.


# Notes on running `ipdk` commands

There is an `ipdk start` command to start an instance of the IPDK
container, an `ipdk connect` command that gets you to a bash prompt
running inside of the IPDK container, and several other `ipdk`
sub-commands that are useful for various purposes.

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


# A quick test of the IPDK installation

You may skip this section.  It is NOT required for installing IPDK.

To start running an instance of the IPDK container:

```bash
$ cd $HOME/ipdk
$ ipdk start -d
Loaded /home/andy/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
Can't find update-binfmts.
Using docker run!
c75e8bbdcbac8e33c231a6f3348069089854d7f77ec6bf2f91373a98ea3ef42a
```

If this succeeds, there will now be a container process running, which
you can see in the output of the `docker ps` command as shown in the
example output below:

```bash
$ docker ps
CONTAINER ID   IMAGE                                                COMMAND                  CREATED              STATUS              PORTS                                                                                  NAMES
c75e8bbdcbac   ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:sha-7978695   "/root/scripts/start…"   27 seconds ago   Up 27 seconds   0.0.0.0:9339->9339/tcp, :::9339->9339/tcp, 0.0.0.0:9559->9559/tcp, :::9559->9559/tcp   ipdk
```

The `ipdk connect` command starts a bash shell inside the container
and leaves you at a prompt where you can enter commands for running
inside of that container.  Sample output of this command is shown
below:

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
is a process named `infrap4d` running:

```bash
root@c75e8bbdcbac:~/scripts# ps -ef | grep infrap4d
root          47       1 99 12:35 ?        00:02:06 /root/networking-recipe/install/sbin/infrap4d
root         113      84  0 12:37 pts/1    00:00:00 grep --color=auto infrap4d
```

It looks like it is.  Now try running the demo bash script to see what
happens:

```bash
root@c75e8bbdcbac:~/scripts# /root/scripts/rundemo_TAP_IO.sh 

WORKING_DIR: /root
SCRIPTS_DIR: /root/scripts
DEPS_INSTALL_DIR: /root/networking-recipe/deps_install
P4C_INSTALL_DIR: /root/p4c/install
SDE_INSTALL_DIR: /root/p4-sde/install
NR_INSTALL_DIR: /root/networking-recipe/install


Cleaning from previous run

Cannot remove namespace file "/run/netns/VM0": No such file or directory
Cannot remove namespace file "/run/netns/VM1": No such file or directory

Setting hugepages up and starting networking-recipe processes

~ ~/scripts

DEPS_INSTALL_DIR: /root/networking-recipe/deps_install
SDE_INSTALL_DIR: /root/p4-sde/install
NR_INSTALL_DIR: /root/networking-recipe/install
P4C_INSTALL_DIR: /root/p4c/install



Updated Environment Variables ...
SDE_INSTALL_DIR: /root/p4-sde/install
LIBRARY_PATH: /root/networking-recipe/deps_install/lib:/root/networking-recipe/deps_install/lib64:/root/networking-recipe/deps_install/lib:/root/networking-recipe/deps_install/lib64:
LD_LIBRARY_PATH: /root/networking-recipe/deps_install/lib:/root/networking-recipe/deps_install/lib64:/root/networking-recipe/install/lib:/root/networking-recipe/install/lib64:/root/networking-recipe/deps_install/lib:/root/networking-recipe/deps_install/lib64:/root/networking-recipe/install/lib:/root/networking-recipe/install/lib64::/root/p4-sde/install/lib:/root/p4-sde/install/lib64:/root/p4-sde/install/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/lib64:/root/p4-sde/install/lib:/root/p4-sde/install/lib64:/root/p4-sde/install/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/lib64
PATH: /root/p4c/install/bin:/root/networking-recipe/deps_install/bin:/root/networking-recipe/deps_install/sbin:/root/networking-recipe/install/bin:/root/networking-recipe/install/sbin:/root/p4c/install/bin:/root/networking-recipe/deps_install/bin:/root/networking-recipe/deps_install/sbin:/root/networking-recipe/install/bin:/root/networking-recipe/install/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

1024
1024

SDE_INSTALL_DIR: /root/p4-sde/install
NR_INSTALL_DIR: /root/networking-recipe/install


NR_INSTALL_DIR: /root/networking-recipe/install
DEAMON_MODE_ARGS: 

~/scripts

Creating TAP ports

~ ~/scripts
setting vhost_dev = true.Set request, successful...!!!
I20230313 12:38:43.734566   187 gnmi_ctl.cc:103] Client context cancelled.
setting vhost_dev = true.Set request, successful...!!!
I20230313 12:38:43.812232   195 gnmi_ctl.cc:103] Client context cancelled.
~/scripts

Generating dependent files from P4C and pipeline builder

~/examples/simple_l3 ~/scripts
I20230313 12:38:45.017838   212 tdi_pipeline_builder.cc:114] Found P4 program: simple_l3
I20230313 12:38:45.017911   212 tdi_pipeline_builder.cc:121] 	Found pipeline: pipe
~/scripts

Create two Namespaces


Move TAP ports to respective namespaces and bringup the ports


Assign IP addresses to the TAP ports


Add ARP table for neighbor TAP port


Add Route to reach neighbor TAP port


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

That looks like success!

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


# Running a P4Runtime client program and connecting to DPDK software switch

All of the steps below were tested on an Ubuntu 20.04 system, after
following the IPDK networking container install steps successfully.

Start an IPDK container and connect to it using these commands:
```bash
cd <path-to-your-clone-of-ipdk-repository>
ipdk start -d
ipdk connect
```

There are 9 cryptographic key/certificate files generated during
execution of the `ipdk connect` command.  These files are copied into
the directory `/usr/share/stratum/certs/` inside the container's file
system.

Below are two ways to successfully set things up so that a small
Python program can connect to TCP port 9559 of the `infrap4d` process
inside the container, as a P4Runtime client, and send P4Runtime API
read and write request messages to `infrap4d`.

The first way shows how to run such a Python test client program
inside of the container.  One advantage of doing it this way is that
you can also easily send packets to TAP interfaces from the same test
client program, and/or read packets output by the DPDK software switch
on TAP interfaces.

The second way shows how to run such a Python test client program in
the base OS.  I do not know of any straightforward way to enable such
a program running in the OS to send packets to or receive packets from
the DPDK software switch.

Note: These instructions use the `p4runtime-shell` Python package,
which is only one of many ways to make a P4Runtime API connection from
a Python program to a P4-programmable network device that is running a
P4Runtime API server.  You need not install `p4runtime-shell` if you
do not want to use it, but these instructions do not give details on
any other ways to make a P4Runtime API connection.

When the instructions say to run a command inside the IPDK container,
it means at a shell prompt that you can reach via running the `ipdk
connect` command.

When the instructions say to run a command outside the IPDK container,
or in the base OS, the command should be executed in a terminal window
that is _not_ inside the IPDK container, but on the base Ubuntu 20.04
operating system.


## Installing `p4runtime-shell` inside the IPDK container

The commands in this section should be run from inside
inside of the IPDK networking container, i.e. a prompt that you got to
via an `ipdk connect` command.

Note: Given how the IPDK container is built with the version of the
Github ipdk repo available as of 2023-Mar-12, neither the `git`
command nor the `p4runtime-shell` Python package are installed inside
of the container when you first start a container process.  Thus if
you stop the container and start it again, e.g. rebooting the base OS
stops the container, you will need to repeat the steps below the next
time you start the container.

Install `git` command and `p4runtime-shell` Python package (the
`chmod` command below is needed since `apt-get` commands often try to
create temporary files in `/tmp`, and for some reason the initial
permissions on the `/tmp` directory inside the container do not allow
writing by arbitrary users):

```bash
chmod 777 /tmp
apt-get update
apt-get install --yes git
pip3 install git+https://github.com/p4lang/p4runtime-shell.git
```

If all of the above steps succeeded, you should see at least the
following P4-related Python packages installed.  The hex digits at the
end of the `p4runtime-shell` version may differ from what you see
below, if updates to the `p4runtime-shell` repo on Github have been
made after this document was written.

```bash
# pip3 list | grep p4
p4runtime                1.3.0
p4runtime-shell          0.0.3.post5+g2603e13
```


## Making a P4Runtime API connection from Python program running inside the IPDK container, to infrap4d

Prerequisite: You have installed the `p4runtime-shell` Python package
inside the IPDK container.

Copy the test Python P4Runtime client program `test-client.py` from
the base OS into the container, by running these commands in the base
OS:

```bash
cp ~/p4-guide/ipdk/23.01/test-client.py ~/.ipdk/volume
```

Then run this command inside the container:

```bash
cp /tmp/test-client.py ~
```

After this setup, you should be able to run the test client program
with this command:

```bash
~/test-client.py
```

Troubleshooting: Normally you would think that inside the container,
you could simply run `/tmp/test-client.py`, but for some reason I do
not understand, doing that fails when I try it on my system, with an
error message like the one below:

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
`test-client.py` when it is stored inside of the directory
`~/.ipdk/volume`.  Again, the workaround is to run that program with a
copy of the file in a directory that is not `~/.ipdk/volume`.


## Installing `p4runtime-shell` in the base OS

Note: You can ignore this section if you prefer to run P4Runtime API
client programs inside the container.

Run these commands in the base OS:

```bash
sudo apt-get install --yes python3-pip
sudo pip3 install git+https://github.com/p4lang/p4runtime-shell.git
```


## Making a P4Runtime API connection from Python program running in the base OS, to infrap4d

Note: You can ignore this section if you prefer to run P4Runtime API
client programs inside the container.

First copy the current cryptographic key/certificate files required
for a client to authenticate itself to the server.  This step only
needs to be done once each time these files change.  One event that
causes these files to change is running `ipdk connect` from the base
OS.

When the IPDK container is started, it is done in a way such that the
directory `/tmp` inside the container is equivalent to the directory
`$HOME/.ipdk/volume` in the base OS.  That is, any changes made to the
directory on one side is immediately reflected on the other side.

Inside the container:
```bash
cp /usr/share/stratum/certs/{ca.crt,client.key,client.crt} /tmp/
```

In the base OS:
```bash
mkdir ~/my-certs
sudo cp ~/.ipdk/volume/{ca.crt,client.crt,client.key} ~/my-certs
sudo chown ${USER}.${USER} ~/my-certs/*
```

After this setup, you should be able to run the test client program
with this command.  The `test-client.py` program takes an optional
parameter that is the name of a directory where it should find the
files `ca.crt`, `client.crt`, and `client.key` that were copied above.

```bash
~/p4-guide/ipdk/23.01/test-client.py ~/my-certs/
```


# Additional experiments

Nothing in this section is required to install or use the IPDK
container.  It describes some experiments that I ran to try out a few
things.  I will likely polish it up a bit in the future.

Since the `rundemo_TAP_IO.sh` script ends with the network namespaces
still existing, and the `infrap4d` process still running, it is much
easier to do experiments like the ones below after `rundemo_TAP_IO.sh`
has completed.

Confirm that the interface `TAP0` exists in network namespace `VM0`,
and interface `TAP1` exists in network namespace `VM1`:

```bash
root@21e5509506d8:~/scripts# ip netns exec VM0 ip link show
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: TAP0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether a6:a6:fd:48:5c:16 brd ff:ff:ff:ff:ff:ff

root@21e5509506d8:~/scripts# ip netns exec VM1 ip link show
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
3: TAP1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether 42:a2:58:59:c5:98 brd ff:ff:ff:ff:ff:ff
```

Start `tcpdump` running and recording packets sent on interface `TAP1`
in namespace `VM1`.  I do this in a separate terminal window in which
I have run these commands, to connect to the same container as the one
that the commands above were run in:

(In new terminal window)
```bash
$ cd $HOME/ipdk
$ ipdk connect
[ ... many lines of output omitted ... ]

root@21e5509506d8:~/scripts# apt install tcpdump
[ ... many lines of output omitted ... ]

root@21e5509506d8:~/scripts# ip netns exec VM1 tcpdump -i TAP1 -w TAP1-try1.pcap
```

(back in the original terminal window)
```bash
root@21e5509506d8:~/scripts# ip netns exec VM0 ping 2.2.2.2 -c 5
PING 2.2.2.2 (2.2.2.2) 56(84) bytes of data.
64 bytes from 2.2.2.2: icmp_seq=1 ttl=64 time=0.108 ms
64 bytes from 2.2.2.2: icmp_seq=2 ttl=64 time=0.249 ms
64 bytes from 2.2.2.2: icmp_seq=3 ttl=64 time=0.099 ms
64 bytes from 2.2.2.2: icmp_seq=4 ttl=64 time=0.130 ms
64 bytes from 2.2.2.2: icmp_seq=5 ttl=64 time=0.111 ms

--- 2.2.2.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4082ms
rtt min/avg/max/mdev = 0.099/0.139/0.249/0.055 ms
```

Now go back to the other terminal window where `tcpdump` is still
running, and type Ctrl-C to quit `tcpdump`, and then run the following
command to copy the captured packets in the pcap file into directory
`/tmp` inside the container.  When the container was started using the
commands above, directory `/tmp` inside the container is the same
directory as `$HOME/.ipdk/volume` in the base OS.

```bash
root@21e5509506d8:~/scripts# cp TAP1-try1.pcap /tmp 
```

In yet another terminal window running as a normal user in the base
OS, not inside the IPDK container, let us use these commands to view
the captured packets using Wireshark:

```bash
$ sudo apt install --yes wireshark
$ wireshark ~/.ipdk/volume/TAP1-try1.pcap
```

I have confirmed that by modifying the file
`/root/examples/simple_l3/simple_l3.p4` and then running the
`rundemo_TAP_IO.sh` script again, as long as the changes to the P4
program compile without errors, the script will update the
`simple_l3.spec` file that is loaded into `infrap4d`.

Try using Python3 library Scapy to send packets into the DPDK software
switch:

(in a terminal that is executing commands inside the IPDK container)
```bash
root@21e5509506d8:~/scripts# ip netns exec VM1 tcpdump -l -i TAP1 -e -n --number -v
tcpdump: listening on TAP1, link-type EN10MB (Ethernet), capture size 262144 bytes
```

Now we can watch in that terminal to see messages printed about each
packet that appears on the `TAP1` interface in network namespace
`VM1`.

(in a separate terminal that is executing commands inside the IPDK container)
```
root@21e5509506d8:~# pip3 install scapy

root@21e5509506d8:~# ip netns exec VM0 python3
Python 3.8.10 (default, Nov 14 2022, 12:59:47) 
[GCC 9.4.0] on linux
Type "help", "copyright", "credits" or "license" for more information.

>>> from scapy.all import *
WARNING: Interface lo: no address assigned

>>> fwd_pkt1=Ether() / IP(dst='2.2.2.2') / TCP(sport=5793, dport=80)
>>> sendp(fwd_pkt1, iface='TAP0')
```

You can see packets that appear on interface `TAP1` in the other
terminal window very shortly after they go across that interface.

Note: On TAP interfaces, it appears that perhaps the source and/or
dest MAC addresses provided by the sender might be overwritten by the
Linux kernel.  I do not know if there is a way to prevent that
behavior.

I also do not know if there is a way to enable DPDK to communicate
over veth interfaces.  This page might give a solution for that, but I
have not understood it well enough nor tried out any of its
recommendations:
https://dpdk.readthedocs.io/en/v17.11/sample_app_ug/kernel_nic_interface.html


# Latest tested version of IPDK

Here is the version of the IPDK repo that I have tested these steps
with most recently:

```
$ cd $HOME/ipdk
$ git log -n 1
commit 7978695ecfa84ebe9720b95d1eae8142d521d1ee (HEAD -> main, origin/main, origin/HEAD)
Merge: ab099be db1b3cb
Author: Filip Szufnarowski <filip.szufnarowski@intel.com>
Date:   Mon Mar 6 12:42:50 2023 +0100

    Merge pull request #380 from intelfisz/fix-build-failures
    
    Fix storage vm failures
```
