# Introduction

These are my notes on attempts to install IPDK by following public
instructions in this repository, as of 2021-Dec-17:

+ https://github.com/ipdk-io/ipdk

I am experienced with the open source P4 development tools, Tofino's
P4 development tools, but this repository is new to me, and I'd like
to find or develop a Bash script that can install the code from this
repository in at least one of the ways it is intended to be installed.

Note that I do not yet know all of the intended deployment
possibilities for the code in this repo yet.  That is also something I
am hoping to understand.


# First attempt to install code on Ubuntu 18.04 Desktop Linux

I started with a freshly installed Ubuntu 18.04 Desktop Linux system
in a VM with 4 GB of RAM, 4 VCPUs, and over 40 GB of free disk space,
running on a host with a 64-bit Intel CPU.

I tried writing the script `ubuntu18.04-install.sh`, in this
directory, based upon the install steps described here:

+ https://github.com/ipdk-io/ipdk/blob/main/build/IPDK_Container/ovs-with-p4_howto

That script fails while trying to build the code in the `target-utils`
repo.  The output of the failed run can be found
[here](fail-logs/log01.txt).  I have sent this script and failed
output log to the IPDK Slack channel on 2021-Dec-17 to see if anyone
there knows the root cause, and how to successfully build the code
using different commands.


# Install code on Ubuntu 18.04 Desktop Linux within a Docker container

I have run a few Docker commands in my life, but I am still very much
new to Docker.  Despite that, I will try using instruction in the
`ipdk` repo related to Docker and see if I can get those to work.


# Installing Docker on Ubuntu 18.04

I am attempting to follow instructions found on the Docker site here
for installing Docker on Ubuntu Linux:

+ https://docs.docker.com/engine/install/ubuntu/

First, uninstall any old versions of Docker on the system:

```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

No packages were removed from my system when I ran that command.

The instructions mention a `/var/lib/docker` directory.  I checked and
there was no such directory on my system.

The instructions page mentiones 3 supported storage drivers, but
except for saying that `overlay2` is the default, does not describe
why I might want to pick one over the other.  I will assume for now
that the default `overlay2` storage driver is a reasonable choice for
this purpose.

Three installation methods are mentioned on the page.  I am going to
try the first one, set up Docker's repositories of packages to be
known on my system, and install from them.

I will use the stable Docker repo, not the nightly or test channels.

I will use the latest stable version, not hand-select a particular
version.

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

After running the commands above, I saw this version of the `docker`
command installed on my system.  The executable program
`/usr/bin/docker` is part of the package `docker-ce-cli`:

```bash
$ docker --version
Docker version 20.10.12, build e91ed57
```

The following command appeared to run with the expected output for a
successful installation of Docker:

```bash
$ sudo docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
2db29710123e: Pull complete 
Digest: sha256:2498fce14358aa50ead0cc6c19990fc6ff866ce72aeb5546e1d59caac3d0d60f
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/

```

These commands showed that the `docker.service` and
`containerd.service` systems were active and running:

```bash
systemctl status docker.service
systemctl status containerd.service
```

I have not yet followed the post-install instructions on this web page
that cause these services to be started every time my system is
rebooted:

+ https://docs.docker.com/engine/install/linux-postinstall/

Nor have I modified the permissions of my user account to avoid the
need to use `sudo` to successfully run `docker` commands.

I did try running these commands from the Troubleshooting section of
the post-install web page, mainly out of curiosity.

Check kernel compatibility with `check-config.sh` script:

```bash
curl https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh > check-config.sh
bash ./check-config.sh
```

The output showed all "Generally Necessary" features were enabled in
the kernel version I was running, and most of the optional ones, too.
Only about 4 optional features were missing.

```bash
$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 18.04.6 LTS
Release:	18.04
Codename:	bionic

$ uname -a
Linux p4dev-linwin 5.4.0-91-generic #102~18.04.1-Ubuntu SMP Thu Nov 11 14:46:36 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
```


# Trying the Ubuntu 20.04 Dockerfile on an Ubuntu 18.04 host

From the name of the directory, maybe I should be trying this on an
Ubuntu 20.04 host system instead, but I will give it a try and see
what happens:

```bash
$ git clone https://github.com/ipdk-io/ipdk
$ cd ipdk/build/IPDK_Container/Ubuntu20.04

