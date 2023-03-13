# Introduction

These are my notes on attempts to install IPDK by following public
instructions in this repository:

+ https://github.com/ipdk-io/ipdk

I am experienced with the open source P4 development tools, and
Tofino's P4 development tools, but this repository is new to me, and I
would like to find or develop a Bash script that can install the code
from this repository in at least one of the ways it is intended to be
installed.

Note that I do not yet know all of the intended deployment
possibilities for the code in this repo yet.  That is also something I
am hoping to understand.

It appears that the `infrap4d` program compiled and installed using
the steps below is a combination of at least the following parts:

+ The DPDK data plane that can have compiled P4 programs loaded into it.
+ A P4Runtime API server listening on TCP port 9559.
+ A gNMI server

The figure on this page seems to provide evidence that this is true,
and to explain some other software components included within the
`infrap4d` process:
https://github.com/ipdk-io/networking-recipe#infrap4d


# Tries starting 2023-Feb-07

This is after IPDK 23.01 was released.

## Andy's macOS 12 system

Hardware:
+ MacBook Pro, 16-inch, 2019
+ 2.4 GHz 8-core Intel Core i9
+ 64 GB RAM
+ Model identifier MacBookPro16,1

OS:
+ macOS 12.6.3

Versions of git, vagrant, and VirtualBox:
```bash
$ git version
git version 2.37.1 (Apple Git-137.1)

$ vagrant version
Installed Version: 2.3.4
Latest Version: 2.3.4
 
You're running an up-to-date version of Vagrant!

$ VBoxManage --version
6.1.42r155177
```

## try1: Attempt to install IPDK Networking Build, IPDK Native on Andy's macOS 12 system

Date: 2023-Feb-07

Hardware/OS is as described in section "Andy's macOS 12 system".

In macOS host system, created an Ubuntu 20.04 Desktop Linux VM running
within VirtualBox, with all the latest updates as of the date I
attempted this install.

+ VM name: Ubuntu 20.04 ipdk net native try1

Started logged in as a non-root user named `andy`, but then did `sudo
bash` to start a bash shell running as `root`.

Followed instructions in file `build/networking/README_NATIVE.md`,
where I used the directory `$HOME/clone` for `<CLONE-PATH>`.

```bash
$ sudo bash
# mkdir $HOME/clone
# cd $HOME/clone
# pwd
/root/clone
# git clone https://github.com/ipdk-io/ipdk.git
# cd ipdk
# git log -n 1 | head -n 10
commit dbab9e275a0838a5407e8fbe9fe337191532adc4
Merge: 067f6e7 f091eab
Author: Filip Szufnarowski <filip.szufnarowski@intel.com>
Date:   Tue Feb 7 12:39:25 2023 +0100

    Merge pull request #320 from intelfisz/feat-eliminate-shell-calls-in-storage
    
    Eliminate shell calls in storage.
# cd ..
# SCRIPT_DIR=$HOME/clone/ipdk/build/networking/scripts $HOME/clone/ipdk/build/networking/scripts/host_install.sh |& tee $HOME/clone/try1-out.txt
```

This got errors and quit very quickly.  See the file
[`try1-out.txt`](try1-out.txt).

It appears to be looking for files in `/git/ipdk` and subdirectories
underneath there, as if `<CLONE-PATH>` must be `/git` or else those
scripts will not work.  If `<CLONE-PATH>` has to be `/git` or nothing
works, then why not write the instructions with `/git` instead of
`<CLONE-PATH>`?

Looking at the `host_install.sh` script, it never mentions
`SCRIPT_DIR`, so that seems obsolete in the instructions.  It does
mention a `-d` command line option that might be what should be used.
I will try that below.

I have created a PR for the ipdk repo proposing simplifications to the
README_NATIVE.md instructions that should make them easier to follow
successfully: https://github.com/ipdk-io/ipdk/pull/376


## try4: Attempt to install IPDK Networking Build, IPDK Native on Andy's macOS 12 system

