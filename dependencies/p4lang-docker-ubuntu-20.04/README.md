# Introduction

This document describes steps I took to verify that I could reproduce
the existing Docker image workflow among the following p4lang
projects, starting from an Ubuntu 20.04 Docker image.

+ third-party
+ PI
+ behavioral-model
+ p4c


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


## Create an Ubuntu 20.04 Docker image from the third-party repository

```bash
$ mkdir -p ~/ubuntu20.04

$ cd ~/ubuntu20.04

$ git clone https://github.com/p4lang/third-party
[... output omitted ... ]

$ cd third-party

$ git log -n 1 | head -n 3
commit 3e0bf558b0c0024fb185c223687e78195d82f200
Author: Radostin Stoyanov <rstoyanov@fedoraproject.org>
Date:   Tue Feb 8 18:53:24 2022 +0000

$ git submodule update --init --recursive
[... output omitted ... ]

$ time docker build -t testing1/third-party . |& tee out-docker-build-third-party-1.txt
[ ... most of output omitted, but saved in file out-docker-build-third-part-1.txt ... ]
real	21m25.923s
user	0m11.518s
sys	0m16.136s
```

When I tried the above, I got errors during the execution of the
following command inside the Ubuntu 20.04 Docker container:

```
#59 [grpc 10/10] RUN env GRPC_PYTHON_BUILD_WITH_CYTHON=1 pip3 install --user --ignore-installed .
```

Note: Until this is fixed somehow, there is no reason to clone the
p4lang/PI repository and try to run `docker build` on its Dockerfile,
because its Dockerfile starts with the one created by the
p4lang/third-party repository.


## Create an Ubuntu 20.04 Docker image from the PI repository

Note: Below is what _should_ be done next, if the steps in the
previous section were working.  However, since they are not, these are
just notes possibly useful in the future to someone who figures out
how to change the steps in the previous section so that they produce a
Docker image named `testing1/third-party`.

```bash
$ cd ~/ubuntu20.04

$ git clone https://github.com/p4lang/PI
[... output omitted ... ]

$ cd PI

$ git log -n 1 | head -n 3
commit 17802cfd67218a26307c0ea69fe520751ca6ab64
Author: Andy Fingerhut <andy.fingerhut@gmail.com>
Date:   Wed Feb 5 15:41:39 2025 -0500

$ git submodule update --init --recursive
[... output omitted ... ]
```

Here, hand-edit the file Dockerfile so that this line:
```
FROM p4lang/third-party:latest
```

is changed to this:
```
FROM testing1/third-party:latest
```

That change causes the PI/Dockerfile build command below to start with
the Docker image named `testing1/third-party` that was created in the
previous section.

```bash
$ time docker build -t testing1/pi . |& tee out-docker-build-pi-1.txt
```


## Create an Ubuntu 20.04 Docker image from the behavioral-model repository

Note: Below is what _should_ be done next, if the steps in all of the
the previous sections were working.

```bash
$ cd ~/ubuntu20.04

$ git clone https://github.com/p4lang/behavioral-model
[... output omitted ... ]

$ cd behavioral-model

$ git log -n 1 | head -n 3
commit d12eefc7bc19fb4da615b1b45c1235899f2e4fb1
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Tue Feb 18 21:18:38 2025 -0500
```

Here, hand-edit the file Dockerfile so that this line:
```
FROM p4lang/pi:${PARENT_VERSION}
```

is changed to this:
```
FROM testing1/pi:${PARENT_VERSION}
```

That change causes the behavioral-model/Dockerfile build command below
to start with the Docker image named `testing1/pi` that was created in
the previous section.

```bash
$ time docker build -t testing1/behavioral-model . |& tee out-docker-build-behavioral-model-1.txt
```


## Create an Ubuntu 20.04 Docker image from the p4c repository

Note: Below is what _should_ be done next, if the steps in all of the
the previous sections were working.

```bash
$ cd ~/ubuntu20.04

$ git clone https://github.com/p4lang/p4c
[... output omitted ... ]

$ cd p4c

$ git log -n 1 | head -n 3
commit e3f7fb367c59081d6019eab1b4e9f51237461fb2
Author: Fabian Ruffy <5960321+fruffy@users.noreply.github.com>
Date:   Sun Apr 6 20:09:25 2025 +0000
```

Here, hand-edit the file Dockerfile so that this line:
```
ARG BASE_IMAGE=p4lang/behavioral-model:latest
```

is changed to this:
```
ARG BASE_IMAGE=testing1/behavioral-model:latest
```

That change causes the p4c/Dockerfile build command below to start
with the Docker image named `testing1/behavioral-model` that was
created in the previous section.

```bash
$ time docker build -t testing1/p4c . |& tee out-docker-build-p4c-1.txt
```
