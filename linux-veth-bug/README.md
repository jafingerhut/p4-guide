# Linux kernel issue where it adds extra bytes at end of packet

p4lang/behavioral-model issue: https://github.com/p4lang/behavioral-model/issues/650#issuecomment-419228162

Link to Ubuntu page with a bug report: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1782544

Kernel versions as output by 'uname -r' command where I have seen GOOD
results:

+ 4.4.0-31-generic (Ubuntu 14.04.5)
+ 4.4.0-134-generic (Ubuntu 14.04.5)


Kernel versions where I have seen BAD results, with captured packet 14
bytes longer than the sent packet:

+ 4.15.0-33-generic (Ubuntu 16.04.5)