Deleted this section in favor of the `try6` section below, which is
more up to date and complete.


## try5: Attempt to install IPDK Networking Build, IPDK Container on Andy's macOS 12 system

Deleted this section in favor of the `try7` section below, which is
more up to date and complete.


## try6: Attempt to install IPDK Networking Build, IPDK Native on Andy's macOS 12 system

Date: 2023-Feb-20

Hardware/OS is as described in section "Andy's macOS 12 system".

In macOS host system, created an Ubuntu 20.04 Desktop Linux VM running
within VirtualBox, with all the latest updates as of the date I
attempted this install.

+ VM name: Ubuntu 20.04 ipdk net native try6
+ RAM: 8 GB

Started logged in as a non-root user named `andy`, but then did `sudo
bash` to start a bash shell running as `root`.

Followed my own slightly modified version of the instructions in file
`build/networking/README_NATIVE.md`, where I used the directory
`$HOME/clone` for `<CLONE-PATH>`.

```bash
$ sudo bash
# mkdir $HOME/clone
# cd $HOME/clone
# pwd
/root/clone
# git clone https://github.com/ipdk-io/ipdk.git
# cd ipdk
# git log -n 1
commit ab099be1b060c33f8b7088130fd7208b8509ea64 (HEAD -> main, origin/main, origin/HEAD)
Merge: 5351118 9724ac1
Author: Artek Koltun <artsiom.koltun@intel.com>
Date:   Fri Feb 17 16:06:26 2023 +0100

    Merge pull request #379 from intelfisz/fiopr
    
    Tests FIO in ptf tests
# cd ..
# $HOME/clone/ipdk/build/networking/scripts/host_install.sh -d $HOME/clone |& tee $HOME/clone/try6-out.txt
```

+ Time to complete: about 29 minutes
+ Maximum disk used at any point during the installation: a little under 7 GB
+ Final disk space used by the end of installation: a little under 5 GB

It appears to have succeeded, except for the last part where it tries
to create some TLS certificates.  The output of the install script is
in the file [`try6-out.txt`](try6-out.txt).  For the part that seems
to fail, see this line of output:

```
cp: cannot create directory '/usr/share/stratum/certs/': No such file or directory
```

It appears that this could have been fixed by uncommenting the
following line in the file, _before_ running the `host_install.sh`
script above:

```
#mkdir -p "${CERTS_DIR_LOCATION}"
```

Even if you did not do that, you can fix the situation at this time by
editing the file `/root/scripts/generate_tls_certs.sh` to remove the
`#` character at the beginning of that `mkdir ...` line.  Then run
this command:

```
/root/scripts/generate_tls_certs.sh
```

Below is my tailored version of the command for running the
`rundemo_TAP_IO.sh` script, based upon the directories I chose:

```bash
/root/clone/ipdk/build/networking/scripts/rundemo_TAP_IO.sh --workdir=/root |& tee $HOME/out-rundemo_TAP_IO.sh
```

If you see errors that look like this:

```
E20230220 18:39:24.025125  1801 credentials_manager.cc:100] Cannot access certificate/key files. Unable to initiate server_credentials.
E20230220 18:39:24.025245  1801 credentials_manager.cc:141] Cannot access certificate/key files. Unable to initiate client_credentials.
E20230220 18:39:24.046629  1801 gnmi_ctl.cc:396] Return Error: stub->Set(&ctx, req, &resp) failed with generic::invalid_argument: Invalid credentials.
I20230220 18:39:24.047788  1802 gnmi_ctl.cc:103] Client context cancelled.
```

Those occur while attempting to execute `gnmi-ctl` commands in the
`rundemo_TAP_IO.sh` script.  They occur because you have no created
TLS certificates as described earlier, so go back and do that.

With those certificates in place, `rundemo_TAP_IO.sh` started an
`infrap4d` process, loaded the compiled P4 program into it, added a
few table entries, and used a `ping` command to send packets through
it.  It all appeared to go successfully!

