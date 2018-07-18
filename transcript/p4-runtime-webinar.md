_Partial_ transcript of the LightReading Webinar "P4 Runtime: Putting
the Control Plane in Charge of the Forwarding Plane"

It has descriptions of most slides, but so far only has a detailed
transcript of the part of the presentation by Jim Wanderer from
Google, as well as one question in the Q&A related to it.

https://www.youtube.com/watch?v=reqJ3cqpfwo

Published on YouTube on 2017-Oct-12.

[Time 0:00:00]

Moderator:
Simon Stanley, Heavy Reading's Analyst at Large

Speakers:
Nick McKeown, Chief Scientist & Co-Founder, Barefoot Networks
Jim Wanderer, Director of Engineering, Google
Timon Sloane, VP Marketing & Ecosystem, Open Networking Foundation (ONF)

The speaker is primarily Simon Stanley at the beginning.

[Time 0:02:40]

slide: Agenda

+ Introduction
+ P4 Runtime - Nick McKeown (Barefoot Networks)
+ An important P4 Runtime use case - Jim Wanderer (Gogle)
+ P4 Runtime integration with ONOS - Timon Sloane (ONF)
+ Q&A

[Time 0:03:20]

slide: Network Virtualization and Open Solutions

[Time 0:04:30]

slide: Key Technology Developments

[Time 0:05:58]

slide: Moving from OpenFlow to P4 Runtime

[Time 0:06:41]

Poll question for webinar audience.

[Time 0:08:16]

slide: P4 Runtime: Putting the Control Plane in charge of the Forwarding Plane

Nick McKeown, Antonin Bas, Remy Chang

[Time 0:08:53]

slide: (no title)

[Figure of switch ASIC with 3 layers of software stack above it.]

[Time 0:10:32]

slide: (no title)

[Figure of multiple OpenFlow-controlled switches in a network with a
central controller communicating with all of them.]

[Time 0:12:32]

[Figure similar to 2 slides ago, but with SAI (Switch Abstraction
Interface) software layer in the middle.]

[Time 0:13:25]

slide: Challenge

Can we design an open, silicon-independent API that is easily enhanced
as we evolve the forwarding plane?

One that can be used equally for local or remote control planes.

[Time 0:13:56]

slide: Two things emerged

1. P4: An open language for describing how switches should process
   packets.

2. P4-programmable switch chips: e.g., the PISA architecture and
   Barefoot's Tofino switch chip.

[Time 0:14:41]

slide: P4.org Membership

[Figure with the logos of many companies and universities.]

[Time 0:15:17]

slide: PISA: Protocol Independent Switch Architecture

[Figure]

[Time 0:16:01]

slide: Example P4 Program

[Figure]


[Time 0:17:08]

slide: Barefoot Tofino 6.5Tb/s Switch

[Time 0:17:40]

slide: (no title)

[Time 0:18:21]

slide: Challenge

Can we design an open, silicon-independent API that is easily enhanced
as we evolve the forwarding plane?

One that can be used equally for local or remote control planes.

[Time 0:18:35]

slide: (no title)


[Time 0:19:48]

slide: In More Detail


[Time 0:19:52]

slide: The P4 program tells us the API we need...


[Time 0:20:10]

slide: P4 Runtime extends API to include table


[Time 0:20:22]

slide: (no title)


[Time 0:20:35]

slide: P4 Runtime for local Control Plane



[Time 0:20:53]

slide: Summary

+ Existing APIs are either hidden behind NDAs, and/or they are hard to
  extend.

+ Changing an existing API typically requires a lot of work, and a
  major interruption of service.

+ The P4 Runtime API is easy to extend by nature: It is derived from
  the program that describes the forwarding behavior.

+ The P4 Runtime API can be used equally well by a remote or local
  control plane.

+ The Control Plane does not need to be interrupted when the API is
  changed.


[Speaker changes to Jim Wanderer]

[Time 0:21:38]

slide: Next Generation SDN Switch

