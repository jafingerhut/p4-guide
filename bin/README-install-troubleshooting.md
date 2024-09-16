# Introduction

Pick one of these alternatives that best fits your situation:

(a) I have a freshly installed Linux system with one of the supported
    distributions and versions, and I want to install the open source
    P4 development tools on it.  (This might be a new VM created for
    this purpose.)

(b) I am comfortable downloading and running a virtual machine image
    with the P4 open source tools already compiled and installed,
    e.g. using a virtual machine application like VirtualBox, VMware
    Fusion, VMware Workstation, Parallels, etc.

If your answer is (a), see the section below [Quick instructions for
successful install script
run](#quick-instructions-for-successful-install-script-run).

If your answer is (b), there are several VM images with many of the
open source P4 development tools already installed available from
links in this table.  Each of them comes with a user account named
`p4` with password `p4` intended for use in developing P4 programs.
They also have a user account `vagrant` (password `vagrant`).

The "Development" VM images contain a copy of the source code from
which the P4 development tools were built in the home directory of the
'vagrant' user account.  If you know how, this source code can be
updated and compiled again.

The "Release" VM images are smaller, and contain only binaries of the
P4 development tools, installed via Debian packages, which can be
upgraded to more recent versions if such have been released.

| Date published | Operating system | Development VM Image link | Release VM Image link | README link | Tested working on macOS? | Tested working on Windows? |
| -------------- | ---------------- | ------------------------- | --------------------- | ----------- | ------------------------ | -------------------------- |
| 2024-Sep-02 | Ubuntu 24.04 | [2.4 GByte VM image](https://drive.google.com/file/d/1mUspxxo7sG0-omvnu6IJasKKSP0PVbCj/view?usp=drive_link) | no such VM created | -- | Combo24 | no |
| 2024-Aug-01 | Ubuntu 24.04 | [2.3 GByte VM image](https://drive.google.com/file/d/1GDL1Nu5DY8YIf7NBkQ5JazGlxCIBO4nY/view?usp=sharing) | no such VM created | [README](https://drive.google.com/file/d/1jwoFN9uqNjKz1tToHGEp_wz9AaYobFYr/view?usp=sharing) | Combo23 | no |
| 2024-Aug-01 | Ubuntu 20.04 | [3.0 GByte VM image](https://drive.google.com/file/d/1UakkQ-qGUzfv0INnmDcIWLCYvTuwpPGW/view?usp=sharing) | no such VM created | [README](https://drive.google.com/file/d/1_C0-No7mgVzzdYyngIlowPmwdns62p3f/view?usp=sharing) | Combo23 | no |
| 2024-Jul-04 | Ubuntu 24.04 | [2.3 GByte VM image](https://drive.google.com/file/d/1zY06ux9THW_iABKVmAcIT8S7WRvmbcaL/view?usp=drive_link) | no such VM created | [README](https://drive.google.com/file/d/1nzLOl2DR2fuI0TCUkI5SNJsaIpGDQBbR/view?usp=drive_link) | Combo23 | no |
| 2024-Jul-04 | Ubuntu 20.04 | [3.0 GByte VM image](https://drive.google.com/file/d/1-lb125xKvcyqSXzEVwF_Efbr_ZUzV4D7/view?usp=drive_link) | no such VM created | [README](https://drive.google.com/file/d/1o4FcS2fwZ8AQVCn4eeFtPcPd20fPv9jE/view?usp=drive_link) | Combo23 | no |
| 2024-Jan-01 | Ubuntu 20.04 | [2.8 GByte VM image](https://drive.google.com/file/d/1RAXXx-J9DJSyCq1JogEaVLrBW8zut0C0/view?usp=drive_link) | [2.2 GBytes VM image](https://drive.google.com/file/d/1N7n9O6dX2H5gdFUb4EDrbk2C13fGmWwp/view?usp=drive_link) | [README](https://drive.google.com/file/d/1R1gp0dcmquE9QVgH2hlXkqbtqIbQU4-1/view?usp=drive_link) | Combo21 | no |
| 2023-Jul-01 | Ubuntu 20.04 | [3.0 GByte VM image](https://drive.google.com/file/d/1JWq05uRe4hwk5DwhpeG_yGJaKP4xYrOi/view?usp=drive_link) | [2.4 GBytes VM image](https://drive.google.com/file/d/1Lxb0VCW0DY_jkPEMbHOzX6Ssp3YxFves/view?usp=drive_link) | [README](https://drive.google.com/file/d/1cIuM36CXvx2yrrpMCGRInKUY2vJSJyfk/view?usp=drive_link) | Combo18 | Combo19 |
| 2023-Jan-01 | Ubuntu 20.04 | [4.2 GByte VM image](https://drive.google.com/file/d/1uy5g0lHr1Cb0f9F-d5ujv44nZJepvI8S/view?usp=share_link) | [2.2 GBytes VM image](https://drive.google.com/file/d/1v5v1lbn6mfqywq0LuOFJJhGaY5ruSe1m/view?usp=share_link) | [README](https://drive.google.com/file/d/1A363Mp8TSl_e2GoTB0NGn0flkjM_-4qe/view?usp=share_link) | Combo12 | Combo13 |
| 2022-Jul-01 | Ubuntu 20.04 | [4.2 GByte VM image](https://drive.google.com/file/d/1A8g2o8vkpfakXenhf2iPFQDx3DCnVuCY/view?usp=sharing) | [2.4 GBytes VM image](https://drive.google.com/file/d/1LcXsGmnYA1ragDnezlFu5GafU2qMLt4C/view?usp=sharing) | [README](https://drive.google.com/file/d/16oTpLekqpQy_Ay3DGtHnDHojBOyM8THQ/view?usp=sharing) | Combo3 | Combo5 |
| 2022-Jan-01 | Ubuntu 20.04 | [4 GByte VM image](https://drive.google.com/file/d/1hFGucuUfpK8bbd0NZmP7s2cilDdDITha/view?usp=sharing) | [2 GBytes VM image](https://drive.google.com/file/d/1_E3V3DEpY2ES-wIWuyQ1lAJo9vK6zG_C/view?usp=sharing) | [README](https://drive.google.com/file/d/13kP8-ktfGVNmzLd_Og6ck3SjPwBLrCa8/view?usp=sharing) | Combo2 | Combo5 |
| 2021-Sep-12 | Ubuntu 20.04 | [4 GByte VM image](https://drive.google.com/file/d/1ZuEM4r_a4RLNq3D9Y3A1aqbiR3gFLE3z/view?usp=sharing) | (none) | [README](https://drive.google.com/file/d/16usydz9BrotG0wI5vToqJttsB4TWIcVg/view?usp=sharing) | Combo1 | Combo4 |

Version combinations I have used above for testing VM images:

| Combination id | Operating system | VM software |
| -------------- | ---------------- | ----------- |
| Combo1 | macOS 10.14.6 | VirtualBox 6.1.26 |
| Combo2 | macOS 10.14.6 | VirtualBox 6.1.30 |
| Combo3 | macOS 11.6.5 | VirtualBox 6.1.30 |
| Combo4 | Windows 10 Enterprise | VirtualBox 6.1.26 |
| Combo5 | Windows 10 Enterprise | VirtualBox 6.1.30 |
| Combo12 | macOS 12.6.x | VirtualBox 6.1.40 |
| Combo13 | Windows 11 Enterprise | VirtualBox 6.1.40 |
| Combo18 | macOS 12.6.x | VirtualBox 7.0.8 |
| Combo19 | Windows 11 Enterprise | VirtualBox 7.0.8 |
| Combo21 | macOS 12.7.x | VirtualBox 7.0.12 |
| Combo23 | macOS 12.7.x | VirtualBox 7.0.18 |
| Combo24 | macOS 12.7.x | VirtualBox 7.0.20 |



## Quick instructions for successful install script run

Start with:

+ an _unmodified_ _fresh_ installation of one of these supported
  operating systems:
  + Ubuntu 20.04, 22.04, 24.04
    + These have been most tested on x86_64 processors (also known as
      amd64), running either Windows or macOS (on an Intel-based Mac
      system), running an Ubuntu Linux VM inside of
      [VirtualBox](https://www.virtualbox.org).
    + In 2024 I began supporting aarch64 processor architectures (also
      known as arm64), at least Apple Silicon Macs with a VM created
      with one of these virtualization programs:
      + [UTM](https://mac.getutm.app)
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
  tried running in a folder that was loal only within the guest OS,
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

Historical notes:

+ Ubuntu 18.04 reached its [end of standard
  support](https://wiki.ubuntu.com/Releases) in April 2023.  I tested
  `install-p4dev-v4.sh` on Ubuntu 18.04 monthly until Feb 2023, and
  `install-p4dev-v6.sh` monthly until March 2023, but discontinued
  testing those combinations at that time.  They might continue
  working after that, but I have no plans to update those scripts to
  work on Ubuntu 18.04 after those dates.
+ Similarly Ubuntu 16.04 reached its end of standard support in April
  2021.  I tested the `install-p4dev-v2.sh` script on Ubuntu 16.04
  monthly until August 2021, but I do not plan to test it any longer.


## Which install script should I use?

I would recommend using `install-p4dev-v5.sh` if you are able to use
Ubuntu 20.04 on an x86_64 processor.  It requires the least disk
space, installs quickly, and it installs pre-compiled P4 development
tools from Debian packages that can be updated later to more recent
versions as they are published, if you wish.  Note: The source code
for behavioral-model and p4c that this installs tends to be up to 2-3
months older than the date when you install them.  If you really need
the latest version of these programs, use a different install script.

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
| install-p4dev-v8.sh | 24.04, 22.04, 20.04 | 20 GB | 200 mins |   2 GB | binary lib version varies by OS | binary lib varies by OS, Python grpcio package v1.51.3, or v1.59.3 on Ubuntu 24.04 | ~/p4dev-python-venv virtual environment |
| install-p4dev-v5.sh | 20.04        |  2 GB |   3 mins | 250 MB | v3.6.1  | v1.16.1 ? | System-wide directories, e.g. /usr/local/lib/python3.*/dist-packages |


The scripts in the next table below are no longer tested by me.  They
are listed here only for possible historical interest.

| Script | Versions of Ubuntu it was formerly tested on | Last tested | P4Runtime API support? | Mininet installed? | Uses Python3 only? | PTF installed? | Free disk space required | Time to run on 2019 MacBook Pro with VirtualBox | Data downloaded from Internet | protobuf | grpc |
| ------ | ------------------------------ | ----------- | ---------------------- | ------------------ | ------------------ | -------------- | ------------------------ | ----------------------------------------------- | ----------------------------- | -------- | ---- |
| install-p4dev-v7.sh | 22.04, 20.04 | 2024-Jun | yes | yes | yes | yes | 25 GB | 200 mins | 2 GB | v3.21.6 | v1.51.3 |
| install-p4dev-v6.sh | 22.04, 20.04 | 2024-Jun | yes | yes | yes | yes | 25 GB | 160 mins | 2 GB | v3.18.1 | v1.43.2 |
| install-p4dev-v4.sh | 20.04, 18.04 | 2023-Feb | yes | yes | yes | yes | 12 GB | 100 mins | 2 GB | v3.6.1 | v1.17.2 |
| install-p4dev-v3.sh | DO NOT USE | Not tested | -- | -- | -- | -- | -- | -- | -- | -- | -- |
| install-p4dev-v2.sh | 18.04, 16.04 | 18.04 in 2022-Mar, 16.04 in 2021-Aug | yes | yes | no, Python2 | no | 11 GB | 100 mins |   2 GB | v3.6.1 | v1.17.2 |
| install-p4dev-p4runtime.sh | 18.04, 16.04 | 2020-Mar | yes | yes | no, Python2 | no | 8.5 GB |  70 mins | ? | v3.2.0 | v1.3.2 |
| install-p4dev.sh | -- | 2019-Oct |  no |  no | no, Python2 | no |  5 GB |  40 mins | ? | v3.2.0 | not installed |


## Testing your installation

Note: Running any of the steps later in this section is completely
optional.  I run them in my monthly test of the install scripts, for
additional assurance that they are doing their jobs correctly.


### Run tests included with `p4c`

One way to test your installation is to run the `p4c` P4 compiler's
included tests, which will compile well over 1000 test P4 programs,
and for several hundred of them it also runs the compiled code on
`simple_switch` and checks that the right packets come out.

Starting from the directory where you ran the install script, enter
these commands in a terminal.  No superuser privileges are required.
```bash
$ cd p4c/build
$ make -j2 check |& tee out.txt
```

With the current install script, it is normal for about 500 of these
tests to fail.  Many of those will pass if you re-run them as the user
`root` with a command like this:

```bash
$ sudo PATH=${PATH} VIRTUAL_ENV=${VIRTUAL_ENV} ${P4GUIDE_SUDO_OPTS} make -j2 recheck |& tee out2.txt
```


### Send ping packets in the solution to `basic` exercise of `p4lang/tutorials` repository

A quick test is to try running the solution to the `basic` exercise in
the tutorials repository.  To do so, follow these steps:

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

Historical note: If you are trying to use versions of the install
script older than `install-p4dev-v4.sh` (no longer tested by me, so
use at your own risk of lost time trying to make things work), you may
need to use a version of the `p4lang/tutorials` repository at version
`4914893445ae24bd1fa3b4aeea4910eeb412f7de` or older (end of year
2020), since the next commit after that updated all Python code to
Python3, not Python2.

If you are using the `install-p4dev-v5.sh` or `install-p4dev-v6.sh`
script, that should install only Python3 packages, and should work
with the latest version of the `p4lang/tutorials` repository.


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
  
  In my testing, I installed Ubuntu Desktop Linux as a virtual machine
  using VirtualBox on a Mac running a relatively recent version of
  macOS as the host operating system.  Installing them as a virtual
  machine on a different host operating system, or on a bare machine,
  should also work.
+ My machine had 2 GBytes of RAM available.  Less than 2 Gbytes will
  almost certainly not be enough.


## Version of P4 tools installed in Release VM images

The version of the P4 tools compiled and included with the
"Development" VM images is always the latest version of the source
code available for that project on Github as of the date of the image,
for these projects:

+ p4c https://github.com/p4lang/p4c
+ behavioral-model https://github.com/p4lang/behavioral-model
+ PI https://github.com/p4lang/PI
+ ptf https://github.com/p4lang/ptf

The version of the P4 tools installed with the "Release" VM images is
the latest version of the Ubuntu 20.04 package published as of the
date of the release image, which can be an older version of the source
code, since the Ubuntu 20.04 packages do not have new versions
published as often as commits are made to the repositories above.

| Date published | Operating system | p4c version | behavioral-model version |
| -------------- | ---------------- | ----------- | ------------------------ |
| 2023-Jul-01 | Ubuntu 20.04 | SHA: 71a06fe 2023-Jun-02 | SHA: 7a8843ff 2023-May-17 |
| 2022-Nov-01 | Ubuntu 20.04 | SHA: 1576090 2022-Aug-02 | SHA: f745e1db 2022-Feb-10 |
| 2022-Mar-01 | Ubuntu 20.04 | SHA: a9aa5ff 2022-Feb-08 | SHA: c76a03c3 2022-Feb-08 |
| 2022-Feb-03 | Ubuntu 20.04 | SHA: b28fbbb 2021-Nov-23 | SHA: 2de095c7 This is not the SHA of any behavioral-model commit SHA in the main branch of its source repository |
