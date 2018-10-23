# Linux kernel issue where it adds extra bytes at end of packet

The program `test-veth-intf.py` can be run as the superuser to test
whether the Linux kernel you are running modifies packets sent to a
veth interface:

    sudo ../bin/test-veth-intf.py


p4lang/behavioral-model issue: https://github.com/p4lang/behavioral-model/issues/650

Link to Ubuntu page with a bug report: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1782544

Page I found with instructions to change kernel versions on Ubuntu
and similar Linux distributions using an application called `ukuu`:
https://itsfoss.com/upgrade-linux-kernel-ubuntu/

Note that when running VirtualBox on a Mac, at least, you have a
narrow window of time for pressing the Escape key during Ubuntu boot,
very shortly after the Oracle splash screen disappears, in order to
cause the Grub menu to display that lets you (under the Advanced
options) pick an installed version of the kernel to use for booting.


Test results: BAD+14 means that the test results were bad, and bad
because the captured packet was the same as the packet sent, plus 14
extra bytes appended at the end.

Kernel version: As output by the `uname -r` command.

| Test Results | Kernel version | Distribution | Notes |
| ------------ | -------------- | ------------ | ----- |
| GOOD    | 4.4.0-31-generic        | Ubuntu 14.04.5 | |
| GOOD    | 4.4.0-116-generic       | Ubuntu 14.04 ? | from Edgar Costa |
| GOOD    | 4.4.0-127-generic       | Ubuntu 14.04.5 | |
| GOOD    | 4.4.0-128-generic       | Ubuntu 14.04.5 | |
| BAD+14  | 4.4.0-130-generic       | Ubuntu 14.04.5 | |
| BAD+14  | 4.4.0-131-generic       | Ubuntu 14.04 ? | from Edgar Costa |
| BAD+14  | 4.4.0-131-generic       | Ubuntu 14.04.5 | |
| BAD+14  | 4.4.0-133-generic       | Ubuntu 14.04.5 | |
| GOOD    | 4.4.0-134-generic       | Ubuntu 14.04.5 | |
| GOOD    | 4.4.0-135-generic       | Ubuntu 14.04.5 | |
| GOOD    | 4.4.142-0404142-generic | Ubuntu 16.04 ? | from Edgar Costa, maybe installed via ukuu? |
| GOOD    | 4.14.68-041468-generic  | Ubuntu 16.04.5 | installed via ukuu |
| GOOD    | 4.15.0-041500-generic   | Ubuntu 16.04.5 | installed via ukuu |
| GOOD    | 4.15.0-15-generic       | Ubuntu 16.04.5 | installed from Ubuntu via synaptic |
| GOOD    | 4.15.0-24-generic       | Ubuntu 16.04.5 | installed from Ubuntu via synaptic |
| GOOD    | 4.15.0-29-generic       | Ubuntu 16.04.5 | installed from Ubuntu via synaptic |
| GOOD    | 4.15.0-30-generic       | Ubuntu 16.04.5 | installed from Ubuntu via synaptic |
| GOOD    | 4.15.0-32-generic       | Ubuntu 16.04.5 or Ubuntu 18.04.1 | installed from Ubuntu via synaptic |
| BAD+14  | 4.15.0-33-generic       | Ubuntu 16.04.5 or Ubuntu 18.04.1 | installed from Ubuntu via Software Updater |
| BAD+14  | 4.15.0-34-generic       | Ubuntu 16.04.5 or Ubuntu 18.04.1 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-36-generic       | Ubuntu 16.04.5 or Ubuntu 18.04.1 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-38-generic       | Ubuntu 16.04.5 or Ubuntu 18.04.1 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.1-041501-generic   | Ubuntu 16.04.5 | installed via ukuu |
| GOOD    | 4.15.18-041518-generic  | Ubuntu 16.04.5 | installed via ukuu |
| GOOD    | 4.16.18-041618-generic  | Ubuntu 16.04.5 | installed via ukuu |