Future plans for Google's SDN Networks

Jim Wanderer, Alireza Ghaffarkah, Waqar Mohsin, Tom Everman, Lorenzo
Vicisano, Babru Thatikunta, Amin Vahdat, ...



[Time 0:21:49]

slide: (no title)

Chart showing evolution of Google's in-house development efforts for
their network.


[Time 0:22:23]

slide: History

For more details, see:

"Jupiter Rising: A Decade of Clos Topologies and Centralized Control
in Google's Datacenter Network"

SIGCOMM 2015


[Time 0:22:31]

slide: (no title)

Around 2010, OpenFlow arrived and we started adopting an SDN
architecture for our system.  This allowed us to centralize the
control of our network, with the brains of the network running on
standard compute servers.  This allowed us to make large scale
flexible networks with sophisticated features addressing special needs
around security and integration with our Google production systems.

This whole approach was key in building our very large 1.3 petabit
Jupiter data center network.


[Time 0:23:04]

slide: OpenFlow Limitations

Changed the way we built networks, but:

+ Limited interface - scale, features
+ Underdefined interface - match well defined, action ambiguous
+ Behavior inconsistent over different switch types

Result:

+ Added special workarounds and extensions
+ Specifications for specific behavior
+ Customized OpenFlow
+ 3rd party devices can't drop into the network fabric


So OpenFlow changed the way we built networks, but there were
limitations.  We no longer had a fully proprietary solution, which was
a good thing.  But OpenFlow's limited interfaces required us to do
some special things.  We needed to scale.  We needed special features.

As Nick mentioned, the interfaces in OpenFlow can be a bit ambiguous.
Well, the matches were well defined.  We could not always precisely
describe what the actual impact would be for programming action on the
behavior of the network.  This led to inconsistent behavior with
different types of switches that we used to build our networks.

To address this, we had to add special workarounds and extensions to
the protocol, and we had to write detailed specifications for what the
behavior was for certain types of programming into our network.  This
resulted in a customized version of OpenFlow, and we were not able to
take 3rd party devices supporting OpenFlow and drop them into our
network fabric.


[Time 0:24:11]

slide: New Hardware

Whitebox / bare metal switches available:

+ Accton Edgecore
+ Delta Networks
+ Quanta Cloud Technology
+ OCP / Wedge

Great fit for building DC fabrics

+ Leverage new technology quickly
+ Available now, fast time to deploy

But, difficult to integrate


And while previously we did need to build our own hardware, that is no
longer true.  There are excellent choices available for building these
large scale data center networks.  The whitebox and bare metal
switches from various manufacturers and providers are great building
blocks for large scale networks.  We would like to use these devices,
because off the shelf hardware lets us leverage new technology
quickly, gives us high velocity, faster for us to deploy.

But it is very difficult for us to integrate these into our networking
solutions.


[Time 0:24:46]

slide: Integration / Support

Large software effort:

+ Platform specific system software e.g. drivers
+ Proprietary switch vendor ASIC SDK
+ Port Google OpenFlow extensions and workarounds
+ Make Openflow function the same way on a new chip

Standard routing protocols almost sound better?

+ Interoperable
+ Not tied to a particular HW platform


And the reason is the software.  It is a large software effort.  It is
time consuming and expensive to incorporate these new systems.  This
comes from a couple of different things.

One of them is the platform specific software.  The drivers in each of
these platforms work slightly differently.  ASIC SDKs are generally
proprietary, and work differently.  And to make these work in our
networks, we would need to port the Google OpenFlow extensions and
workarounds to these new platforms, and make OpenFlow programming work
the same way on different chips.  This is a daunting, time consuming,
expensive effort, and almost makes standard routing protocols sound
better.  They are interoperable, and they are not tied to a particular
hardware platform.


[Time 0:25:34]

slide: What is Needed for an SDN Switch

Goals:

+ Fast and easy use of best and newest hardware available
+ High velocity to introduce new features

Want:

