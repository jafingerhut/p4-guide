# Introduction

This document describes steps I took in an attmept to create a new
Docker image workflow among the following p4lang projects, starting
from an Ubuntu 26.04 Docker image.

+ third-party
+ PI
+ behavioral-model
+ p4c

TODO: Summarize how well these steps are working after trying them
out.

## Base system on which Docker was run

I ran an Ubuntu 26.04 Desktop Linux system within a VirtualBox VM,
running on an x86_64 processor.

This VM had 16 GBytes of RAM, and 4 VCPUs.

```bash
$ head /proc/meminfo 
MemTotal:       15847460 kB
MemFree:        12864552 kB
MemAvailable:   14502148 kB
Buffers:           37740 kB
Cached:          1861552 kB
SwapCached:            0 kB
Active:          2301512 kB
Inactive:         371860 kB
Active(anon):     810344 kB
Inactive(anon):        0 kB

$ cat /etc/os-release 
PRETTY_NAME="Ubuntu 26.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="26.04"
VERSION="26.04.1 LTS (Resolute Raccoon)"
VERSION_CODENAME=resolute
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=resolute
LOGO=ubuntu-logo
```

On this system I installed Docker by using a simple Bash script that
simply attempts to follow the documented instructions for installing
Docker on an Ubuntu Linux system:

+ https://github.com/jafingerhut/p4-guide/blob/master/bin/install-docker.sh

Then I rebooted the system and tested the Docker installation with the
command:

```bash
docker run hello-world
```

The command above ran successfully.


## Create an Ubuntu 26.04 Docker image from a modified fork of the third-party repository

```bash
$ mkdir -p ~/ubuntu26.04
$ cd ~/ubuntu26.04

$ git clone https://github.com/jafingerhut/third-party
[... output omitted ... ]

$ cd third-party

$ git checkout add-ubuntu26-dockerfile

$ git log -n 1 | head -n 3
commit 00000e9a1528667a7d7d1151ed0abedc84fb2a89
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Sun Oct 18 06:10:27 2026 -0400

$ git submodule update --init --recursive
[... no submodules to get, so empty output ... ]

$ time docker build --no-cache -t jafingerhut/third-party:latest-ubuntu-26.04 -f Dockerfile.ubuntu-26.04 . |& tee out-docker-build-third-party-1.txt
[ ... most of output omitted, but saved in file out-docker-build-third-party-1.txt ... ]
real	3m2.437s
user	0m0.642s
sys	0m1.735s

$ docker images
IMAGE                                          ID             DISK USAGE   CONTENT SIZE   EXTRA
jafingerhut/third-party:latest-ubuntu-26.04    fd7b23d0c3f0        579MB          140MB        
```

Earlier I tried updating:

+ libyang directory to tag v3.1.0
+ sysrepo directory to tag v2.10.1

because the libpcre3 apt package existed on Ubuntu until 24.04, but
did not exist on Ubuntu 26.04.  Those versions of libyang and sysrepo
had been updated to work with a later version of libpcre that was
available to install as a package on 26.04 (libpcre2-dev).

Later I simply modified the Dockerfile.ubuntu-26.04 so that it does
not build these libraries.


## Create an Ubuntu 26.04 Docker image from a modified fork of the PI repository

```bash
$ cd ~/ubuntu26.04

$ git clone https://github.com/jafingerhut/PI
[... output omitted ... ]

$ cd PI

$ git checkout add-ubuntu26-dockerfile

$ git log -n 1 | head -n 3
commit 71ece2bd562e8694625b5dab706b26e71a7bdc40
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Tue Oct 20 21:56:47 2026 -0400

$ git submodule update --init --recursive
[... output omitted ... ]

$ time docker build --no-cache -t jafingerhut/pi:latest-ubuntu-26.04 -f Dockerfile.ubuntu-26.04 --build-context p4lang/third-party:latest-ubuntu-26.04=docker-image://jafingerhut/third-party:latest-ubuntu-26.04 . |& tee out-docker-build-pi-1.txt
[ ... most of output omitted ... ]
real	3m35.643s
user	0m0.621s
sys	0m1.571s
```


## Create an Ubuntu 26.04 Docker image from a modified fork of the behavioral-model repository

```bash
$ cd ~/ubuntu26.04

$ git clone https://github.com/jafingerhut/behavioral-model
[... output omitted ... ]

$ cd behavioral-model

$ git checkout add-ubuntu26-dockerfile

$ git log -n 1 | head -n 3
commit 3b5eb85686042d6bb3743199535ae4749818158b
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Tue Oct 20 22:38:55 2026 -0400

$ time docker build --no-cache -t jafingerhut/behavioral-model:latest-ubuntu-26.04 -f Dockerfile.ubuntu-26.04 --build-context p4lang/pi:latest-ubuntu-26.04=docker-image://jafingerhut/pi:latest-ubuntu-26.04 . |& tee out-docker-build-behavioral-model-1.txt
[ ... most of output omitted, but saved in file out-docker-build-pi-1.txt ... ]
real	9m32.984s
user	0m0.697s
sys	0m1.716s
```


## Create an Ubuntu 26.04 Docker image from a modified fork of the p4c repository

Note: Below is what _should_ be done next, if the steps in all of the
the previous sections were working.

```bash
$ cd ~/ubuntu26.04

$ git clone https://github.com/jafingerhut/p4c
[... output omitted ... ]

$ cd p4c

# no branch created.  Already merged only known small fix needed into main branch

$ git log -n 1 | head -n 3
commit fa467df37c1d42e6928340468875536a20ec3d66 (up/main, up/HEAD)
Author: Jiri Havranek <jiri@pantherun.com>
Date:   Tue Oct 20 13:33:06 2026 +0000

$ time docker build --no-cache -t jafingerhut/p4c:latest-ubuntu-26.04 -f Dockerfile.ubuntu-26.04 --build-context p4lang/behavioral-model:latest-ubuntu-26.04=docker-image://jafingerhut/behavioral-model:latest-ubuntu-26.04 . |& tee out-docker-build-p4c-1.txt
[ ... most of output omitted, but saved in file out-docker-build-pi-1.txt ... ]
real	33m39.395s
user	0m9.812s
sys	0m17.839s

$ docker images
[ TODO: copy and paste output here ]
```
