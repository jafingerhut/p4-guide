# Introduction


## Quick instructions for successful install script run

Start with an unmodified fresh installation of Ubuntu Linux 16.04 or
18.04, with at least 2 GB of RAM (4 GB preferred), 10 GB of free disk
space, and a reliable Internet connection that is up for the entire
duration of running the install script.

Then run these commands in a terminal.  You may run the commands from
any directory you wish -- I typically run it from the home directory
of my account.  Whichever directory is your current directory when you
start the script, is where new directories with names like `p4c`,
`behavioral-model`, `protobuf`, etc. will be created.
```
$ sudo apt install git
$ git clone https://github.com/jafingerhut/p4-guide
$ ./p4-guide/bin/install-p4dev-p4runtime.sh |& tee log.txt
```
[Replace `install-p4dev-p4runtime.sh` with `install-p4dev.sh` or
`install-p4dev-v2.sh` if you prefer to use those install scripts
instead.]

I have tested the install scripts most often when running as a normal
user, i.e. not as the superuser `root`.  There are several `sudo`
commands in the install script, some of which will prompt you to enter
your password before the script can continue.  This can occur multiple
times during the execution of the script, so check it every 15 minutes
or so until it is finished, to see if it is waiting for you to enter
your password.

The `|& tee log.txt` part of the command is not necessary for the
install to work.  It causes the output of the script to be saved to
the file `log.txt`, as well as appear in the terminal window.  The
output is about 10,000 lines long on a good run, so saving it to a
file is good if you want to see what it did.


## Details

This page gives a few tips for those having difficulties using one of
these installation scripts to install the open source P4 development
tools:

+ [install-p4dev-p4runtime.sh](install-p4dev-p4runtime.sh) - If you
  want to use the P4Runtime API from controller software to configure
  the P4 program tables.
+ [install-p4dev.sh](install-p4dev.sh) - If you do not want to bother
  installing the P4Runtime API software, and can get by with older
  controller APIs, e.g. the API based upon Thrift.

You can find the (long) output files from my test runs of these
scripts that I do about once per month in [the bin/output
directory](output/) of this repository.  The dates on those files show
when I last ran them.

Things I did that helped this process go smoothly:

+ I started from an _unmodified_ _fresh_ installation of Ubuntu Linux.
  These install scripts install many packages using `apt-get`, and
  although I do not know how to determine a complete list of which
  Ubuntu packages conflict with each other, I know there are some that
  when simultaneously installed on a system, _can_ cause problems for
  each other.  Thus if you start from an Ubuntu machine with many
  packages installed on it already, and one of them conflicts with the
  packages installed by these scripts, you may not end up with a
  working installation of the open source P4 development tools.
  
  In particular, I tested with all of the Ubuntu install images linked
  below.  In my testing, I installed them as a virtual machine using
  VirtualBox on a Mac running macOS 10.13 High Sierra as the host
  operating system, but installing them as a virtual machine on a
  different host operating system, or on a bare machine, should also
  work:
  + [Ubuntu Desktop 18.04.3](http://releases.ubuntu.com/18.04/ubuntu-18.04.3-desktop-amd64.iso) for the amd64 architecture
  + [Ubuntu Desktop 16.04.6](http://releases.ubuntu.com/16.04/ubuntu-16.04.6-desktop-amd64.iso) for the amd64 architecture
+ My machine had 4 GBytes of RAM available.  Less than 2 Gbytes will
  almost certainly not be enough.
+ My machine had at least 10 Gbytes of free disk space before the
  installation process started, on top of the approximately 4 Gbytes
  consumed by the fresh Ubuntu 16.04 installation, or the
  approximately 6 Gbytes consumed by the fresh Ubutu 18.04
  installation.  You should not need that much free disk space in
  order to succeed running these scripts, but you probably do want
  several Gbytes of free disk space after the installation is
  complete.
+ During the entire time my machine was running the installation
  script, it had good reliable access to the Internet.  Many of the
  steps in these scripts download packages from the Ubuntu package
  repositories, or use git to download source code from the Github.com
  web site.  Not all of these download attempts are at the beginning
  of the scripts -- some occur near the end of running the script.

Below are the commands I ran in a terminal window, after booting up
the fresh Ubuntu Linux installation.  Replace
`install-p4dev-p4runtime.sh` with `install-p4dev.sh` if you do not
want to install the P4Runtime software.

```
$ sudo apt install git
$ git clone https://github.com/jafingerhut/p4-guide
$ ./p4-guide/bin/install-p4dev-p4runtime.sh |& tee log.txt
```

The `|& tee log.txt` part of the command is not necessary for the
install to work.  It causes the output of the script to be saved to
the file `log.txt`, as well as appear in the terminal window.

If you want to see the output that I saw when running the last command
above on my system, perhaps to compare it to yours to see what
happened differently, you can find them [here](output/).