+ Easy to program
+ Easy to configure
+ Easy to manage
+ Silicon and system independence / abstraction

How?



However, SDN is then a critical enabler.  For our large scale, high
performance networks, we need SDN.  So we need to get it to work for
us, and achieve our goals, with our goals being to make it fast and
easy to use the best and newest hardware, and give us high velocity in
introducing new features into our network.

And what would do?  If we could make an SDN switch that was easy for
us to program and control, easy to configure and manage, and provided
a silicon and system abstraction to make it independent, then that
would be a system we can use to build our networks.

How?  What is the best way to do this?


[Time 0:26:13]

slide: Next Gen SDN Switch

+ P4Runtime
+ OpenConfig:
  + gNMI
  + gNOI
+ Open Network Linux Platform

[Figure shows a controller using P4Runtime to communicate with P4
Runtime Agent software running on a switch.  Other software components
shown on the switch are OpenConfig with gNMI and gNOI, and Open
Network Linux Platform.]


We believe we can make such a switch by using P4Runtime to control it.
We would program the switch forwarding pipelines with a P4 based
control.  We would manage and configure the switch using OpenConfig,
and the network management and network operations interfaces that
OpenConfig defines.  And we would achieve platform independence with
the Open Network Linux Platform, or ONLP.  This gives you a powerful
multi vendor solution for building SDN networks.


[Time 0:26:46]

slide: P4

Designed for programmable pipelines, but useful for fixed switches:

+ Define expected switch behavior and capabilities
+ Describe specific tables and functions

[Figure showing a few networking tables like L2, L3, Bridge, ACL, and
ECMP, with data flow arrows between them.  Also a brief snippet of a
few lines of P4 code, which includes annotations like @switchstack and
@proto_tag that I have not seen before.]


OK, a little more detail.  First, about P4.  As Nick described, P4 was
designed for programmable pipelines.  We found it very useful to apply
to fixed switches.  So we use P4 to detail and specify the functions
that we use in our application.  We can use P4 to document the
requirements and assumptions we are making when we build our system,
and build these networks, and we do not have to write separate
documentation.  This makes the chip behavior explicit and well
defined.  And we can describe the specific tables and functions that
we use, using P4.

On the left you see a simple abstract pipeline that our applications
might program.  And on the right you can see a snippet of P4 that
defines some of the functionality that is important to our
applications.


[Time 0:27:41]

slide: P4 Runtime Protocol

Configure the forwarding plane:

+ Act on specific tables
+ Read, Insert, Modify, Delete switch table entries
+ Contract for a programming interface
+ Openflow-like and well defined

[Figure with a box labeled "Forwarding State" with arrows down to the
tables in a copy of the logical pipeline figure from the previous
slide.]

Then, based on P4, P4Runtime is a protocol that allows us to configure
the forwarding plane.  We push the forwarding state to the chip, and
the P4 definition allows us to explicitly define the API, and the
results we get from programming the forwarding plane.  We do not need
to write the extra specs for the behavior.

This protocol allows a controller to act on specific tables with read,
modify, insert, and deleting entries in the switch tables.  This gives
us a contract for the programming interface that is OpenFlow-like but
well defined.


[Time 0:28:24]

slide: P4 Runtime Control

P4 Runtime Protocol Agent

+ Interface to switch ASIC
+ Provides access to switch tables
+ Transport: gRPC, FB Swift, etc
+ Replaces OpenFlow Agent

Remote or Local Control

ASIC pipeline can be:

+ Fixed
+ Programmable
+ Hybrid

[Figure showing a centralized controller using P4Runtime protocol to
communicate with P4Runtime Agent on switch, then switch stack SW, SDK,
and ASIC.]


The way we are using P4Runtime is with a centralized controller that
has been enhanced to support this protocol.  And we replace the
OpenFlow agent on the switch stack with the P4Runtime agent.  This
runtime agent serves as an interface to the switch ASIC, and provides
access to the switch tables.

