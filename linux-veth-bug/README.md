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
| GOOD    | 4.15.0-39-generic       | Ubuntu 16.04.5 or Ubuntu 18.04.1 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-42-generic       | Ubuntu 16.04.5 or Ubuntu 18.04.1 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-43-generic       | Ubuntu 16.04.5 or Ubuntu 18.04.1 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-44-generic       | Ubuntu 18.04.1 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-45-generic       | Ubuntu 16.04.5 or Ubuntu 18.04.1 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-46-generic       | Ubuntu 16.04.5 or Ubuntu 18.04.1 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-47-generic       | Ubuntu 16.04.6 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-50-generic       | Ubuntu 16.04.6 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-51-generic       | Ubuntu 16.04.6 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-52-generic       | Ubuntu 16.04.6 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-54-generic       | Ubuntu 16.04.6 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.0-55-generic       | Ubuntu 16.04.6 | installed from Ubuntu via Software Updater |
| GOOD    | 4.15.1-041501-generic   | Ubuntu 16.04.5 | installed via ukuu |
| GOOD    | 4.15.18-041518-generic  | Ubuntu 16.04.5 | installed via ukuu |
| GOOD    | 4.16.18-041618-generic  | Ubuntu 16.04.5 | installed via ukuu |
| GOOD    | 4.18.0-14-generic       | Ubuntu 18.10 | installed from Ubuntu via Software Updater |
| GOOD    | 4.18.0-16-generic       | Ubuntu 18.04.2 | installed from Ubuntu via Software Updater |
| GOOD    | 4.18.0-17-generic       | Ubuntu 18.04.2 | installed from Ubuntu via Software Updater |
| GOOD    | 4.18.0-18-generic       | Ubuntu 18.04.2 | installed from Ubuntu via Software Updater |
| GOOD    | 4.18.0-20-generic       | Ubuntu 18.04.2 | installed from Ubuntu via Software Updater |
| GOOD    | 4.18.0-21-generic       | Ubuntu 18.04.2 | installed from Ubuntu via Software Updater |
| GOOD    | 4.18.0-22-generic       | Ubuntu 18.04.2 | installed from Ubuntu via Software Updater |
| GOOD    | 4.18.0-24-generic       | Ubuntu 18.04.2 | installed from Ubuntu via Software Updater |
| GOOD    | 5.0.0-23-generic        | Ubuntu 18.04.3 | installed from Ubuntu via Software Updater |


# What do Linux veth interfaces combined with Scapy do with short packets?

Run the following test program.  Note: this Python program does not
create and remove veth interfaces while it runs, but assumes that
`veth0` and `veth1` have already been created and configured in the
way that the `veth_setup.sh` script does, before it starts.  The
reason is that it enables one to start a monitoring program like
Wireshark or tcpdump on those interfaces before the test program
begins.

    sudo ../bin/veth_setup.sh

    # tcpdump is optional, and if run, should be done in separate
    # terminal windows from the test program below.
    sudo tcpdump -xx -e -n --number -v -i veth0
    sudo tcpdump -xx -e -n --number -v -i veth1

    sudo ../bin/test-veth-pkt-lengths-py3.py

Below are the results I saw using these software versions:

+ Ubuntu 18.04.5 Desktop Linux
+ Linux kernel 5.4.0-58-generic
+ Python 3.6.9
+ Scapy 2.4.3 (installed using `sudo pip3 install scapy`)

```
$ sudo ../bin/test-veth-pkt-lengths-py3.py
Creating interface 'veth0' with peer 'veth1'...
Device "veth0" does not exist.
Error status 1 while trying to show the interface
Configuring interface 'veth0'
Configuring interface 'veth1'
Interface creation done.
Length 14 bytes - no exception calling Ether(b)
Length 15 bytes - no exception calling Ether(b)
Length 42 bytes - no exception calling Ether(b)
Length 13 bytes - EXCEPTION calling Ether(b)
<class 'struct.error'>
Length  4 bytes - EXCEPTION calling Ether(b)
<class 'struct.error'>
Length  0 bytes - no exception calling Ether(b)
sniff start
.
Sent 1 packets.
.
Sent 1 packets.
.
Sent 1 packets.
.
Sent 1 packets.
.
Sent 1 packets.
.
Sent 1 packets.
sniff stop returned 6 packet
Packet(s) sent to interface 'veth0':
 1 len  14 00cafed00d0f00deadbeeffa0800
 2 len  15 00cafed00d0f00deadbeeffa080045
 3 len  42 00cafed00d0f00deadbeeffa08004500001c0001000040117cce7f0000017f0000010035003500080172
 4 len  13 00cafed00d0f00deadbeeffa08
 5 len   4 00cafed0
 6 len   0 
Number of captured packets on interface 'veth0': 6
 1 len  14 00cafed00d0f00deadbeeffa0800
 2 len  15 00cafed00d0f00deadbeeffa080045
 3 len  42 00cafed00d0f00deadbeeffa08004500001c0001000040117cce7f0000017f0000010035003500080172
 4 len  60 00cafed00d0f00deadbeeffa080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
 5 len  60 00cafed00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
 6 len  60 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

output of 'uname -a' command:
b'Linux andy-vm 5.4.0-58-generic #64~18.04.1-Ubuntu SMP Wed Dec 9 17:11:11 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux'
output of 'uname -r' command:
b'5.4.0-58-generic'
Deleting interface pair veth0<->veth1
```

Conclusions I draw from this output:

+ When you use Scapy's `Ether()` call on a value with type `bytes`, it
  throws an exception if that `bytes` array has a length in bytes in
  the range [1, 13], inclusive.  This seems reasonable to me, given
  that an Ethernet header must contain 14 bytes.
  + For some reason I do not know, calling `Ether()` on a value with
    type `bytes` with length 0 does not throw an exception.
+ Linux veth interfaces can send and receive packets with lengths 14
  bytes and longer, and no padding will be added, even though these
  are shorter than the minimum Ethernet frame length of 64 bytes.
+ It is possible to use Scapy's `Raw()` to create packets shorter than
  14 bytes, and you can send them to the Linux veth interfaces, but in
  that case some software somewhere is padding them so that they are
  received with a length of 60 bytes, which is the minimum Ethernet
  frame length of 64 bytes, except for the 4-byte CRC at the end.
  + From running the `tcpdump` commands above on both interfaces
    `veth0` and `veth1`, both of them show a length of 60 bytes for
    the last 3 packets, so this padding seems to be added somewhere
    between the call to `sendp` in the Python test program, and the
    veth0 interface.
