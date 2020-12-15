## Getting the current free disk space in a format easy for a script to compare

I have tested this command on Ubuntu 16.04, 18.04, and 20.04 systems,
and on all of them it outputs a single line of text, which is a
decimal number of MBytes that is free on the file system that stores
the current directory.

```bash
df --output=avail --block-size=1M . | tail -n 1
```

Sample output on a system with about 16 GBytes of free disk space:

```bash
$ df -h .
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        59G   40G   16G  72% /

$ df --output=avail --block-size=1M . | tail -n 1
16336
```


## Getting the system RAM

```bash
head -n 1 /proc/meminfo | awk '{print $2;}'
```

```bash
head -n 1 /proc/meminfo | awk '{print $2;}'
```

"VirtualBox RAM" means the setting in the GUI of:

Settings -> System -> Motherboard -> Base Memory

| VirtualBox RAM | MemTotal |
|        2048 MB | 2035312, 2035532, 2035540, 2041024 | 54.8 to 60.4 MBytes short of 2*1024 MBytes |
|        4096 MB | 4030244, 4030264, 4038900 | 151.8 to 160.2 MBytes short of 4*1024 MBytes |

From this source:

https://www.thegeekdiary.com/understanding-proc-meminfo-file-analyzing-memory-utilization-in-linux/

High level statistics

MemTotal: Total usable ram (i.e. physical ram minus a few reserved
    bits and the kernel binary code)
MemFree: Is sum of LowFree+HighFree (overall stat)
MemShared: 0; is here for compat reasons but always zero.
Buffers: Memory in buffer cache. mostly useless as metric nowadays
    Relatively temporary storage for raw disk blocks shouldn’t get
    tremendously large (20MB or so)
Cached: Memory in the pagecache (diskcache) minus SwapCache, Doesn’t
    include SwapCached
SwapCache: Memory that once was swapped out, is swapped back in but
    still also is in the swapfile (if memory is needed it doesn’t need
    to be swapped out AGAIN because it is already in the
    swapfile. This saves I/O)

Another source that looks authoritative, since it comes from the Linux
kernel itself:

https://github.com/torvalds/linux/blob/master/Documentation/filesystems/proc.rst
