# Introduction


## Quick instructions for successful install script run

Start with an unmodified fresh installation of Ubuntu Linux 16.04 or
18.04, with at least 4 GB of RAM, at least 10 GB of free disk space,
and a reliable Internet connection that is up for the entire duration
of running the install script -- it will download approximately 1 to 2
GByte of data.

Then run the commands below in a terminal.  Note:
+ You may run the commands from any directory you wish -- I typically
  run it from the home directory of my account.  Whichever directory
  is your current directory when you start the script, is where new
  directories with names like `p4c`, `behavioral-model`, `protobuf`,
  `grpc`, etc. will be created.
+ I have only tried these install scripts when running as a normal
  user, i.e. not as the superuser `root`.  There are several `sudo`
  commands in the install script, some of which will prompt you to
  enter your password before the script can continue.  The only
  commands run as superuser are those that install files in
  system-wide directories such as `/usr/local/bin`.  This password
  prompting can occur multiple times during the execution of the
  script, so check it every 15 minutes or so until it is finished, to
  see if it is waiting for you to enter your password.
```
$ sudo apt install git
$ git clone https://github.com/jafingerhut/p4-guide
$ ./p4-guide/bin/install-p4dev-p4runtime.sh |& tee log.txt
```
Replace `install-p4dev-p4runtime.sh` with `install-p4dev.sh` or
`install-p4dev-v2.sh` if you prefer to use those install scripts
instead.  More details on the differences between them are in the next
section.

The `|& tee log.txt` part of the command is not necessary for the
install to work.  It causes the output of the script to be saved to
the file `log.txt`, as well as appear in the terminal window.  The
output is about 10,000 lines long on a good run, so saving it to a
file is good if you want to see what it did.


## Which install script should I use?

I would recommend using `install-p4dev-p4runtime.sh` if you have no
preferences.  See the differences below if you want to make a more
informed decision.

* The shell script
  [`install-p4dev-p4runtime.sh`](install-p4dev-p4runtime.sh)
  installs everything that the next on below does, plus
  `simple_switch_grpc`, which can use the P4Runtime API protocol to
  communicate with a controller (in addition to the older Thrift API).
* The older shell script [`install-p4dev.sh`](install-p4dev.sh)
  installs `simple_switch`, which uses the Thrift API protocol to
  communicate with a controller.  This install script does not install
  the software necessary to use the P4Runtime API.
* The newest shell script
  [`install-p4dev-v2.sh`](install-p4dev-v2.sh) is still fairly new
  and less tested than the ones above, so consider it "bleeding edge"
  for now.  It is like `install-p4dev-p4runtime.sh` in that it also
  installs `simple_switch_grpc` and P4Runtime software.
  `install-p4dev-v2.sh` installs more recent versions of Protobuf,
  Thrift, and gRPC libraries than the scripts above do.  It has been
  successfully run on all of Ubuntu 16.04, 18.04, and 19.10 systems,
  with good test results from running `p4c`'s included tests (which
  exercise little or none of the P4Runtime API code), and a basic
  "install a few table entries via the P4Runtime API in Python" hand
  test.


## Testing your installation

One way to test your installation is to run the `p4c` P4 compiler's
included tests, which will compile almost 1400 test P4 programs, and
for several hundred of them it also runs the compiled code on
`simple_switch` and checks that the right packets come out.

Starting from the directory where you ran the install script, enter
these commands in a terminal.  No superuser privileges are required.
```
$ cd p4c/build
$ make check
```


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
