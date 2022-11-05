# Introduction

These are my notes on attempts to install IPDK by following public
instructions in this repository, as of 2022-Nov-05:

+ https://github.com/ipdk-io/ipdk

I am experienced with the open source P4 development tools, Tofino's
P4 development tools, but this repository is new to me, and I'd like
to find or develop a Bash script that can install the code from this
repository in at least one of the ways it is intended to be installed.

Note that I do not yet know all of the intended deployment
possibilities for the code in this repo yet.  That is also something I
am hoping to understand.


# Andy's macOS 12 system

Hardware:
+ MacBook Pro, 16-inch, 2019
+ 2.4 GHz 8-core Intel Core i9
+ 64 GB RAM
+ Model identifier MacBookPro16,1

OS:
+ macOS 12.6.1

Versions of git, vagrant, and VirtualBox:
```
$ git version
git version 2.37.1 (Apple Git-137.1)

$ vagrant version
Installed Version: 2.3.2
Latest Version: 2.3.2
 
You're running an up-to-date version of Vagrant!

$ VBoxManage --version
6.1.40r154048
```


# Attempt to install IPDK Networking Build, IPDK Container on Andy's macOS 12 system

Hardware/OS is as described in section "Andy's macOS 12 system".

```
$ cd $HOME/Documents/p4-docs/ipdk
$ git clone https://github.com/ipdk-io/ipdk
$ cd ipdk
$ git log -n 1 | head -n 3
commit 637e132b30d4e8fdddfffe9a157614ae63e04deb
Merge: 0adb4ef 5214f61
Author: Artek Koltun <artsiom.koltun@intel.com>
```

Follow instructions in file build/networking/README_DOCKER.md, under
heading "Bringup the Vagrant VM":

Starting from root directory of ipdk repo:
```
$ cd build/networking/vagrant-container
$ vagrant up
```

During this step, I noticed in VirtualBox GUI that these two VMs were
created with the following names:

+ `packer_ubuntu-20.04-amd64-docker_1667683537944_84434` - 1024 MB RAM, 2 processors
+ `ipdk-container` - 8192 MB RAM, 4 processors

See the contents of the following file for the output I saw on my
macOS terminal during execution of the `vagrant up` command:

+ [macos12-networking-container-vagrant-up-log.txt](macos12-networking-container-vagrant-up-log.txt)

Follow instructions in file build/networking/README_DOCKER.md, under
heading "Login to the VM":

```
vagrant ssh
```

Follow instructions in file build/networking/README_DOCKER.md, under
heading "Login to the VM":

```
vagrant@ubuntu2004:~$ ipdk connect
-bash: ipdk: command not found
```

It was not clear from the README instructions what to do at this point
about such a basic error.  I deleted the two VMs created using
VirtualBox GUI, to clean things up in preparation for my next attempt.


# Attempt to install IPDK Networking Build, IPDK Native on Andy's macOS 12 system

Hardware/OS is as described in section "Andy's macOS 12 system".

```
$ cd $HOME/Documents/p4-docs/ipdk
$ git clone https://github.com/ipdk-io/ipdk
$ cd ipdk
$ git log -n 1 | head -n 3
commit 637e132b30d4e8fdddfffe9a157614ae63e04deb
Merge: 0adb4ef 5214f61
Author: Artek Koltun <artsiom.koltun@intel.com>
```

Follow instructions in file build/networking/README_NATIVE.md, under
heading "Bringup the Vagrant VM":

Starting from root directory of ipdk repo:
```
$ cd build/networking/vagrant-native
$ vagrant up 2>&1 | tee macos12-networking-native-vagrant-up-log.txt
```

+ [macos12-networking-native-vagrant-up-log.txt](macos12-networking-native-vagrant-up-log.txt)

Follow instructions in file build/networking/README_NATIVE.md, under
heading "Login to the VM":

```
vagrant ssh
```

Follow instructions in file build/networking/README_NATIVE.md, under
heading "Run the install script to install all dependencies and build
components.":

```
sudo su -
SCRIPT_DIR=/git/ipdk/build/networking/scripts /git/ipdk/build/networking/scripts/host_install.sh
```

See the following file for the output that I saw on running the
commands above:

+ [macos12-networking-native-step2.txt](macos12-networking-native-step2.txt)

I might be able to figure out how to work around that error, but why
should I?  Shouldn't the instructions work as given in the README?
