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

Date: 2023-Feb-11

Hardware/OS is as described in section "Andy's macOS 12 system".

In macOS host system, created an Ubuntu 20.04 Desktop Linux VM running
within VirtualBox, with all the latest updates as of the date I
attempted this install.

+ VM name: Ubuntu 20.04 ipdk net container try5
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
commit c38906d2a9f94200d3f99fc8fc24a56013a5115b
Merge: dbab9e2 8763e4f
Author: Artek Koltun <artsiom.koltun@intel.com>
Date:   Wed Feb 8 12:57:38 2023 +0100

    Merge pull request #374 from intelfisz/feat-update-storage-libs
    
    Update storage libs.
```

Now attempted to start following the instructions listed on this page:
https://github.com/ipdk-io/ipdk/blob/main/build/networking/README_DOCKER.md

```bash
$ cd $HOME/clone/ipdk/build
$ ./ipdk install
```

The last command above finished in a fraction of a second.

It created a directory $HOME/.ipdk and copies a file named ipdk.env
into it.

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
$ sudo apt-get update
$ sudo apt-get install --yes ca-certificates curl gnupg lsb-release
$ sudo mkdir -m 0755 -p /etc/apt/keyrings
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
$ sudo apt-get install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

The IPDK install steps below require that you follow these "Linux
post-install steps" that enable a non-root user to run docker commands
without prefixing them with 'sudo', found here:
https://docs.docker.com/engine/install/linux-postinstall/

```bash
$ sudo groupadd docker
$ sudo usermod -aG docker $USER
$ newgrp docker
$ docker run hello-world
```

### Continue with IPDK install

I was not behind a proxy, so did not attempt to do any of the proxy
configuration steps described.  They should be unnecessary for my
current install attempt.

```bash
$ cd $HOME/clone/ipdk
$ ipdk build --no-cache |& tee out-ipdk-build--no-cache.txt
```

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

However, I got an error when trying what appears to be one of the next steps, which is running `ipdk start -d`:

```bash
$ ipdk start -d |& tee out-ipdk-start-d.txt
fatal: not a git repository (or any of the parent directories): .git
Loaded /home/andy/clone/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
Can't find update-binfmts.
Using docker run!
Unable to find image 'ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:sha-none' locally
docker: Error response from daemon: manifest unknown.
See 'docker run --help'.
andy@andyvm:~$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
andy@andyvm:~$ docker images
REPOSITORY                               TAG           IMAGE ID       CREATED         SIZE
ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64   sha-c38906d   8de06103d9f3   7 days ago      1.69GB
hello-world                              latest        feb5d9fea6a5   17 months ago   13.3kB
```

It looks like maybe it got the wrong tag name somehow, with `none`
instead of the correct SHA digits `c38906d`?



Try something different this time, making some semi-educated guesses
about how I should set some environment variable values before running
the commands:

```bash
$ docker images
REPOSITORY                               TAG           IMAGE ID       CREATED         SIZE
ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64   sha-c38906d   8de06103d9f3   7 days ago      1.69GB
hello-world                              latest        feb5d9fea6a5   17 months ago   13.3kB
```

```bash
$ export SCRIPT_DIR=$HOME/clone/ipdk/build/scripts

$ ipdk start -d |& tee out-ipdk-start-d-try2.txt
Loaded /home/andy/clone/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
Can't find update-binfmts.
Using docker run!
c69587abe39a81ae7905665ceec32981718d7fc04160f31a3bbede29094a0536

$ docker ps
CONTAINER ID   IMAGE                                                COMMAND                  CREATED              STATUS              PORTS                                                                                  NAMES
c69587abe39a   ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:sha-c38906d   "/root/scripts/start…"   About a minute ago   Up About a minute   0.0.0.0:9339->9339/tcp, :::9339->9339/tcp, 0.0.0.0:9559->9559/tcp, :::9559->9559/tcp   ipdk

$ ipdk connect
Loaded /home/andy/clone/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env

