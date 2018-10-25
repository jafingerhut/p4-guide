## Idle timeout notifications in PSA

Terminology:

+ controller - another name for P4Runtime Client
+ agent - another name for P4Runtime Server

The basic idea of this feature is that the P4 developer wishes to
specify that, for one or more tables in their program, the PSA device
should send an idle timeout notification message to the controller for
any and all table entries that have not been matched by any packet
processing for a configurable time T.  The messages should include the
device id, table id, the key of the table entry, and a time that it
was last matched, if ever.

We want to describe the capabilities of this feature in such a way
that:

+ It is possible to implement it with low cost in hardware.
+ It enables actual desired use cases.


### Notes on precision

Note that in reality, after the last time a packet matched a table
entry, any timeout notification mechanism will be triggered during
some _interval_ of time, i.e. the condition will be detected no sooner
than a duration Tmin after the last match, and no later than a
duration Tmax after the last match.  This interval is at least as long
as one clock period of a clocked hardware device, e.g. 1/1.5GHz = 2/3
nanoseconds.  For most applications of timeout notifications, there is
no need for the interval to be anywhere near that short.

The MAC table use case described below is by default configured to
remove old MAC table entries when they have not been matched for 300
seconds.  For such a use case, does it really matter to anyone that
they be removed 300 seconds plus or minus 1 nanosecond after the last
time they were matched?  Most likely no.  If they were removed after
anywhere between 300 to 301 seconds of inactivity, you would probably
be content.

So picoseconds is, for the foreseeable future, a time unit that is
smaller than needed for this purpose.

Some whole number of hours is definitely too large of a time unit.

Using units of seconds is probably good enough for the MAC table use
case, but it seems likely that P4 developers would find other use
cases where shorter timouts would be useful, e.g. to develop a system
that implemented BFD[^BFD], a timeout of 50 milliseconds, and perhaps
as short as 10 milliseconds, is desirable.

[^BFD]: https://tools.ietf.org/html/rfc5880


### MAC table use case

The most common example use case for this feature is to enable a
developer to create a MAC table for Ethernet bridging, and the control
plane software wants to know when existing MAC table entries have not
been matched for a long time.  The control plane software uses these
notifications to then remove those stale entries from the table,
because most likely the host with that MAC address has been removed
from the network.  Keeping the table entry would be a waste of table
capacity.

Here is a page of documentation for Cisco's NXOS operating system.  It
describes how a user may configure a timeout duration for stale MAC
table entries in an L2 forwarding table:
https://www.cisco.com/c/m/en_us/techdoc/dc/reference/cli/nxos/commands/l2/mac-address-table-aging-time.html

Note that the default aging time is 300 seconds.  The page also says:

    "The age value may be rounded off to the nearest multiple of 5
    seconds.  If the system rounds the value to a different value from
    that specified by the user (from the rounding process), the system
    returns an informational message."



### Other use cases




### Idle timeout notifications will be lossy in some cases

It is possible for idle timeout "events" to occur faster than the
controller is able to receive them, or even faster than the agent is
able to process them.

Example: A table with idle timeout notification enabled, with T=1
second, has 1 million entries.

Suppose no packets are matching any of these 1 million entries.

1 second after the entries are installed, if CPU utilization and
communications bandwidth were free, then ideally we would notify the
controller with 1 million essages, 1 per table entry that has not been
matched for the last 1 second.

Suppose in the actual system, it takes 10 seconds to transmit those 1
million notification messages from agent to controller.  (Why would a
controller receive them that slowly, you may ask?  One, it is just an
example, and you can replace it with much shorter times like 100
milliseconds and the points below still hold, and two, the controller
may simultaneously be receiving similar timeout notifications from 50
other PSA devices simultaneously).

During those 10 seconds, suppose after 5 seconds packets arrive that
match all 1 million entries (in a system that can process 1 billion
packets per second, this could take as little as 1 millisecond to
happen).  After 5.001 + 1 second, all of those entries are again
unmatched for the 1 second before that time.

What is the desired behavior in such an "overload" scenario?

Should the agent finish transmitting the original notifications,
during the interval [0, 10 seconds], and when it is done with those,
start transmitting them all over again, even though they are now 5
seconds old?

It seems to me that a reasonable implementation would, in times when
there is enough compute and data transmission bandwidth available,
send all timeout notificatin messages with reasonable latency,
e.g. tens of milliseconds from the time they occurred.

When the volume of the timeout events is too large, many of them would
never be sent at all, being effectively "lost" between the device and
the agent, or within the agent, and the controller may never learn of
such lost timeout events.  Even the agent may not ever learn of many
of them, since it may not have enough resources to keep up with the
rate at which they occur.

One might wish for some kind of "fairness" in the loss of
notifications, e.g. if a table entry E1 had its notification lost
recently, it will be less likely to have its notification lost later.

However, if the reason for the notifications is that the controller
wants to remove the entries it hears about, because they are
considered 'stale', then the removed entries will definitely not cause
future notifications, so other stale entries are in such a case more
likely to make it through (unless new table entries are added that
also become stale, and for some implementation-specific reasons their
notifications are more likely to get through than the table entry that
has been around longer).


### Details

TBD: Should timeout notifications also occur for the default action
"entry" of a table?  Is there a use case where someone would _want_
the controller to get such a notification?  What would it do in
response to such a notification?

TBD: Would anyone want to get idle timeout notifications for parser
value sets?  I cannot think of a use case.  Parser value sets in my
experience are very small, e.g. a dozen entries or so, and their
contents only change very rarely, usually as a result of a network
administrator's request.  It seems of low value to require this
feature on parser value sets to me.

TBD: Should it be possible to enable idle timeout notifications on a
table with const entries?  It seems like a low value thing to support,
if it is complicated at all.


TBD: What about the combination of idle timeout notification and
action profiles?  What should that do?

TBD: What about the combination of idle timeout notification and
action selectors?  What should that do?
