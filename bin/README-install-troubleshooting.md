# Introduction

Pick one of these alternatives that best fits your situation:

(a) I have a freshly installed Linux system with one of the supported
    distributions and versions, and I want to install the open source
    P4 development tools on it.  (This might be a new VM created for
    this purpose.)

(b) I have a system with a 64-bit Intel/AMD processor, or an Apple
    Silicon Mac, and I am comfortable downloading and running a
    virtual machine image with the P4 open source tools already
    compiled and installed, e.g. using the virtual machine application
    VirtualBox.

If your answer is (a), see the section below [Quick instructions for
successful install script
run](#quick-instructions-for-successful-install-script-run).

If your answer is (b), there are several VM images with many of the
open source P4 development tools already installed available from
links in this table.  Each of them comes with a user account named
`p4` with password `p4` intended for use in developing P4 programs.

All VM images contain a copy of the source code from which the P4
development tools were built in the home directory of the 'p4'
user account.  If you know how, this source code can be updated and
compiled again.

| Date published | Operating system | x86_64 VM Image link | Tested working on x86_64 Windows? | aarch64 VM Image link | Tested working on Apple Silicon macOS? |
| -------------- | ---------------- | -------------------- | --------------------- | ------------------------ | -------------------------- |
| 2025-Mar-01 | Ubuntu 24.04 | [5.4 GByte VM image](https://drive.google.com/file/d/1Khfsugub0Ar_eI-uxBsswbbnJMIcNZ4k/view?usp=sharing) | Combo26 | [4.6 GByte VM image](https://drive.google.com/file/d/1Joky3wfAyA0zz9GqCdNhjGA9eVRr2Ibe/view?usp=sharing) | Combo27 |
| 2025-Feb-01 | Ubuntu 24.04 | [5.2 GByte VM image](https://drive.google.com/file/d/13_D4c3WWilJKPjyioOM7Ie5ZFXV-xT4S/view?usp=sharing) | Combo26 | no such VM created | -- |
| 2025-Jan-01 | Ubuntu 24.04 | [4.5 GByte VM image](https://drive.google.com/file/d/14DI0Ovnn2eo3boFewWHg83xnhtF1jKjK/view?usp=sharing) (first image released with Ubuntu GNOME desktop) | Combo26 | no such VM created | -- |

If you are looking for a VM image built in 2024 or earlier, see [this
page](older-images.md).

Version combinations I have used above for testing VM images:

| Combination id | Operating system | VM software |
| -------------- | ---------------- | ----------- |
| Combo26 | Windows 11 Pro | VirtualBox 7.1.4 |
| Combo27 | macOS 14.7.x | VirtualBox 7.1.6 |


## Quick instructions for successful install script run

Start with:

+ an _unmodified_ _fresh_ installation of one of these supported
  operating systems:
  + Ubuntu 20.04, 22.04, 24.04
    + These have been most tested on x86_64 processors (also known as
      amd64), running either Windows or macOS (on an Intel-based Mac
      system), running an Ubuntu Linux VM inside of
      [VirtualBox](https://www.virtualbox.org).
      + See
        [here](https://github.com/jafingerhut/jafingerhut.github.com/blob/master/notes/macos-virtualbox-ubuntu-install-notes.md)
        for instructions I have successfully followed in creating
        Ubuntu Linux VMs within VirtualBox.
    + In 2024 I began supporting aarch64 processor architectures (also
      known as arm64), at least Apple Silicon Macs with a VM created
      with one of these virtualization programs:
      + [UTM](https://mac.getutm.app) - See
        [here](https://github.com/jafingerhut/jafingerhut.github.com/blob/master/notes/macos-utm-notes.md)
        for instructions on creating an Ubuntu Linux VM within UTM
        that have worked for me.
      + [VirtualBox](https://www.virtualbox.org), which now has Beta
        level support for Apple Silicon Macs starting with version
        7.1.0.
  + Fedora Linux
    + Only a few Fedora releases are supported by the older
      `install-p4dev-v6.sh` and `install-p4dev-v7.sh` scripts, no
      longer tested by me.  You can search for `fedora` in these
      scripts to see which versions of Fedora they support.
    + To get a copy of older Fedora releases, see one of these places:
      + [fedoraproject.org releases](https://archives.fedoraproject.org/pub/archive/fedora/linux/releases)
	  + [dl.fedoraproject.org releases](https://dl.fedoraproject.org/pub/fedora/linux/releases/)
+ The system must have:
  + at least 2 GB of RAM (4 GB recommended)
  + at least 25 GB of free disk space (not 25 GB of disk space total
    for the VM, but 25 GB free disk space after the OS has been
    installed), and
  + a reliable Internet connection that is up for the entire duration
    of running the install script -- it will download approximately 2
    to 3 GByte of data.

If you use the `install-p4dev-v5.sh` script (supported only for Ubuntu
20.04 on x86_64 systems), you need only 3 GB of free disk space, and
about 250 MByte of data will be downloaded from the Internet.  See the
table below for more details.

Note: These scripts have been reported NOT WORKING on WSL (Windows
Subsystem for Linux).  I have had success running supported versions
of Ubuntu Linux using VirtualBox on these host operating systems:

+ macOS 10.14.x
+ macOS 10.15.x
+ macOS 12.6.x
+ macOS 13.6.x
+ macOS 14.6.x
+ Windows 10
+ Windows 11

Then run the commands below in a terminal.  Note:
+ You may run the commands from any directory you wish -- I typically
  run it from the home directory of my account.  Whichever directory
  is your current directory when you start the script, is where new
  directories with names like `p4c`, `behavioral-model`, `mininet`,
  `grpc`, etc. will be created.  I have heard a report from someone
  using this that in a VM where they created a shared folder between
  the guest OS and the host OS, and tried to run one of the install
  scripts in that directory, it failed.  It worked when they later
  tried running in a folder that was only within the guest OS,
  which is the only way I have ever tested this script myself, and
  thus strongly recommend.
+ I have only tried these install scripts when running as a normal
  user, i.e. not as the superuser `root`.  There are several `sudo`
  commands in the install script.  I have tried to write this script
  so that you should be prompted to enter your password once very soon
  after you start the script, and then never need to enter it again
  while the script runs.  The only commands run as superuser are those
  that install files in system-wide directories such as
  `/usr/local/bin`.

```bash
$ sudo apt install git     # For Ubuntu
$ sudo dnf install git     # For Fedora
$ git clone https://github.com/jafingerhut/p4-guide
$ ./p4-guide/bin/install-p4dev-v8.sh |& tee log.txt

# If you used v8 version of the install script, see Note 1 below.
```

Replace the `v8` in `install-p4dev-v8.sh` with `v5` if you prefer to
use that version.  More details on the differences between them are in
the next section.

The `|& tee log.txt` part of the command is not necessary for the
install to work.  It causes the output of the script to be saved to
the file `log.txt`, as well as appear in the terminal window.  The
output is about 10,000 lines long on a good run, so saving it to a
file is good if you want to see what it did.

Note 1: If you use `install-p4dev-v8.sh` and use `bash` as your
command shell (the default on Ubuntu and Fedora Linux), you should
execute the command `source p4setup.bash` in every `bash` shell where
you wish to run the P4 development tools.  You can add the `source
p4setup.bash` line to your `$HOME/.bashrc` file, so that it will
automatically be run for you in any new `bash` shell you create.


## Which install script should I use?

I would recommend using `install-p4dev-v8.sh` as shown in the example
commands above.  It does take a significant amount of time to install,
and a decent amount of disk space.  However, `install-p4dev-v5.sh`
installs pre-compiled binaries last updated in Aug 2023, and it is not
clear whether anyone will ever take the effort required to update
them to a more recent version.

Minor note: As of 2023-Jan when I updated the PTF tests in this
p4-guide repository to use p4runtime-shell as the Python API for table
add/delete/modify, a system that results from running
`install-p4dev-v5.sh` can run the exercises in the p4lang/tutorials
repository, but does not have the `p4runtime-shell` package installed,
so cannot run the PTF tests in the p4-guide repository.  If you
install `p4runtime-shell` system-wide, you can then run the PTF tests
in the p4-guide repository, but then the exercises in p4lang/tutorials
fail to run, probably because of some conflict in how the Python
packages are installed.  This can probably be worked around by using
Python virtual environments, but I have not tested this.  A system
installed using any other version of the install script does not have
this issue.

All of the current install scripts install everything required to
enable you to run the examples in the
[tutorials](https://github.com/p4lang/tutorials) repository, since
2021.

See the tables below if you want to make a more informed decision.

The scripts in the next table below have all been tested monthly
through 2024.  They all include the following:

+ [P4Runtime API support](https://github.com/p4lang/p4runtime)
+ [Mininet](http://mininet.org)
+ [PTF](https://github.com/p4lang/ptf)
+ [p4runtime-shell](https://github.com/p4lang/p4runtime-shell)
+ Uses Python3 only, no Python2 installed

| Script | Versions of Ubuntu it works on | Free disk space required | Time to run on 2019 MacBook Pro with VirtualBox | Data downloaded from Internet | protobuf | grpc | Where are Python3 packages installed? |
| ------ | ------------------------------ | ------------------------ | ----------------------------------------------- | ----------------------------- | -------- | ---- | ------------------------------------- |
| install-p4dev-v8.sh | 24.04, 22.04, 20.04 | 22 GB | 120 mins |   2 GB | binary lib version varies by OS | binary lib varies by OS, Python grpcio package v1.51.3, or v1.59.3 on Ubuntu 24.04 | ~/p4dev-python-venv virtual environment |
| install-p4dev-v5.sh | 20.04        |  2 GB |   3 mins | 250 MB | v3.6.1  | v1.16.1 ? | System-wide directories, e.g. /usr/local/lib/python3.*/dist-packages |


## Other details

I have moved many details that are only for running additional tests,
and notes of historical interest, to a separate article.  If you have
installed a working system from the instructions above, there is _NO
REASON_ to read the other article.  You are good to go without ever
having to read it.

If you understand that, that other article is
[here](testing-history-and-other-details.md).