We are using gRPC as the transport between the controller and switch.
Other transports such as Swift would work fine, also. [TBD: Should
this have been "Thrift" instead of "Swift", perhaps?]

We are using centralized remote control, but local processes and
routing protocols running on the switch would also use this interface
in the same way.

Note that we are making no assumptions about the ASIC.  The ASIC can
be fixed.  It can be programmable.  Or it could be some hybrid.


[Time 0:29:17]

slide: P4 Switch Abstraction

+ Logical pipeline configured on switch
+ Logical pipeline mapped to physical
+ Program logical pipeline
+ Mapping done via the P4 compiler and switch software.

[Figure showing the same logical pipeline figure as before, and below
that a "Physical" pipeline that is a closer representation of an
imagine switch ASIC, with a different data flow of hardware tables and
how they relate to each other.  There are dotted lines from tables in
the logical pipeline to one or more tables below in the physical
pipeline, representing which physical tables implement the behavior of
the logical pipeline.]

OK, but how do we handle the variation between chips?  How do we
address the complexity of putting different types of switches in our
network?

Our approach is to use P4 to define an abstract logical pipeline.  So
this is an abstraction.  This is an interface that a controller would
see, and the controller would program to the logical pipeline.

Then this logical pipeline is mapped onto a specific physical
implementation.  Because P4 is a compiled language and it has a
compiler, we can leverage that compiler for smart mapping of a logical
pipeline onto a physical pipeline.


[Time 0:30:02]

slide: P4 Runtime Multi-Vendor

[Figure shows a single controller talking to multiple logical
pipelines, each with a potentially different physical pipeline
implementing copies of the same logical pipeline.]


This allows us to put different types of ASICs into our network, and a
controller just sees a common logical interface, and it interacts with
all different types of switches in the same way.  So the different
implementations of ASICs are abstracted into a single model.  And the
P4 compiler and the software running on the switch are responsible for
mapping that logical pipeline onto the actual physical implementation.
In this way, we can drop new devices into the network with no changes
to our controller.


[Time 0:30:41]

slide: Configuration and Management

OpenConfig

+ Declarative configuration
+ Streaming telemetry
+ Model-driven management and operations
  + gNMI - network management interface
  + gNOI - network operations interface
+ Vendor-neutral data models
+ Address practical operational needs

[Figure showing Management system, connected to a switch running
OpenConfig gNMI and gNOI software, App SW, Platform Software, and ASIC
and other hardware.]


In addition to programming the network, managing and configuring
multi-vendor networks is still a challenge.  We think the right
approach is to use OpenConfig.  OpenConfig can fill this role.
OpenConfig brings a declarative configuration, and provides streaming
telemetry where data is streamed off the device to collectors.

It uses a model driven management scheme for operations, and it has a
network management interface and a network operations interface to
configure, manage, and operate the device.  It is based on vendor
neutral data models.  And it is deemed fine by a group of operators
who run large scale networks, and these operators have real world
problems to solve.  And so the design of OpenConfig is addressing
these practical needs.


[Time 0:31:30]

slide: System Software

Hardware / Platform variations

Open Network Linux Platform

+ Abstraction layer to inventory, manage, and monitor platform devices
+ Consistent API to platform level
+ Fans, PSUs, LED, media, temperature, EPROMs, FPGAs, ...

[Figure that is same as on previous slide, except with ONLP software
on the switch.]


To address differences at the platform layer between systems, where
systems have different drivers, and different logic handling hardware
at the system level for things such as pluggable media, fans,
temperature sensors -- which are all handled differently -- we are
looking for ONLP, the Open Network Linux Platform, to be the
abstraction layer to allow us to inventory, manage, and monitor all of
these hardware devices.  ONLP gives us a consistent API to this
platform layer that allows us to run software on multiple different
platforms in the same way.


[Time 0:32:14]

slide: Vision

Switch hardware system vendors provide:

+ System software
+ OpenConfig model support

Chip vendors provide

+ P4 Runtime for the ASIC
+ P4 Compiler support for mapping logical pipelines to ASIC