Ater these successful tests, I was also able to edit this file:

```
/root/examples/simple_l3/simple_l3.p4
```

to another legal P4 program that modified the TTL field in the IPv4
header to a different value than the value 64 it had when I used
`tcpdump` to capture the packets during a run of `rundemo_TAP_IO.sh`,
plus recalculate a correct IPv4 header checksum, and the modified
program was compiled and used when I ran `rundemo_TAP_IO.sh` again.

The original version of `simple_l3.p4` was copied from
`/root/clone/ipdk/build/networking/examples/simple_l3/simple_l3.p4`
and a copy is also in this directory in file
[`simple_l3.p4`](simple_l3.p4).

My modified version is in this directory as
[`simple_l3.modified.p4`](simple_l3.modified.p4).


## try7: Attempt to install IPDK Networking Build, IPDK Container on Andy's macOS 12 system

Date: 2023-Feb-21

Hardware/OS is as described in section "Andy's macOS 12 system".

In macOS host system, created an Ubuntu 20.04 Desktop Linux VM running
within VirtualBox, with all the latest updates as of the date I
attempted this install.

+ VM name: Ubuntu 20.04 ipdk net container try7
+ RAM: 8 GB

Started logged in as a non-root user named `andy`.

```bash
$ mkdir $HOME/clone
$ cd $HOME/clone
$ pwd
/home/andy/clone
$ git clone https://github.com/ipdk-io/ipdk.git
$ cd ipdk
$ git log -n 1
commit ab099be1b060c33f8b7088130fd7208b8509ea64 (HEAD -> main, origin/main, origin/HEAD)
Merge: 5351118 9724ac1
Author: Artek Koltun <artsiom.koltun@intel.com>
Date:   Fri Feb 17 16:06:26 2023 +0100

    Merge pull request #379 from intelfisz/fiopr
    
    Tests FIO in ptf tests
```

Now attempted to start following the instructions listed on this page:
https://github.com/ipdk-io/ipdk/blob/main/build/networking/README_DOCKER.md

```bash
$ cd $HOME/clone/ipdk/build
$ ./ipdk install
```

The last command above finished in a fraction of a second.

It created a directory `$HOME/.ipdk` and copied a file named
`ipdk.env` into it.

I already had a directory `$HOME/bin` in my shell's command PATH
before running the command above.  While running `./ipdk install`, it
also created a symbolic link named `$HOME/bin/ipdk` to
`$HOME/clone/ipdk/build/scripts/ipdk.sh`.

```bash
$ cd $HOME/clone/ipdk
$ ipdk install ubuntu2004
Loaded /home/andy/clone/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
User changable IPDK configuration file is already defined at 
'~/.ipdk/ipdk.env'.
Changed runtime environment to: ubuntu2004
IPDK CLI is installed!
```

The last command above finished very quickly with the output shown.
It appeared to modify the file `$HOME/.ipdk/ipdk.env`.  I am not sure
if it changed anything else.

### Install docker on Ubuntu 20.04

I tried following these instructions for installing Docker on Ubuntu
20.04:
https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

