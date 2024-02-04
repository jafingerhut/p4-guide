# Introduction

This article contains notes on installing IPDK, the open source parts
only, on an Ubuntu 20.04 system.

There are also step-by-step instructions for compiling P4 programs for
the DPDK software switch, loading the compiled programs into it, and
sending packets to it for processing.

+ [Installing IPDK](README-install-ipdk-networking-container-ubuntu-20.04-and-test.md)
+ [Useful notes on using IPDK](general-ipdk-notes.md)
+ [Quick test of your IPDK installation](quick-test.md)
+ [Notes on debugging P4 programs run on the DPDK software switch](debugging-p4-dpdk-programs.md)
+ [Running a P4 program with multiple Linux network namespaces, sending packets to it using tcpreplay, capturing packets out with tcpdump](run-p4-prog-with-multiple-network-namespaces.md)
+ [Running P4 program `add_on_miss0.p4` and testing it using a Python controller program (without PTF), tcpreplay, and tcpdump](testing-add-on-miss0-with-python-controller-tcpreplay-tcpdump.md)
+ [Running a P4 program and testing it using a PTF test](running-p4-program-and-ptf-test.md)
  + [Running P4 program `add_on_miss0.p4` and testing it using a PTF test](testing-add-on-miss0.md)
  + [Running P4 program `add_on_miss1.p4` and testing it using a PTF test](testing-add-on-miss1.md)
  + [A note on tiout durations in P4-DPDK](note-on-timeout-durations-in-p4-dpdk.md)
+ [Running DASH P4 code on DPDK software switch](running-dash-p4-code.md)


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