WORKING_DIR: /root
Generating TLS Certificates...
Generating RSA private key, 4096 bit long modulus (2 primes)
.................................................................................................++++
.................................................................................................................................................................................................................................................................++++
e is 65537 (0x010001)
Generating RSA private key, 4096 bit long modulus (2 primes)
....++++
..............................................................................................++++
e is 65537 (0x010001)
Signature ok
subject=C = US, ST = CA, L = Menlo Park, O = Open Networking Foundation, OU = Stratum, CN = localhost
Getting CA Private Key
Generating RSA private key, 4096 bit long modulus (2 primes)
.++++
.............................................++++
e is 65537 (0x010001)
Signature ok
subject=C = US, ST = CA, L = Menlo Park, O = Open Networking Foundation, OU = Stratum, CN = Stratum client certificate
Getting CA Private Key
Deleting old installed certificates
Certificates generated and installed successfully in  /usr/share/stratum/certs/
root@c69587abe39a:~/scripts# 
```

That looks somewhat promising.  What should I try next?

The instructions suggest this command to verify that there is a
process named infrap4d running:

```bash
root@c69587abe39a:~/scripts# ps -ef | grep infrap4d
root          47       1 99 18:53 ?        00:04:07 /root/networking-recipe/install/sbin/infrap4d
root         114      84  0 18:57 pts/1    00:00:00 grep --color=auto infrap4d
```

It looks like it is.  Let's try running the demo bash script to see
what happens:

```bash
root@c69587abe39a:~/scripts# /root/scripts/rundemo_TAP_IO.sh

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
I20230219 19:06:53.472540   223 gnmi_ctl.cc:103] Client context cancelled.
setting vhost_dev = true.Set request, successful...!!!
I20230219 19:06:53.540518   231 gnmi_ctl.cc:103] Client context cancelled.
~/scripts

Generating dependent files from P4C and pipeline builder

~/examples/simple_l3 ~/scripts
I20230219 19:06:55.042119   248 tdi_pipeline_builder.cc:114] Found P4 program: simple_l3
I20230219 19:06:55.042199   248 tdi_pipeline_builder.cc:121] 	Found pipeline: pipe
~/scripts

Create two Namespaces


Move TAP ports to respective namespaces and bringup the ports


Assign IP addresses to the TAP ports


Add ARP table for neighbor TAP port


Add Route to reach neighbor TAP port


Programming P4 pipeline


Ping from TAP0 port to TAP1 port

PING 2.2.2.2 (2.2.2.2) 56(84) bytes of data.
64 bytes from 2.2.2.2: icmp_seq=1 ttl=64 time=0.134 ms
64 bytes from 2.2.2.2: icmp_seq=2 ttl=64 time=0.102 ms
64 bytes from 2.2.2.2: icmp_seq=3 ttl=64 time=0.176 ms
64 bytes from 2.2.2.2: icmp_seq=4 ttl=64 time=0.177 ms
64 bytes from 2.2.2.2: icmp_seq=5 ttl=64 time=0.174 ms

--- 2.2.2.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4168ms
rtt min/avg/max/mdev = 0.102/0.152/0.177/0.030 ms
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=64 time=0.139 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=64 time=0.142 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=64 time=0.091 ms
64 bytes from 1.1.1.1: icmp_seq=4 ttl=64 time=0.092 ms
64 bytes from 1.1.1.1: icmp_seq=5 ttl=64 time=0.131 ms

--- 1.1.1.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4079ms
rtt min/avg/max/mdev = 0.091/0.119/0.142/0.022 ms
```

That looks like success, as far as I can tell.

It appears that the infrap4d process is a combination of the DPDK data
plane that can have compiled P4 programs loaded into it, and also
includes a P4Runtime API server listening on TCP port 9559.

TODO: Is this true?

TODO: What else does infrap4d include?


## try6: Attempt to install IPDK Networking Build, IPDK Native on Andy's macOS 12 system

Date: 2023-Feb-20

Hardware/OS is as described in section "Andy's macOS 12 system".

In macOS host system, created an Ubuntu 20.04 Desktop Linux VM running
within VirtualBox, with all the latest updates as of the date I
attempted this install.

+ VM name: Ubuntu 20.04 ipdk net native try4
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
