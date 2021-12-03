# Introduction

Pick one of these alternatives that best fits your situation:

(a) I have a new Ubuntu 18.04, or 20.04 Linux system, and I want to
    install the open source P4 development tools on it.  (This might
    be a new VM created for this purpose.)

(b) I am comfortable downloading and running a virtual machine image
    with the P4 open source tools already compiled and installed,
    e.g. using a virtual machine application like VirtualBox, VMware
    Fusion, VMware Workstation, Parallels, etc.

If your answer is (a), see the section below "Quick instructions for
successful install script run".

If your answer is (b), there are several VM images with many of the
open source P4 development tools already installed available from
links in this table.  Each of them comes with a user account named
'p4' with password 'p4' intended for use in developing P4 programs.
They also have a user account 'vagrant' (password 'vagrant').

The "Development" VM images contain a copy of the source code from
which the P4 development tools were built in the home directory of the
'vagrant' user account.  If you know how, this source code can be
updated and compiled again.

The "Release" VM images are smaller, and contain only binaries of the
P4 development tools, installed via Debian packages, which can be
upgraded to more recent versions if such have been released.

| Date published | Operating system | Development VM Image link | Release VM Image link | README link | Tested working on macOS? | Tested working on Windows? |
| -------------- | ---------------- | ------------------------- | --------------------- | ----------- | ------------------------ | -------------------------- |
| 2021-Dec-03 | Ubuntu 20.04 | [4 GByte VM image](https://drive.google.com/file/d/1lq6CKGAiwENP4igWOvkm1Yt1od5AN988/view?usp=sharing) | [2 GBytes VM image](https://drive.google.com/file/d/1gcfDV5euOW-95x0Xq4R6m2WdKQ49_AY7/view?usp=sharing) | [README](https://drive.google.com/file/d/1rdMOTd2v5W54H5Hhm8JYJ23vbFEfH4vD/view?usp=sharing) | Yes, with macOS 10.14.6 and VirtualBox 6.1.26 | Yes, with Windows 10 Enterprise and VirtualBox 6.1.26 |
| 2021-Nov-01 | Ubuntu 20.04 | [4 GByte VM image](https://drive.google.com/file/d/1I4_VtoWIG87Pvm3cTcg2JHMmZAtR9wnd/view?usp=sharing) | (none) | [README](https://drive.google.com/file/d/1nHFU9wS7AnN8y4mPPV_JwVOvUubk1Bis/view?usp=sharing) | Yes, with macOS 10.14.6 and VirtualBox 6.1.26 | Yes, with Windows 10 Enterprise and VirtualBox 6.1.26 |
| 2021-Oct-01 | Ubuntu 20.04 | [4 GByte VM image](https://drive.google.com/file/d/1QBbht4npEHfw4Fxvv3id_w8gCPFZBmwm/view?usp=sharing) | (none) | [README](https://drive.google.com/file/d/1zHVnMw4u-HUVPZid2XnvNFsNGqy2liqp/view?usp=sharing) | Yes, with macOS 10.14.6 and VirtualBox 6.1.26 | Yes, with Windows 10 Enterprise and VirtualBox 6.1.26 |
| 2021-Sep-12 | Ubuntu 20.04 | [4 GByte VM image](https://drive.google.com/file/d/1ZuEM4r_a4RLNq3D9Y3A1aqbiR3gFLE3z/view?usp=sharing) | (none) | [README](https://drive.google.com/file/d/16usydz9BrotG0wI5vToqJttsB4TWIcVg/view?usp=sharing) | Yes, with macOS 10.14.6 and VirtualBox 6.1.26 | Yes, with Windows 10 Enterprise and VirtualBox 6.1.26 |
| 2021-Jul-07 | Ubuntu 20.04 | [4 GByte VM image](https://drive.google.com/file/d/1L0Yc6QOyXNNzEIZyFixcDKlnTl9tC6MA/view?usp=sharing) | (none) | [README](https://drive.google.com/file/d/1xTsj4pMjLYOsMH1TkugEZvu1kDBFxu7J/view?usp=sharing) | Yes, with macOS 10.14.6 and VirtualBox 6.1.26 | Not tested by me. |
| 2021-Jun-01 | Ubuntu 20.04 | [4 GByte VM image](https://drive.google.com/file/d/1ZkE5ynJrASMC54h0aqDwaCOA0I4i48AC/view?usp=sharing) | (none) | (none) | Yes, with macOS 10.14.6 and VirtualBox 6.1.26 | Not tested by me. |


## Quick instructions for successful install script run

Note: Ubuntu 16.04 reached its [end of standard support in April
2021](https://wiki.ubuntu.com/Releases).  I tested the
`install-p4dev-v2.sh` script on Ubuntu 16.04 monthly until August
2021, and it worked fine up to that date, but I do not plan to test it
any longer.  It may continue to work for a significant length of time.

Start with:

+ an _unmodified_ _fresh_ installation of Ubuntu Linux 18.04 or 20.04,
  with ...
  + at least 2 GB of RAM (4 GB recommended)
  + at least 12 GB of free disk space (not 12 GB of disk space total
    for the VM, but 12 GB free disk space after the OS has been
    installed), and
  + a reliable Internet connection that is up for the entire duration
    of running the install script -- it will download approximately 1
    to 2 GByte of data.

If you use the latest `install-p4dev-v5.sh` script (supported only for
Ubuntu 20.04), you need only 2.5 GB of free disk space, and about 250
MByte of data will be downloaded from the Internet.  See the table
below for more details.

Note: These scripts have been reported NOT WORKING on WSL (Windows
Subsystem for Linux).  I have had success running supported versions
of Ubuntu Linux using VirtualBox on both macOS and Windows 10 hosts.

Then run the commands below in a terminal.  Note:
+ You may run the commands from any directory you wish -- I typically
  run it from the home directory of my account.  Whichever directory
  is your current directory when you start the script, is where new
  directories with names like `p4c`, `behavioral-model`, `protobuf`,
  `grpc`, etc. will be created.
+ I have only tried these install scripts when running as a normal
  user, i.e. not as the superuser `root`.  There are several `sudo`
  commands in the install script.  I have tried to write this script
  so that you should be prompted to enter your password once very soon
  after you start the script, and then never need to enter it again
  while the script runs.  The only commands run as superuser are those
  that install files in system-wide directories such as
  `/usr/local/bin`.
```bash
$ sudo apt install git
$ git clone https://github.com/jafingerhut/p4-guide
$ ./p4-guide/bin/install-p4dev-v4.sh |& tee log.txt
```
Replace `install-p4dev-v4.sh` with `install-p4dev-v5.sh` if you prefer
it instead.  More details on the differences between them are in the
next section.

The `|& tee log.txt` part of the command is not necessary for the
install to work.  It causes the output of the script to be saved to
the file `log.txt`, as well as appear in the terminal window.  The
output is about 10,000 lines long on a good run, so saving it to a
file is good if you want to see what it did.


## Which install script should I use?

I would recommend using `install-p4dev-v5.sh` if you are able to use
Ubuntu 20.04.  It requires the least disk space, installs quickly, and
it installs pre-compiled P4 development tools from Debian packages
that can be updated later to more recent versions as they are
published, if you wish.

If you prefer Ubuntu 18.04, then I would recommend
`install-p4dev-v4.sh`.

If you wish to run the examples in the
[tutorials](https://github.com/p4lang/tutorials) repository as of
2021, you need P4Runtime API support and Mininet.

See the table below if you want to make a more informed decision.

| Script | Versions of Ubuntu it works on | Last tested | P4Runtime API support? | Mininet installed? | Uses Python3 only? | Free disk space required | Time to run on 2015 MacBook Pro with VirtualBox | Data downloaded from Internet |
| ------ | ------------------------------ | ----------- | ---------------------- | ------------------ | ------------------ | ------------------------ | ----------------------------------------------- | ----------------------------- |
| install-p4dev-v5.sh | 20.04        | Monthly through 2021 | yes | yes | yes |  2 GB |   3 mins | 250 MB |
| install-p4dev-v4.sh | 20.04, 18.04 | Monthly through 2021 | yes | yes | yes | 12 GB | 100 mins |   2 GB |
| install-p4dev-v3.sh | DO NOT USE | Not tested | -- | -- | -- | -- | -- | -- |
| install-p4dev-v2.sh | 18.04, 16.04 | 18.04 monthly through 2021, 16.04 in 2021-Aug | yes | yes | no, Python2 | 11 GB | 100 mins |   2 GB |
| install-p4dev-p4runtime.sh | 18.04, 16.04 | 2020-Mar | yes | yes | no, Python2 | 8.5 GB |  70 mins | ? |
| install-p4dev.sh | -- | 2019-Oct |  no |  no | no, Python2 |  5 GB |  40 mins | ? |


## Testing your installation


### Run tests included with `p4c`

One way to test your installation is to run the `p4c` P4 compiler's
included tests, which will compile well over 1000 test P4 programs,
and for several hundred of them it also runs the compiled code on
`simple_switch` and checks that the right packets come out.

Starting from the directory where you ran the install script, enter
these commands in a terminal.  No superuser privileges are required.
```bash
$ cd p4c/build
$ make -j2 check |& tee make-check-out.txt
```

With the current install script, it is normal for about 50 of these
tests to fail.  The only ones that are expected to fail are for the
EBPF and UBPF targets.  If someone is interested in using `p4c` for
those targets, they will need to learn how to do so (suggested
modifications to enable this for my scripts are welcome, but I am not
interested in investigating this myself).

If you have saved the output of the `make` command in a file as
suggested above, the output of the last `wc -l` command in the command
pipeline below should print 0, indicating that the only failures were
in the EBPF and UBPF tests.

```bash
$ grep '(Failed)' make-check-out.txt | grep -v ' ebpf/' | grep -v ' ubpf/' | grep -v ' ebpf-bcc/' | wc -l
0
```

These tests exercise many corner cases of the `p4c` compiler.  The
tests with `bmv2/` at the beginning of their names run the
`simple_switch` process, adding table entries using the Thrift API
(not P4Runtime).


### Send ping packets in the solution to `basic` exercise of `p4lang/tutorials` repository

NOTE: If you are using versions of the install script older than
`install-p4dev-v4.sh`, you may need to use a version of the
`p4lang/tutorials` repository at version
`4914893445ae24bd1fa3b4aeea4910eeb412f7de` or older (end of year
2020), since the next commit after that updated all Python code to
Python3, not Python2.

If you are using the `install-p4dev-v4.sh` script, that should install
only Python3 packages, and should work with the latest version of the
`p4lang/tutorials` repository.

Another quick test is to try running the solution to the `basic`
exercise in the tutorials repository.  To do so, follow these steps:

```bash
$ git clone https://github.com/p4lang/tutorials
$ cd tutorials/exercises/basic
$ cp solution/basic.p4 basic.p4
$ make run
```

If at the end of many lines of logging output you see a prompt
`mininet>`, you can try entering the command `h1 ping h2` to ping from
virtual host `h1` in the exercise to `h2`, and it should report a
successful ping every second.  It will not stop on its own.  You can
type Control-C to stop it and return to the `mininet>` prompt, and you
can type Control-D to exit from mininet and get back to the original
shell prompt.

You may restore the modified `basic.p4` program back to its original
contents with the command:

```bash
$ git checkout basic.p4
```

This test exercises at least `p4c` for the v1model architecture,
`simple_switch_grpc`, and a portion of the P4Runtime API
implementation in `simple_switch_grpc` for adding table entries.


## Details

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
  VirtualBox on a Mac running macOS 10.14 Mojave as the host operating
  system, but installing them as a virtual machine on a different host
  operating system, or on a bare machine, should also work:
  + [Ubuntu Desktop 20.04.3](http://releases.ubuntu.com/20.04/ubuntu-20.04.3-desktop-amd64.iso) for the amd64 architecture
  + [Ubuntu Desktop 18.04.6](http://releases.ubuntu.com/18.04/ubuntu-18.04.6-desktop-amd64.iso) for the amd64 architecture
  + [Ubuntu Desktop 16.04.7](http://releases.ubuntu.com/16.04/ubuntu-16.04.7-desktop-amd64.iso) for the amd64 architecture
+ My machine had 2 GBytes of RAM available.  Less than 2 Gbytes will
  almost certainly not be enough.
