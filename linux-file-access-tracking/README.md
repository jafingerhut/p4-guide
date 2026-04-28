# Introduction

This article is not specific to P4 at all.  It is only here because I
used these steps to determine which files in this repository were
actually _used_ when automated tests were run, vs. any files that were
never used at all, and should be considered for removal.

+ https://github.com/p4lang/p4c

The technique should work on any programs you want to run on Linux.
The particular steps here were tested on an Ubuntu 24.04 Linux system,
but they should work with at most small modifications on other Linux
distributions, too.


# Goal

Suppose you want to run some sequence of commands on Linux,
e.g. building the code in the `p4c` repository, and you want to know
_every_ file read and/or written by those commands.

The technique described below is close to achieving that.  It will
show all of those files, but also all other files accessed by other
running programs on the system, e.g. periodic background tasks, or
files accessed by the GUI window manager processes, etc.


# How to do it

In one terminal, start the program that will record all files accessed
by any process:

The value of `OPENSNOOP` used below varies depending upon Linux
distribution.  Examples from recent Ubuntu LTS releases include:

+ Ubuntu 22.04 program name: `opensnoop-bpfcc`
  + To install: `sudo apt install bpfcc-tools linux-headers-$(uname -r)`
+ Ubuntu 24.04 program name: `opensnoop`
  + To install: `sudo apt-get install libbpf-tools`
+ Ubuntu 26.04 program name: `opensnoop-libbpf`
  + To install: `sudo apt-get install libbpf-tools`

```bash
sudo ${OPENSNOOP} > out-files-opened.txt
```

Note: `opensnoop` prints normal output to stdout, but at unpredictable
times relative to printing those normal output lines it prints
messages like `Lost <number> events` to stderr.  The `Lost` messages
interfere with proper parsing of the stdout data if they are mingled
together, so it is best to keep them separate, e.g. by _not_ using
bash features that redirect stdout and stderr to the same place.

After that process has started, in another terminal:

```bash
~/p4-guide/bin/build-p4c.sh release full
```
or whatever sequence of commands instead of that one, that you wish to
know what files they open.

Filtering out programs that are unrelated to the build:

```bash
./file-access-stats.py out-files-opened.txt > tmp.txt
./filter.sh tmp.txt > files-accessed-during-cmds.txt
```

If you would like to know which of a given set of files were accessed,
and which were not, you can follow up with commands like below:

```
find /absolute/path/to/directory/of/interest \! -type d > full-paths-of-interest.txt
./files-accessed-from-list.py full-paths-of-interest.txt files-accessed-during-cmds.txt > annotated-full-paths-of-interest.txt
```
