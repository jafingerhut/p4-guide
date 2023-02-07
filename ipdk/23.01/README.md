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
```
$ git version
git version 2.37.1 (Apple Git-137.1)

$ vagrant version
Installed Version: 2.3.4
Latest Version: 2.3.4
 
You're running an up-to-date version of Vagrant!

$ VBoxManage --version
6.1.42r155177
```

## Attempt to install IPDK Networking Build, IPDK Native on Andy's macOS 12 system

Date: 2023-Feb-07

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

Created an Ubuntu 20.04 Desktop Linux VM running within VirtualBox,
with all the latest updates as of the date I attempted this install.

VM name: Ubuntu 20.04 ipdk net native try1

Started logged in as a non-root user named `andy`, but first did `sudo bash` to start a bash shell running as `root`.

Followed instructions in file `build/networking/README_NATIVE.md`,
where I used the directory `/home/andy/clone` for `<CLONE-PATH>`.

```
$ sudo bash
# mkdir $HOME/clone
# cd $HOME/clone
# pwd
/root/clone
# git clone https://github.com/ipdk-io/ipdk.git
# SCRIPT_DIR=$HOME/clone/ipdk/build/networking/scripts $HOME/clone/ipdk/build/networking/scripts/host_install.sh |& tee $HOME/clone/out.txt
```

This got errors and quit very quickly.  It appears to be looking for
files in /git/ipdk and subdirectories underneath there, as if
`<CLONE-PATH>` must be `/git` or else those scripts will not work.  If
that is true, then why not write the instructions with `/git` instead
of `<CLONE-PATH>`?