```bash
sudo apt-get update
sudo apt-get install --yes ca-certificates curl gnupg lsb-release
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

The IPDK install steps below require that you follow these "Linux
post-install steps" that enable a non-root user to run docker commands
without prefixing them with 'sudo', found here:
https://docs.docker.com/engine/install/linux-postinstall/

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

At this point, docker commands like `docker run hello-world` should
succeed _in that terminal window where you ran the `newgrp docker`
command_, but if you create a new terminal window without running
`newgrp docker`, it will fail.  If you reboot the system at this
point, then you should be able to run docker commands without `sudo`
in any new terminal window you create.


### Continue with IPDK install

I was not behind a proxy, so did not attempt to do any of the proxy
configuration steps described.  They should be unnecessary for my
current install attempt.

```bash
$ cd $HOME/clone/ipdk
$ ipdk build --no-cache |& tee try7-out.txt
```

The output of the install script is in the file
[`try7-out.txt`](try7-out.txt).

The maximum extra disk space used during the above command I saw was a
bit under 8.5 GB, and since some intermediate files were removed
during the build, the final disk space was a bit under 7GB more than
what was used on the system at the start.  This was with 4 CPU cores
on an x86_64 system -- I am not sure whether it could be more disk
space if more CPU cores were used.

The RAM required was nearly 6 GB while compiling p4c, with 4 CPU
cores.  It would likely be about 1.5 GB per CPU core at the highest.

On Andy's macOS 12 system, it took about 33 mins to complete, with a 1
Gbps Internet connection.

At this point, there was a new docker image created, as shown below:

```bash
$ docker images -a
REPOSITORY                               TAG           IMAGE ID       CREATED         SIZE
ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64   sha-c38906d   8de06103d9f3   27 hours ago    1.69GB
hello-world                              latest        feb5d9fea6a5   16 months ago   13.3kB
```

To start running an instance of the IPDK container:

```bash
$ cd $HOME/clone/ipdk
$ ipdk start -d
Loaded /home/andy/clone/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
Can't find update-binfmts.
Using docker run!
2c40e1efdc612e14c0102af068c2f4004bb247bdf2269ea8ba27663a6e901d9a
```

Note: If you run `ipdk start -d`, e.g. after rebooting the system on
which you installed IPDK, and you see an error message like `fatal:
not a git repository` followed later by `Unable to find image
'<some-name>' locally`, as shown in the example output below:

```
$ ipdk start -d
fatal: not a git repository (or any of the parent directories): .git
Loaded /home/andy/clone/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
Can't find update-binfmts.
Using docker run!
Unable to find image 'ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:sha-none' locally
docker: Error response from daemon: manifest unknown.
See 'docker run --help'.
```

This is most likely because you are trying to run the command when the
current directory is not one that is inside of your cloned copy of the
`ipdk` repository.  To avoid this, simply `cd $HOME/clone/ipdk` and
try the `ipdk start -d` command again.

Note: The docker image name is created containing a string of hex
digits at the end.  This hex string is part of the commit SHA of the
ipdk git repository at the time the docker image was created, so if
that changes because you updated your clone of the `ipdk` repo, you
may need to rebuild the docker image.

```bash
$ docker ps
CONTAINER ID   IMAGE                                                COMMAND                  CREATED              STATUS              PORTS                                                                                  NAMES
2c40e1efdc61   ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:sha-ab099be   "/root/scripts/start…"   About a minute ago   Up About a minute   0.0.0.0:9339->9339/tcp, :::9339->9339/tcp, 0.0.0.0:9559->9559/tcp, :::9559->9559/tcp   ipdk

$ ipdk connect
fatal: not a git repository (or any of the parent directories): .git
Loaded /home/andy/clone/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env

WORKING_DIR: /root
Generating TLS Certificates...
Generating RSA private key, 4096 bit long modulus (2 primes)
...................................................++++
............................++++
e is 65537 (0x010001)
Generating RSA private key, 4096 bit long modulus (2 primes)
.....................................................................................................................................................................++++
...........................++++
e is 65537 (0x010001)
Signature ok
subject=C = US, ST = CA, L = Menlo Park, O = Open Networking Foundation, OU = Stratum, CN = localhost
Getting CA Private Key
Generating RSA private key, 4096 bit long modulus (2 primes)
...................................................................++++
.................................................................................................................................................++++
e is 65537 (0x010001)
Signature ok
subject=C = US, ST = CA, L = Menlo Park, O = Open Networking Foundation, OU = Stratum, CN = Stratum client certificate
Getting CA Private Key
Deleting old installed certificates
Certificates generated and installed successfully in  /usr/share/stratum/certs/
root@21e5509506d8:~/scripts# 
```

The instructions suggest this command to verify that there is a
process named `infrap4d` running:

```bash
root@21e5509506d8:~/scripts# ps -ef | grep infrap4d
root          48       1 99 21:37 ?        00:02:18 /root/networking-recipe/install/sbin/infrap4d
root         114      85  0 21:39 pts/1    00:00:00 grep --color=auto infrap4d
```

It looks like it is.  Let's try running the demo bash script to see
what happens:

```bash
root@21e5509506d8:~/scripts# /root/scripts/rundemo_TAP_IO.sh

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
I20230222 21:40:41.957209   187 gnmi_ctl.cc:103] Client context cancelled.
setting vhost_dev = true.Set request, successful...!!!
I20230222 21:40:42.024011   195 gnmi_ctl.cc:103] Client context cancelled.
~/scripts