P4 Runtime + OpenConfig is _the abstraction layer_ for switches

+ Easy integration
+ Fast deployment for best and latest hardware


So our end goal is to use off-the-shelf hardware for high velocity and
low cost.  If we can get the system hardware vendors to provide us
system software with ONLP, and OpenConfig support, and the chip
vendors to provide P4Runtime support for the ASIC, and P4 compiler
support for mapping logical pipelines to their ASIC implementation,
then P4Runtime plus OpenConfig becomes _the_ abstraction layer for
switches.  This will allow us to easily integrate the best and newest
hardware into our networks very quickly with little effort, and allow
us to deliver the best solutions to our demanding customers.

Now I will hand it over to Timon.


[Time 0:32:59]

slide: ONF

Open Networking Foundation

P4 Runtime Demo

ONOS Controlling Barefoot Tofino Fabric


[Speaker changes to Timon Sloane]


[Time 0:33:20]

slide: ONF - A Track Record of Impact


[Time 0:35:47]

slide: P4 Runtime - Enabling Data Plane Pipeline Independence

[Figure with Application, ONOS, OpenFlow table management, and a
fixed-function data plane pipeline.  Later on the right is added
another similar figure, except with a P4 Runtime Agent component added
to ONOS, and a Programmable data plane pipeline at the bottom.]


[Time 0:38:51]

slide: Live demo at SDN World Congress

October 10-13, 2017.  The Hague, Netherlands

+ ONOS using P4 Runtime to:

  + Manage a spine-leaf fabric
  + Support data plane pipeline configuration
    + Downloads P4 program via P4 Runtime
  + Manipulate downloaded pipeline tables to manage traffic
    + Via P4 Runtime protobuf definitions carried over gRPC

+ Google's tor.p4 used as P4 program
  + Pipeline definition

+ Demonstrated on three switch types
  + 6.5 Tb/s Barefoot Tofino based OCP Wedge 100BF-65
  + 3.2 Tb/s Barefoot Tofino based OCP Wedge 100BF-32
  + BMv2 Soft Switch



[Time 0:39:59]

slide: Looking Forward - Beyond the Demo

+ Next Steps:
  + Switch configuration via OpenConfig over gNMI
  + Extend P4 Runtime support to other switch vendors/ASICs
  + Support for new/existing ONOS applications with any P4 program
    + Done via manual ONOS-to-P4 mapping

+ Longer-Term Scope
  + Ability to understand P4 programs (automatic ONOS-to-P4 mapping)
  + Rethink Northbound API to enable the full potential to P4
  + New Use Cases
    + In-band Telemetry
    + Spine-Leaf Fabric Optimization
    + VNF Offloading



[Time 0:41:44]

slide: ONF Vision for leveraging a P4 Enabled Data Plane

Virtualization is more than a VNF



[Time 0:44:06]

slide: Come Join the Community

+ P4 Brigade within ONOS Project
  + Wiki - https://tinyurl.com/onos-p4-brigade
+ P4.org
  + P4 API Working Group: https://tinyurl.com/p4-api-wg-charter

[photos of people working together]

P4 Brigade Working Session, Sept 2017, Seoul, South Korea


[Time 0:44:43]

slide: ONF
Open Networking Foundation

Thank You


[Speaker changes to Simon Stanley]


[Time 0:44:48]

slide: Summary

+ Webscale and telecom operators are pushing for greater control of
  large networks

+ Switch devices are becoming more programmable

+ OpenFlow provides limited control of switching hardware through an
  open interface

+ P4 is used to specify packet forwarding behavior in some smart NICs
  and switch devices

+ P4 Runtime provides a fully flexible and open interface between
  network controllers and switch dataplanes


[Time 0:45:39]

Poll question for webinar audience.



[Time 0:47:15]

Question: How is P4 different than OpenFlow?

did not transcribe this, but P4.org has an article written by Nick
McKeown and a few other people with a longer answer.



