# Introduction

This repository aims to be a guide to the public p4lang repositories,
and some other selected public sources of information about P4,
related tools, and published research papers.

Caveat emptor: As of this writing, the author is not an expert on
these topics, and is creating this in hopes of getting up to speed
with the state of the art more quickly.  Corrections and comments
are very welcome.


## `p4lang` repositories by name

`p4lang` is the name of a Github
['organization'](https://github.com/blog/674-introducing-organizations).
A Github organization is a way of grouping together multiple related
repositories.

[p4lang organization](https://github.com/p4lang/) on Github

All p4lang repositories as of 2017-Mar-10, sorted by name (case
insensitive), with their descriptions:

* [`behaviorial-model`](https://github.com/p4lang/behavioral-model) -
  Rewrite of the behavioral model as a C++ project without
  auto-generated code (except for the PD interface)
* [`mininet`](https://github.com/p4lang/mininet) - Emulator for rapid
  prototyping of Software Defined Networks http://mininet.org (forked
  from [mininet/mininet](https://github.com/mininet/mininet))
* [`ntf`](https://github.com/p4lang/ntf) - Network Test Framework
* [`p4-build`](https://github.com/p4lang/p4-build) - Infrastructure
  needed to generate, build and install the PD library for a given P4
  program
* [`p4-hlir`](https://github.com/p4lang/p4-hlir) - (No description)
* [`p4app`](https://github.com/p4lang/p4app) - (No description)
* [`p4c`](https://github.com/p4lang/p4c) - P4_16 prototype compiler
* [`p4c-behavioral`](https://github.com/p4lang/p4c-behavioral) - P4
  compiler for the behavioral model
* [`p4c-bm`](https://github.com/p4lang/p4c-bm) - Generates the JSON
  configuration for the behavioral-model (bmv2), as well as the C/C++
  PD code
* [`p4factory`](https://github.com/p4lang/p4factory) - Compile P4 and
  run the P4 behavioral simulator
* [`p4ofagent`](https://github.com/p4lang/p4ofagent) - Openflow agent
  on a P4 dataplane
* [`papers`](https://github.com/p4lang/papers) - Repository for papers
  related to P4
* [`PI`](https://github.com/p4lang/PI) - P4 PI headers and
  target-independent code
* [`ptf`](https://github.com/p4lang/ptf) - Packet Test Framework
* [`SAI`](https://github.com/p4lang/SAI) - Switch Abstraction
  Interface (forked from
  [opencomputeproject/SAI](https://github.com/opencomputeproject/SAI))
* [`scapy-vxlan`](https://github.com/p4lang/scapy-vxlan) - A scapy
  clone, with support for additional packet headers
* [`switch`](https://github.com/p4lang/switch) - Consolidated switch
  repo (API, SAI and Nettlink)
* [`third-party`](https://github.com/p4lang/third-party) - Third-party
  dependencies for p4lang software
* [`thrift`](https://github.com/p4lang/thrift) - Mirror of Apache
  Thrift (forked from
  [apache/thrift](https://github.com/apache/thrift))
* [`tutorials`](https://github.com/p4lang/tutorials) - P4 language
  tutorials


Excerpt from 2017-Mar-07 email from Antonin Bas on p4-dev email list
[link](http://lists.p4.org/pipermail/p4-dev_lists.p4.org/2017-March/000794.html)

> IMO, there is no good reason to use p4factory today, as it is in the
> process of being deprecated.  Either you want to run switch.p4, in
> which case you should refer to the instructions in the switch repo
> directly, or you are interested in writing your own P4 programs and
> running them in bmv2, in which case the best place to get started is
> probably the tutorials repo.  To generate control plane APIs easily,
> the best place to look is the p4-build repository.


## `p4lang` repositories by category

Remaining to be categorized:

* [`p4-build`](https://github.com/p4lang/p4-build) - Infrastructure
  needed to generate, build and install the PD library for a given P4
  program
* [`p4app`](https://github.com/p4lang/p4app) - (No description)
* [`p4factory`](https://github.com/p4lang/p4factory) - Compile P4 and
  run the P4 behavioral simulator
* [`p4ofagent`](https://github.com/p4lang/p4ofagent) - Openflow agent
  on a P4 dataplane
* [`PI`](https://github.com/p4lang/PI) - P4 PI headers and
  target-independent code
* [`switch`](https://github.com/p4lang/switch) - Consolidated switch
  repo (API, SAI and Nettlink)

P4 compilers, some only front end, some front end plus back end for
one or more P4 targets:

* [`p4-hlir`](https://github.com/p4lang/p4-hlir) - (No description)
* [`p4c`](https://github.com/p4lang/p4c) - P4_16 prototype compiler
* [`p4c-behavioral`](https://github.com/p4lang/p4c-behavioral) - P4
  compiler for the behavioral model
* [`p4c-bm`](https://github.com/p4lang/p4c-bm) - Generates the JSON
  configuration for the behavioral-model (bmv2), as well as the C/C++
  PD code

P4 behavioral models, for running P4 programs on general purpose
computers:

* [`behaviorial-model`](https://github.com/p4lang/behavioral-model) -
  Rewrite of the behavioral model as a C++ project without
  auto-generated code (except for the PD interface).  Also known as
  `bmv2`.
* [`p4c-behavioral`](https://github.com/p4lang/p4c-behavioral) - P4
  compiler for the behavioral model

Open source tools created by organizations other than p4.org, used by
one or more `p4lang` repositories:

* [`mininet`](https://github.com/p4lang/mininet) - Emulator for rapid
  prototyping of Software Defined Networks http://mininet.org (forked
  from [mininet/mininet](https://github.com/mininet/mininet))
* [`SAI`](https://github.com/p4lang/SAI) - Switch Abstraction
  Interface (forked from
  [opencomputeproject/SAI](https://github.com/opencomputeproject/SAI))
* [`scapy-vxlan`](https://github.com/p4lang/scapy-vxlan) - A scapy
  clone, with support for additional packet headers
* [`third-party`](https://github.com/p4lang/third-party) - Third-party
  dependencies for p4lang software
* [`thrift`](https://github.com/p4lang/thrift) - Mirror of Apache
  Thrift (forked from
  [apache/thrift](https://github.com/apache/thrift))

For creating and running automated tests:

* [`mininet`](https://github.com/p4lang/mininet) - Emulator for rapid
  prototyping of Software Defined Networks http://mininet.org (forked
  from [mininet/mininet](https://github.com/mininet/mininet))
* [`ntf`](https://github.com/p4lang/ntf) - Network Test Framework
* [`ptf`](https://github.com/p4lang/ptf) - Packet Test Framework
* [`scapy-vxlan`](https://github.com/p4lang/scapy-vxlan) - A scapy
  clone, with support for additional packet headers

Documentation, research papers, and tutorials:

* [`papers`](https://github.com/p4lang/papers) - Repository for papers
  related to P4
* [`tutorials`](https://github.com/p4lang/tutorials) - P4 language
  tutorials