Generating dependent files from P4C and pipeline builder

~/examples/simple_l3 ~/scripts
I20230222 21:40:43.436168   212 tdi_pipeline_builder.cc:114] Found P4 program: simple_l3
I20230222 21:40:43.436239   212 tdi_pipeline_builder.cc:121] 	Found pipeline: pipe
~/scripts

Create two Namespaces


Move TAP ports to respective namespaces and bringup the ports


Assign IP addresses to the TAP ports


Add ARP table for neighbor TAP port


Add Route to reach neighbor TAP port


Programming P4 pipeline


Ping from TAP0 port to TAP1 port

PING 2.2.2.2 (2.2.2.2) 56(84) bytes of data.
64 bytes from 2.2.2.2: icmp_seq=1 ttl=64 time=0.112 ms
64 bytes from 2.2.2.2: icmp_seq=2 ttl=64 time=0.107 ms
64 bytes from 2.2.2.2: icmp_seq=3 ttl=64 time=0.122 ms
64 bytes from 2.2.2.2: icmp_seq=4 ttl=64 time=0.144 ms
64 bytes from 2.2.2.2: icmp_seq=5 ttl=64 time=0.108 ms

--- 2.2.2.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4079ms
rtt min/avg/max/mdev = 0.107/0.118/0.144/0.013 ms
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=64 time=0.123 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=64 time=0.117 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=64 time=0.107 ms
64 bytes from 1.1.1.1: icmp_seq=4 ttl=64 time=0.132 ms
64 bytes from 1.1.1.1: icmp_seq=5 ttl=64 time=0.141 ms

--- 1.1.1.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4071ms
rtt min/avg/max/mdev = 0.107/0.124/0.141/0.011 ms
root@21e5509506d8:~/scripts# 
```

That looks like success!

Note that running the script `rundemo_TAP_IO.sh` kills any `infrap4d`
process that may be running, and also deletes the network namespaces
`VM0` and `VM1` if they exist when the script is started (and then
later in the script creates new network namespaces with those names).
Thus if you want to do things like run `tcpdump` to capture packets
into and/or out of `infrap4d`, you need to run those `tcpdump`
commands after the script is started, but before the packets start
flowing.

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
$ cd $HOME/clone/ipdk
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


## try8: Attempt to install IPDK Networking Build, IPDK Container on Andy's macOS 12 system

Except for being a slightly later date, and the version of the ipdk
repo being slightly newer than try7, everything here went the same as
in try7.

Date: 2023-Mar-12

Hardware/OS is as described in section "Andy's macOS 12 system".

In macOS host system, created an Ubuntu 20.04 Desktop Linux VM running
within VirtualBox, with all the latest updates as of the date I
attempted this install.

+ VM name: Ubuntu 20.04 ipdk net container try8
+ RAM: 8 GB

Started logged in as a non-root user named `andy`.

```bash
$ mkdir $HOME/clone
$ cd $HOME/clone
$ pwd
/home/andy/clone
$ git clone https://github.com/ipdk-io/ipdk.git
$ cd ipdk
$ git log -n 1
commit 7978695ecfa84ebe9720b95d1eae8142d521d1ee (HEAD -> main, origin/main, origin/HEAD)
Merge: ab099be db1b3cb
Author: Filip Szufnarowski <filip.szufnarowski@intel.com>
Date:   Mon Mar 6 12:42:50 2023 +0100

    Merge pull request #380 from intelfisz/fix-build-failures
    
    Fix storage vm failures