[Time 0:48:13]

Question: When will it be possible for ONOS or ONFP to have native P4
support?


[Time 0:49:51]

Question: Does monolithic VNFs imply moving away from Intel DPDK SDK
to P4Runtime implementations?


[Time 0:51:31]

Question: Typically, technology either provides complete flexibility,
or line rate performance.  So will you explain how, with this
approach, you can deliver both?


[Time 0:53:15]

Question: Besides data center use case, does Google plan or envisage
leveraging P4 to further enhance its global SDWAN on top of the famous
B4?


[Time 0:53:50]

Question: Can you please clarify how P4Runtime reduces complexity?
Does it need different schemas for different hardware pipeline
implementations?

[speaker Timon Sloane]

So when you have programmable forwarding planes, you know the same
schema can just be pushed down.  And I guess by schema we are talking
about the P4 program, I presume.  But maybe this question is about if
you have different fixed function forwarding pipelines, and you are
trying to model those in P4.  In which case there are two ways to
answer that.

One is that yes, there would be different P4 programs to model
specifically those fixed function pipelines.  But Jim from Google did
describe the ability to abstract that pipeline with a simplified
pipeline that could be uniform and run on different data planes and
pipelines.  And so in that way of thinking, that is a common schema --
a P4 program -- that is running on different hardware platforms.

And maybe Jim you want to follow that up?

[speaker Jim Wanderer]

You had that right, Timon.  Our plan is to have a simple pipeline
defined, or schema defined, that can be realized on multiple different
types of chips.  And instead of having a different pipeline for each
type of chip, we would actually have a different logical pipeline, or
schema as the questioner asks, for different roles.  So a top of rack
switch might have different functionality than an edge router.

And then what this abstraction approach allows us to do is
deliberately introduce changes.  So if we get a new generation of
hardware, and we want to introduce that switch use into the network,
we can have a slightly different schema for that switch.  But that is
an explicit control decision for which we can implement support.  So
in that way the control is in our hands.  The complexity has mostly
been pushed to this compiler and the implementation in the switch
software to map the logical pipeline to the actual physical hardware.


[Time 0:56:14]

Question: Is there any applications traditionally run on an x86 that
can run on P4 switches?

Answer summary: Examples include:

+ layer 4 load balancers
+ DNS caches
+ DDOS mitigation
+ accelerate storage
+ measurement


[Time 0:58:10]

Question: Here you talked a lot about controller based networking.
How do you envisage a hybrid approach where networks still run a
common control plane such as BGP, and a controller pushes advanced
functionality using P4Runtime?

[Jim Wanderer]

That is a very interesting question.  The way we would do it -- I am
not sure this is the way everybody would do it -- we would have the
BGP running on top of some software which used P4Runtime to push the
forwarding state generated by BGP into the hardware.  That way,
everything would be accessing the hardware through P4Runtime.  And
whether it be networking protocols, security applications, or other
types of forwarding applications, would all be using P4 together.

[Timon Sloane]

The way we think of it, actually, is we do this today, but maybe not
quite how the questioner was thinking.  If you look at an ONOS
implementation, or a CORD data center, we run the BGP protocol in
software on an x86, to exchange with the peer routers.  But then we
use that intelligence, using OpenFlow today, to push rules throughout
the fabric to be able to do all of the routing, so that no packets
have to hit any software processor.  And it essentially makes the data
center fabric run like one massive router, and every one of the
whitebox switches is almost like a blade in a chassis based switch.
You might think of it that way.

So we are blending the traditional protocols with the SDN techniques.
But we do it that way because then that island, the CORD data center,
has to be compatible with the existing network.  The existing network
uses BGP and other routing protocols.

So I think a little bit different than the question was intended, but
in the real world it is always a blend, frankly, to be able to
introduce new technologies.


[Time 1:00:31]

Question: I would like to learn about P4.  What is the best place to
start?

The web site P4.org has a lot of info.  There is a workshop every
year, and a developer day with tutorials.
