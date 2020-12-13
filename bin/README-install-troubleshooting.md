# Introduction


## Quick instructions for successful install script run

Start with:

+ an _unmodified_ _fresh_ installation of Ubuntu Linux 16.04 or 18.04,
  with ...
  + at least 2 GB of RAM (4 GB recommended)
  + at least 12 GB of free disk space (not 12 GB of disk space total
    for the VM, but 12 GB free disk space after the OS has been
    installed), and
  + a reliable Internet connection that is up for the entire duration
    of running the install script -- it will download approximately 1
    to 2 GByte of data.

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
+ The script requires several other files in this repository to be
  present, at least some files in the `bin/patches` directory.  If you
  copy only the script to another system, it will fail.
```bash
$ sudo apt install git
$ git clone https://github.com/jafingerhut/p4-guide
$ ./p4-guide/bin/install-p4dev-v2.sh |& tee log.txt
```
Replace `install-p4dev-v2.sh` with `install-p4dev-p4runtime.sh` if you
prefer it instead.  More details on the differences between them are
in the next section.

The `|& tee log.txt` part of the command is not necessary for the
install to work.  It causes the output of the script to be saved to
the file `log.txt`, as well as appear in the terminal window.  The
output is about 10,000 lines long on a good run, so saving it to a
file is good if you want to see what it did.


## Which install script should I use?

I would recommend using `install-p4dev-v2.sh` if you have no
preferences.  See the differences below if you want to make a more
informed decision.

* The script [`install-p4dev-v2.sh`](install-p4dev-v2.sh)
  installs `p4c`, `behavioral-model` `simple_switch`, plus
  `simple_switch_grpc`, that can use the P4Runtime API protocol to
  communicate with a controller (in addition to the older Thrift API).
  It also installs Mininet and a few other small packages that enable
  you to run the exercises in the master branch of the
  [tutorials](https://github.com/p4lang/tutorials) repository.  It
  uses the latest versions of the Protobuf, Thrift, and gRPC libraries
  that are supported by the open source P4 development tools.  It has
  been successfully run on Ubuntu 16.04 and 18.04 systems, with good
  test results from running `p4c`'s included tests (which exercise
  little or none of the P4Runtime API code), and running the basic
  exercise in the [tutorials](https://github.com/p4lang/tutorials)
  repository.
* The script
  [`install-p4dev-p4runtime.sh`](install-p4dev-p4runtime.sh) is nearly
  identical to `install-p4dev-v2.sh`, except it uses slightly older
  versions of the Protobuf, Thrift, and gRPC libraries, that were
  until some time during 2019 the latest supported versions.
* The newest script
  [`install-p4dev-v4.sh`](install-p4dev-v4.sh) is based on
  `install-p4dev-v2.sh`, but has several changes enabling it to work
  on Ubuntu 20.04 Linux systems.  Ubuntu 20.04 has Python3 installed
  by default, but does not have Python2 installed by default.  The
  `install-p4dev-v4.sh` script tries to only install Python3 modules,
  and in fact it will not install Python2 at all except very near the
  end, because the install script for Mininet causes Python2 to be
  installed still.  See below 
* The older shell script [`install-p4dev.sh`](install-p4dev.sh) does
  not install anything unless you edit it.  The messages that appear
  when you run it explain why, and how to change it if you really want
  to run it despite its limitations.  This script does _not_ install
  the software necessary to use the P4Runtime API, and thus is
  insufficient by itself to enable you to run the exercises in August
  2019 or later versions of the
  [tutorials](https://github.com/p4lang/tutorials) repository.


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

If you have saved the output of the `make` command output in a file as
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

NOTE: If you are using Ubuntu 20.04 and the `install-p4dev-v4.sh`
script, the latest `tuturials` code as of 2020-Dec still assumes there
are more Python2 P4-related modules installed, or else most things
fail.  There is an _EXPERIMENTAL_ patch to the `p4lang/tutorials` code
(meaning it could still have many bugs) in the file
`p4-guide/bin/patches/tutorials-python3-changes1.patch` that enables
at least the test described below to work on such a system.  You can
apply it by using the command `patch -p1 <
tutorials-python3-changes1.patch` when inside the `tutorials`
directory after cloning the tutorials repository, if you wish to try
it out.

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
  VirtualBox on a Mac running macOS 10.13 High Sierra as the host
  operating system, but installing them as a virtual machine on a
  different host operating system, or on a bare machine, should also
  work:
  + [Ubuntu Desktop 18.04.3](http://releases.ubuntu.com/18.04/ubuntu-18.04.3-desktop-amd64.iso) for the amd64 architecture
  + [Ubuntu Desktop 16.04.6](http://releases.ubuntu.com/16.04/ubuntu-16.04.6-desktop-amd64.iso) for the amd64 architecture
+ My machine had 4 GBytes of RAM available.  Less than 2 Gbytes will
  almost certainly not be enough.
