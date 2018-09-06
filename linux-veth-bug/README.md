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


Kernel versions as output by 'uname -r' command where I have seen GOOD
results:

+ 4.4.0-31-generic (Ubuntu 14.04.5)
+ 4.4.0-134-generic (Ubuntu 14.04.5)
+ 4.14.68-041468-generic (Ubuntu 16.04.5), installed via ukuu
+ 4.15.0-041500-generic (Ubuntu 16.04.5), installed via ukuu
+ 4.15.1-041501-generic (Ubuntu 16.04.5), installed via ukuu
+ 4.15.18-041518-generic (Ubuntu 16.04.5), installed via ukuu
+ 4.16.18-041618-generic (Ubuntu 16.04.5), installed via ukuu


Kernel versions where I have seen BAD results, with captured packet 14
bytes longer than the sent packet:

+ 4.15.0-33-generic (Ubuntu 16.04.5)
