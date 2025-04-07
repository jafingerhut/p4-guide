# Introduction

This document describes steps I took in an attmept to create a new
Docker image workflow among the following p4lang projects, starting
from an Ubuntu 24.04 Docker image.

+ third-party
+ PI
+ behavioral-model
+ p4c

These steps are not completely working yet, as decribed later in this
document.


## Base system on which Docker was run

I ran an Ubuntu 24.04 Desktop Linux system within a VirtualBox VM,
running on an x86_64 processor.

This VM had 16 GBytes of RAM, and 4 VCPUs.

```bash
$ head /proc/meminfo 
MemTotal:       16376720 kB
MemFree:        12805428 kB
MemAvailable:   14876620 kB
Buffers:           74512 kB
Cached:          2231504 kB
SwapCached:            0 kB
Active:          1725732 kB
Inactive:        1468920 kB
Active(anon):     932052 kB
Inactive(anon):        0 kB

$ cat /etc/os-release 
PRETTY_NAME="Ubuntu 24.04.2 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.2 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
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


## Create an Ubuntu 24.04 Docker image from a modified fork of the third-party repository

```bash
$ mkdir -p ~/ubuntu24.04
$ cd ~/ubuntu24.04

$ git clone https://github.com/jafingerhut/third-party
[... output omitted ... ]

$ cd third-party

$ git checkout use-ubuntu-24.04-in-docker-container

$ git log -n 1 | head -n 3
commit 9c1996a8a40864ad0657300ab2db1b40455ad59b
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Thu Mar 13 15:06:23 2025 +0000

$ git submodule update --init --recursive
[... no submodules to get, so empty output ... ]

$ time docker build -t jafingerhut/third-party . |& tee out-docker-build-third-party-1.txt
[ ... most of output omitted, but saved in file out-docker-build-third-party-1.txt ... ]
real	52m22.547s
user	0m6.145s
sys	0m14.991s

$ docker images
REPOSITORY                TAG       IMAGE ID       CREATED       SIZE
jafingerhut/third-party   latest    7a4e0531ff9d   7 hours ago   462MB
```


## Create an Ubuntu 24.04 Docker image from a modified fork of the PI repository

```bash
$ cd ~/ubuntu24.04

$ git clone https://github.com/jafingerhut/PI
[... output omitted ... ]

$ cd PI

$ git checkout use-jafingerhut-docker-image

$ git log -n 1 | head -n 3
commit 8577a002c41f8c5e26eaed27019104c12bf7dd23
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Tue Mar 11 22:47:41 2025 -0700

$ git submodule update --init --recursive
[... output omitted ... ]

$ time docker build -t jafingerhut/pi . |& tee out-docker-build-pi-1.txt
[ ... most of output omitted, but saved in file out-docker-build-pi-1.txt ... ]
real	7m22.432s
user	0m1.210s
sys	0m2.931s

$ docker images
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
jafingerhut/pi            latest    d4cea4b3a96e   12 minutes ago   514MB
jafingerhut/third-party   latest    7a4e0531ff9d   7 hours ago      462MB
```


## Create an Ubuntu 24.04 Docker image from a modified fork of the behavioral-model repository

```bash
$ cd ~/ubuntu24.04

$ git clone https://github.com/jafingerhut/behavioral-model
[... output omitted ... ]

$ cd behavioral-model

$ git checkout dockerfile-updates-for-ubuntu-24.04

$ git log -n 1 | head -n 3
commit 17858633ee232387614e215598fa3f986e22ef4b
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Wed Mar 12 08:50:37 2025 -0700

$ time docker build -t jafingerhut/behavioral-model . |& tee out-docker-build-behavioral-model-1.txt
[ ... most of output omitted, but saved in file out-docker-build-pi-1.txt ... ]
real	14m12.042s
user	0m1.862s
sys	0m3.657s

$ docker images
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
jafingerhut/pi            latest    d4cea4b3a96e   37 minutes ago   514MB
jafingerhut/third-party   latest    7a4e0531ff9d   8 hours ago      462MB
```

Note: No Docker image named jafingerhut/behavioral-model exists,
because the `docker build ...` command above experienced errors while
attempting to build BMv2.  Those errors can be seen in file
`out-docker-build-behavioral-model-1.txt` near the end.

The errrs appear to be related to some libraries built by the PI step
referring to symbols that appear to be related to SSL and/or other
encryption features.  I suspect that something in the way one of these
docker iamges is being built is not setting it up to use the latest
Ubuntu 24.04 versions of the SSL libraries.  Either that, or perhaps
they _are_ set up to use those, but something in p4lang code is using
deprecated function calls that have been removed since the version of
the SSL libraries that came with Ubuntu 20.04.


## Create an Ubuntu 24.04 Docker image from a modified fork of the p4c repository

Note: Below is what _should_ be done next, if the steps in all of the
the previous sections were working.

```bash
$ cd ~/ubuntu24.04

$ git clone https://github.com/jafingerhut/p4c
[... output omitted ... ]

$ cd p4c

$ git checkout dockerfile-updates-for-ubuntu-24.04

$ git log -n 1 | head -n 3
commit 8e7a2b3a243cecf54d5fcc96b7422a1eae38ee8d
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Thu Mar 13 08:35:07 2025 -0700

$ time docker build -t jafingerhut/p4c . |& tee out-docker-build-p4c-1.txt
[ ... most of output omitted, but saved in file out-docker-build-pi-1.txt ... ]
[ TODO: copy and paste time take to complete command above ]

$ docker images
[ TODO: copy and paste output here ]
```
