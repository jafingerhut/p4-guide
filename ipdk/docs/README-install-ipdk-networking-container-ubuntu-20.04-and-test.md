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

All of the commands immediately below should complete very quickly:

```bash
cd $HOME
git clone https://github.com/ipdk-io/ipdk.git
cd ipdk/build
./ipdk install
export PATH=$HOME/ipdk/build:$PATH
cd ..
ipdk install ubuntu2004    # if base OS is Ubuntu
ipdk install fedora33      # if base OS is Fedora
```

You now have two choices:

+ source: Install the container by building it from source code on
  your own system.  On a 2019-era MacBook Pro with a 1 Gbps Internet
  connection, this took 33 minutes for me, but 80 minutes on the same
  system with a download speed ranging between 1.5 to 2 MBytes per
  second.
+ pre-built container: Install the container by downloading one that I
  have built from source code from Docker Hub.  This image is about
  1.8 GBytes in size.

If you choose "source", execute this command:
```bash
ipdk build --no-cache |& tee $HOME/log-ipdk-build.txt
```
See below for a command to verify that you now have a docker image on
your system with the name `ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64`.

If you choose "pre-built container", execute this command:
```bash
docker pull jafingerhut/ipdk-net:ipdk_v23.07
```
then edit the file `$HOME/.ipdk/ipdk.env` to replace this line:
```
IMAGE_NAME=ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64
```
with these lines:
```
IMAGE_NAME=jafingerhut/ipdk-net
TAG="ipdk_v23.07"
```
See next for a command to verify that you now have a docker iamge on
your system with the name `jafingerhut/ipdk-net`.

At this point, you should see that you have a docker image with the
name mentioned above -- the precise name depends upon whether you
chose "source" or "pre-built container".  The sample output below
shows something similar to what you should see if you chose "source":

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


# Publishing an IPDK Docker image for others to use

These steps are _not_ necessary for anyone to follow in order to
install or use IPDK.  I am recording these steps for my own future
reference if and when I want to publish future versions of the IPDK
networking container to Docker Hub.

First, build the IPDK networking container from source code, following
the instructions for building from source above.

Let `IMAGE_ID` be a shell variable whose value is the hexadecimal
string appearing in the "IMAGE ID" column of the image that is built
from source code, as seen in the output of the command `docker images
-a`, as shown in the example earlier.

My account name is `jafingerhut` on Docker Hub, but I will generalize
the instructions slightly in case others really do want to use these
steps.

```
IMAGE_ID="e4d502f4a4ee"
DOCKER_HUB_USER_ID="jafingerhut"

docker login
# Enter your Docker hub user id and password, if asked for it.

docker tag ${IMAGE_ID} ${DOCKER_HUB_USER_ID}/ipdk-net:ipdk_v23.07
docker push ${DOCKER_HUB_USER_ID}/ipdk-net:ipdk_v23.07
```


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
