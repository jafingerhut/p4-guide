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

A few projects have intentionally been placed into more than one
category.

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


## `p4lang` repository descriptions

Glossary:

* `API` - Application Programming Interface
* `HLIR` - High Level Intermediate Representation.  See IR.
* `IR` - Intermediate Representation - data structures created as a
  result of parsing P4 source code, representing all relevant details
  about the source code needed for the back end portion of a compiler
  to generate configuration specific to a particular P4 target.
* `PD API` - Protocol Dependent API ?  TBD where to find out more
  about this.
* `PI API` - Protocol Independent API.  See `PI` repository [docs
  directory](https://github.com/p4lang/PI/blob/master/docs/msg_format.md)
  for some more about this, although I do not know if that particular
  document is up to date with the code.
* `v1.0.x` - As of 2017-Mar-12, v1.0.3 is the latest version of the P4
  specification in the v1.0.x series, although there is a v1.0.4
  planned by the P4 language design committee to clarify a few things,
  e.g. eliminating the portion of the specification that says that
  primitive actions within a compound action are to be performed in
  parallel -- v1.0.4 will specify sequential behavior within a
  compound action.
* `v1.1.x` - As of 2016-Dec-14 when a draft version of the P4_16
  language specification was released, the v1.1.x series of
  specifications was no longer publicized and effectively deprecated.


### `p4-hlir`

Written in Python.  Parses source code for P4_14 (v1.0.x) and P4
v1.1.x versions of P4.  Creates Python objects in memory representing
P4 source code objects such as headers, tables, field lists, actions,
etc.

Also performs target-independent semantic checks, such as references
to undefined tables or fields, and dead code elimination,
e.g. eliminating tables that are never applied, or actions that are
not an action of any live table.

This repository has not been extended to parse P4_16 programs.  It
seems that `p4c` is intended to be the new compiler for both P4_14 and
P4_16.


### `p4c-behavioral`

`p4c-behavioral` uses `p4-hlir` as its front end to parse source code
and produce an IR.  From that IR it generates a C/C++ behavioral model
(version 1, not for use with bmv2).  This repository has seen very few
changes since Aug 2016.  Most likely this is because bmv2 in
`behavioral-model` is recommended over this v1 kind of behavioral
model, for the reasons described
[here](https://github.com/p4lang/behavioral-model#why-did-we-need-bmv2-).

There may be a conflict between installing this software, and that in
the `p4c-bm` repo, as they both seem to install a Python module called
p4c-bm.


### `p4c-bm`

`p4c-bm` uses `p4-hlir` as its front end to parse source code and
produce an IR.  From that IR it can generate the kind of JSON data
files used as input to the `behavioral-model`, and optionally C++ PD
code.



### `p4c`

`p4c` is a front end compiler for both P4_14 and P4_16 programs.  The
repository also contains a back end for `behavioral-model` (aka
`bmv2`), and a couple of other sample back ends.  It is intended to be
able to easily add new back ends to it.

Unlike `p4-hlir` this front end is written in C++ rather than Python.



## Executables created during installation

The executables are shown with the path where they are
created/installed using the latest README instructions as of March
2017.

| Repository | Executable | Notes |
| ---------- | ---------- | ----- |
| p4-hlir    | /usr/local/bin/p4-shell      | |
| p4-hlir    | /usr/local/bin/p4-validate   | |
| p4-hlir    | /usr/local/bin/p4-graphs     | |
| p4c-bm     | /usr/local/bin/p4c-bmv2      | Compile P4_14 or v1.1 to bmv2 JSON input file, PD API files, and optionally a few other things. |
| p4c        | <repo_root>/build/p4c-bm2-ss | Compile P4_14 or P4_16 to bmv2 JSON input file |
| p4c        | <repo_root>/build/p4c-ebpf   | |
| p4c        | <repo_root>/build/p4test     | |

Sample command lines to compile P4_14 source file foo.p4 to JSON data
file that can be used as bmv2 input:

    p4c-bmv2 --json foo.json foo.p4
    p4c-bm2-ss --p4v 14 -o foo.json foo.p4


## Python modules created during installation

Python modules currently installed can be shown using 'pip list'
command.  You can see which directory the files are in using 'pip show
<module-name>' command.  This could be a system-wide directory
requiring root privileges, or if you have created a Python virtual
environment, it may be a directory anywhere you wish in the file
system, without requiring root privileges to add modules.

| Repository | Python module |
| ---------- | ------------- |
| p4-hlir    | p4-hlir |
| p4c-bm     | wheel (not P4-specific module) |
| p4c-bm     | Tenjin (not P4-specific module) |
| p4c-bm     | p4-hlir |
| p4c-bm     | p4c-bm |
