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

```
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

Date: 2023-Feb-10

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

```
$ sudo bash
# mkdir $HOME/clone
# cd $HOME/clone
# pwd
/root/clone
# git clone https://github.com/ipdk-io/ipdk.git
# cd ipdk
# git log -n 1
commit c38906d2a9f94200d3f99fc8fc24a56013a5115b
Merge: dbab9e2 8763e4f
Author: Artek Koltun <artsiom.koltun@intel.com>
Date:   Wed Feb 8 12:57:38 2023 +0100

    Merge pull request #374 from intelfisz/feat-update-storage-libs
    
    Update storage libs.
# cd ..
# $HOME/clone/ipdk/build/networking/scripts/host_install.sh -d $HOME/clone |& tee $HOME/clone/try4-out.txt
```

This run took about 29 mins to complete, and appears like it may have
succeeded.  The output of the install script is in the file
[`try4-out.txt`](try4-out.txt).

TODO: Test the resulting system to see if it can run P4 programs on
DPDK, and record any failed or succeeding command sequences and their
output that distinguishes good from bad results here.
