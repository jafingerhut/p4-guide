# Introduction

This article contains notes on installing IPDK, the open source parts
only, on an Ubuntu 20.04 system.

There are also step-by-step instructions for compiling P4 programs for
the DPDK software switch, loading the compiled programs into it, and
sending packets to it for processing.

The IPDK instructions and build scripts come from this repository:

+ https://github.com/ipdk-io/ipdk

The `infrap4d` program compiled and installed using the steps below is
a combination of at least the following parts:

+ The DPDK data plane, or software switch.  You may compile P4
  programs and load the binaries into it to execute them.
+ A P4Runtime API server, by default listening on TCP port 9559 for
  incoming connection requests from P4Runtime API clients
  (i.e. controller programs).
+ A gNMI server

Source: The figure on [this
page](https://ipdk.io/p4cp-userguide/overview/overview.html#infrap4d)
shows the above parts, and also some other software components
included within the `infrap4d` process.

+ [Installing IPDK](docs/README-install-ipdk-networking-container-ubuntu-20.04-and-test.md)
+ [Useful notes on using IPDK](docs/general-ipdk-notes.md)
+ [Quick test of your IPDK installation](quick-test.md)
+ [Notes on debugging P4 programs run on the DPDK software switch](docs/debugging-p4-dpdk-programs.md)
+ [Running a P4 program with multiple Linux network namespaces, sending packets to it using tcpreplay, capturing packets out with tcpdump](docs/run-p4-prog-with-multiple-network-namespaces.md)
+ [Running P4 program `add_on_miss0.p4` and testing it using a Python controller program (without PTF), tcpreplay, and tcpdump](docs/testing-add-on-miss0-with-python-controller-tcpreplay-tcpdump.md)
+ [Running a P4 program and testing it using a PTF test](docs/running-p4-program-and-ptf-test.md)
  + [Running P4 program `add_on_miss0.p4` and testing it using a PTF test](docs/testing-add-on-miss0.md)
  + [Running P4 program `add_on_miss1.p4` and testing it using a PTF test](docs/testing-add-on-miss1.md)
  + [A note on timeout durations in P4-DPDK](docs/note-on-timeout-durations-in-p4-dpdk.md)
+ [Running DASH P4 code on DPDK software switch](docs/running-dash-p4-code.md)


# Other places to go for information about P4 DPDK

Talks given by developers of P4 DPDK:

+ "Running P4 programs as DPDK applications", Cristian Dumitrescu and
  Han Wang, Intel, DPDK Summit, July 12-13, 2021
  + https://www.youtube.com/watch?v=xJR-5DcqhlY
+ "Develop Your CPU Network Stack in P4", Cristian Dumitrescu, P4
  Workshop, May 24-26, 2022
  + https://www.youtube.com/watch?v=NySJfUIUzww
  + slides: https://opennetworking.org/wp-content/uploads/2022/05/Cristian-Dumitrescu-Final-Slide-Deck.pdf
+ "Do not develop from scratch, simply write P4 and get DPDK",
  Cristian Dumitrescu, Intel, DPDK Userspace Summit, September 6-8,
  2022
  + https://www.youtube.com/watch?v=dPvH_joaScA


# Latest tested version of IPDK

Here is the version of the IPDK repo that I have tested these steps
with most recently:

```
$ cd $HOME/ipdk
$ git log -n 1
commit 0e3fa3ea1a4edafc537def3e9951053ef68338c5 (HEAD -> main, tag: v24.01, origin/main, origin/ipdk_v24.01, origin/HEAD)
Merge: b0446f6 cc8adcf
Author: Sabeel Ansari <35787514+5abeel@users.noreply.github.com>
Date:   Tue Jan 16 12:37:04 2024 -0600

    Merge pull request #411 from saynb/saynb/dev/k8s-release-notes
    
    Addign K8s realease notes for 24.01
```
