# Saw "Add port operation failed" when starting simple_switch

Symptom: You tried running simple_switch and you see a message like
this:

```
[10:59:18.649] [bmv2] [D] [thread 20021] Adding interface veth2 as port 0
[10:59:18.649] [bmv2] [E] [thread 20021] Add port operation failed
```

Note: simple_switch does _not_ quit when this happens.  It keeps
running, but whatever port it had trouble adding will _not_ be present
in your software switch.  You won't be able to send packet to your P4
program on that port, and packets sent to that port by your P4 program
will disappear.

If the interface that failed was a virtual Ethernet one like veth2,
the most likely fix is to run this command to create those interfaces:

```
$ sudo $BMV2/tools/veth_setup.sh
```

or if you do not have the shell variable BMV2 set to the path of your
copy of the p4lang/behavioral-model repository, you can replace $BMV2
with that directory.


# Trying to run simple_switch but get error "Nanomsg returned a exception ..."

Symptom: You tried running simple_switch (or some p4c or
behavioral-model `make check` command you ran tried doing so for you),
and you see an error message like this:
```
Nanomsg returned a exception when trying to bind to address 'ipc:///tmp/bmv2-0-notifications.ipc'.
The exception is: Address already in use
This may happen if
1) the address provided is invalid,
2) another instance of bmv2 is running and using the same address, or
3) you have insufficent permissions (e.g. you are using an IPC socket on Unix, the file already exists and you don't have permission to access it)
```

The most likely fix is to run this command:

```
$ sudo rm /tmp/bmv2-0-notifications.ipc 
```

It is also possible you have one or more `simple_switch` processes
running on your machine already.  See the next section for that.

Explanation:

When you run `simple_switch`, it normally creates a "Unix domain
socket" for possible communication of logging data to other processes.
If you use this command, you will see what looks like a file in the
`/tmp` directory named `bmv2-0-notifications.ipc`:

```
$ ls -l /tmp/bmv2-0-notifications.ipc 
srwxr-xr-x 1 root root 0 Sep 20 13:11 /tmp/bmv2-0-notifications.ipc
```

This file will be owned by whatever Unix user you last ran
`simple_switch` as, which is most commonly your normal login user id,
or `root` if you use `sudo` to run `simple_switch` as specified
elsewhere in this repository (to give `simple_switch` the needed
permissions to send/receive packets to virtual Ethernet ports).

If you earlier ran `simple_switch` as root and this file was left
behind owned as root, and later try to run `simple_switch` as you,
e.g. because you forgot `sudo`, or because you try to run the tests
that come with the `p4c` or `behavioral-model` repositories, which do
not need root permissions, then when running as you, `simple_switch`
will try to create that file in `/tmp` and fail, causing the message
above.  Deleting the file owned by root enables simple_switch to
create the file as your user id.


# Killing old simple_switch processes

The symptoms could be any of several that I do not have handy at the
time of writing this. Feel free to submit some specific symptoms if
you have the details that would help others recognize this situation.

Running multiple `simple_switch` processes that are all trying to read
packets from, or send packets to, the same virtual Ethernet ports on
the same machine simultaneously, might be exactly what you want in
order to simulate a network of multiple switches communicating via
Ethernet links to each other.

However, if it is an accident that you have multiple `simple_switch`
processes running, and you want to ensure none are currently running
before starting a new one, read below.

```
$ ps axguw | grep simple_switch
jafinger 20161  0.2  0.3 223116 14452 pts/1    Sl+  11:11   0:00 simple_switch --log-console -i 0@veth2 action-profile-and-selector/action-profile.json
jafinger 20174  0.0  0.0  21536  1036 pts/3    S+   11:11   0:00 grep --color=auto simple_switch
```

To kill all processes with the name `simple_switch` (but not
`simple_switch_CLI`):

```
$ sudo killall -s 9 simple_switch
```


# Compiler gives error message about `mark_to_drop`

If you see an error message like this when compiling one of these programs:
```
demo1.p4_16.p4(92): [--Werror=legacy] error: mark_to_drop: Passing 1 arguments when 0 expected
        mark_to_drop(stdmeta);
        ^^^^^^^^^^^^^^^^^^^^^
demo1.p4_16.p4(137): [--Werror=legacy] error: mark_to_drop: Passing 1 arguments when 0 expected
        mark_to_drop(stdmeta);
        ^^^^^^^^^^^^^^^^^^^^^
```

this is most likely because you are using a version of `p4c` compiled
from source code from 2019-Apr-18 or sooner.  In particular, it was
compiled before this change was committed to the compiler:

```
commit 73f100e460e60d8a872522991603a2b2c3cf77ea
Author: Mihai Budiu <mbudiu@vmware.com>
Date:   Thu Apr 18 16:40:56 2019 -0700

    Deprecate mark_to_drop(); replace with mark_to_drop(standard_metadata) function (#1835)
    
    * Deprecate @mark_to_drop; replace with mark_to_drop(standard_metadata)
```

It was discovered shortly before that change was made that the
`v1model` architecture's definition of `mark_to_drop` should take the
standard_metadata struct as a parameter, because it locally modifies
some fields of that structure.

You have two choices for resolving this:

+ Change the P4 program so it calls `mark_to_drop()` with no
  parameters, instead of `mark_to_drop(stdmeta)`.
+ Leave the P4 program unchanged, but update your version of the `p4c`
  compiler to one built from source from the commit mentioned above,
  or later.