$ OS_VERSION="20.04"
$ IMAGE_NAME="ipdk/p4-ovs-fc33"
# TODO: Try changing to this in a later run:
###IMAGE_NAME = ipdk/p4-ovs-ubuntu20.04
$ TAG=`git rev-parse --short HEAD`

$ echo $OS_VERSION
20.04

$ echo $IMAGE_NAME
ipdk/p4-ovs-fc33

$ echo $TAG
bae1355
```

After the above commands, I ran the command below, which had lots of
output as it was running commands inside of `Dockerfile` in the
`Ubuntu20.04` directory of the `ipdk` repo:

```bash
$ sudo docker build --no-cache -t ${IMAGE_NAME}:${TAG} -f Dockerfile . --build-arg OS_VERSION=${OS_VERSION}

```


# Installing Docker on Fedora

In particular, I tried Fedora 34.

I am attempting to follow instructions found on the Docker site here
for installing Docker on Ubuntu Linux:

+ https://docs.docker.com/engine/install/fedora/

First, uninstall any old versions of Docker on the system:

```bash
sudo dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
```

This removed tens of packages in my Fedora 34 system.

The instructions mention a `/var/lib/docker` directory.  I checked and
there was no such directory on my system.

Three installation methods are mentioned on the page.  I am going to
try the first one, set up Docker's repositories of packages to be
known on my system, and install from them.

I will use the stable Docker repo, not the nightly or test channels.

I will use the latest stable version, not hand-select a particular
version.

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io
```

Start the docker systemd service:

```bash
sudo systemctl start docker
```

After running the commands above, I saw this version of the `docker`
command installed on my system.  The executable program
`/usr/bin/docker` is part of the package `docker-ce-cli`:

```bash
$ docker --version
Docker version 20.10.12, build e91ed57
```

The following command appeared to run with the expected output for a
successful installation of Docker:

```bash
$ sudo docker run hello-world
[ ... about 20 lines of good-looking output omitted ... ]
```


# Install code on Fedora within a Docker container

Again, I was using Fedora 34, after going through steps in previous
section to install Docker on Fedora 34.

The main instructions I am following, with a few variations mentioned
below, are from this README in the ipdk repo:

+ ipdk/build/IPDK_Container/README

```bash
git clone https://github.com/ipdk-io/ipdk
cd ipdk/build/IPDK_Container

OS_VERSION="33"
IMAGE_NAME="ipdk/p4-ovs-fc33"
REPO="${PWD}"
TAG=`git rev-parse --short HEAD`

## Build the container without caching. To be used when cloning from GIT repo.
sudo docker build --no-cache -t ${IMAGE_NAME}:${TAG} -f Dockerfile . --build-arg OS_VERSION=${OS_VERSION}
```

The last command above took a very long time to install the DNF scapy
package, because it installed TeXlive, too.  Weird.  Probably should
consider trimming down the package install list, as it should not need
to install TeXlive.

The commands below are what the directions in the
IPDK_Container/README file will run if you run `make volume`, except
the versions below use `sudo`:

```bash
sudo docker volume create shared
sudo docker run --rm --cap-add ALL --privileged -v shared:/tmp -it ${IMAGE_NAME}:${TAG}
```

The last command changes the prompt, because it is running a shell
inside of the container.  Exiting from that shell goes back to the
base OS Bash prompt, outside of the container.

Continuing with following directions in the README:

```bash
source /root/start_p4ovs.sh /root
```

That command cloned a git repo that I believe not only had one or more
submodules in its third-party directory, but some of those submodules
were git repos that in turn had their own submodules, 3 or 4 levels
deep!  Is this intentional?

I think there was even a case where it was not a tree, but a DAG, with
a third-party git repo that occurred as a submodule of multiple parent
git repos.  Is this intentional?

There was a 'dnf install scapy' command somewhere in the scripts,
which seems to as a side effect also install TeXlive.  That seems like
a sloppy definition of a scapy package that pulls in a TeXlive
installation, which is quite large.  It seems worth asking whether the
scapy Fedora package either (a) could be skipped entirely, or (b)
could have its definition changed so it does not pull in TeXlive as
well.

At some point after installing many packages and compiling some
package using a build tool called `ninja`, the Docker image simply
disappeared.  I do not know how to find out why that happened.

See the next section for my attempt at installing IPDK code on the
base Fedora system, without using Docker.


# Install code on Fedora in base system, not inside a container

See the script `fedora-step1-install-pkkgs.sh` in this directory for
my first attempt at a script towards this goal.