```

Now attempted to start following the instructions listed on this page:
https://github.com/ipdk-io/ipdk/blob/main/build/networking/README_DOCKER.md

```bash
$ cd $HOME/clone/ipdk/build
$ ./ipdk install
```

The last command above finished in a fraction of a second.

It created a directory `$HOME/.ipdk` and copied a file named
`ipdk.env` into it.

I already had a directory `$HOME/bin` in my shell's command PATH
before running the command above.  While running `./ipdk install`, it
also created a symbolic link named `$HOME/bin/ipdk` to
`$HOME/clone/ipdk/build/scripts/ipdk.sh`.

```bash
$ cd $HOME/clone/ipdk
$ ipdk install ubuntu2004
Loaded /home/andy/clone/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
User changable IPDK configuration file is already defined at 
'~/.ipdk/ipdk.env'.
Changed runtime environment to: ubuntu2004
IPDK CLI is installed!
```

The last command above finished very quickly with the output shown.
It appeared to modify the file `$HOME/.ipdk/ipdk.env`.  I am not sure
if it changed anything else.

### Install docker on Ubuntu 20.04

I tried following these instructions for installing Docker on Ubuntu
20.04:
https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

```bash
sudo apt-get update
sudo apt-get install --yes ca-certificates curl gnupg lsb-release
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

The IPDK install steps below require that you follow these "Linux
post-install steps" that enable a non-root user to run docker commands
without prefixing them with 'sudo', found here:
https://docs.docker.com/engine/install/linux-postinstall/

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

At this point, docker commands like `docker run hello-world` should
succeed _in that terminal window where you ran the `newgrp docker`
command_, but if you create a new terminal window without running
`newgrp docker`, it will fail.  If you reboot the system at this
point, then you should be able to run docker commands without `sudo`
in any new terminal window you create.


### Continue with IPDK install

I was not behind a proxy, so did not attempt to do any of the proxy
configuration steps described.  They should be unnecessary for my
current install attempt.

```bash
$ cd $HOME/clone/ipdk
$ ipdk build --no-cache |& tee try8-out.txt
```

The output of the install script is in the file
[`try8-out.txt`](try8-out.txt).

On Andy's macOS 12 system, the command above took:

+ about 33 mins to complete, with a 1 Gbps Internet connection.
+ about 78 mins to complete, with a 1.5 to 2 MBytes/sec Internet download speed


# Running a P4Runtime client program and connecting to DPDK software switch

All of the steps below were tested on an Ubuntu 20.04 system, after
following the IPDK networking container install steps successfully.

Then start an IPDK container and connect to it using these commands:
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
inside of the IPDK networking container, e.g. a prompt that you got to
via an `ipdk connect` command.

Note: Given how the IPDK container is built with the version of the
Github ipdk repo available as of 2023-Mar-12, neither the `git`
command nor the `p4runtime-shell` Python package are installed inside
of the container when you first start a container process.  Thus if
you stop the container and start it again, e.g. rebooting the base OS
stops the container, you will need to repeat the steps below the next
time you start the container.

Install `git` (the `chmod` command below is needed since `apt-get`
commands often try to create temporary files in `/tmp`, and for some
reason the initial permissions on the `/tmp` directory inside the
container do not allow writing by arbitrary users):

```bash
chmod 777 /tmp
apt-get update
apt-get install --yes git
```

Install the `p4runtime-shell` Python package:
```bash
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

Run these commands in the base OS:

```bash
sudo apt-get install --yes python3-pip
sudo pip3 install git+https://github.com/p4lang/p4runtime-shell.git
```


## Making a P4Runtime API connection from Python program running in the base OS, to infrap4d

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
