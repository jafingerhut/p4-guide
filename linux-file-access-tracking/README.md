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

```bash
sudo execsnoop-bpfcc |& tee ~/out-files-accessed-during-p4c-build.txt
```

After that process has started, in another terminal:

```bash
~/p4-guide/bin/build-p4c.sh release full
```

Filtering out programs that are unrelated to the build:

```bash
F="out-files-accessed-during-p4c-build.txt"
egrep -v '\b(dbus-daemon|gnome-terminal|systemd-oomd|VBoxClient|VBoxService|Xorg)\b' $F | m
file-access-stats.py $F >| out2.txt

cat out2.txt | ./filter.sh
```
