# Introduction

This article describes potential problems with using the script
`install-p4dev-v10.sh` to install the open source P4 development tools
on Ubuntu 26.04.


# Systems tested so far

I have tested this script at least mostly working on both of these
systems:

+ x86_64 Ubuntu Linux 26.04 running within VirtualBox 7.2.14 on a
  physical x86_64 host running Windows 11.
+ aarch64 Ubuntu Linux 26.04 running within VirtualBox 7.2.18 on a
  physical Apple Silicon Mac running macOS 26.x.

On the Apple Silicon Mac, I often saw internal errors when the script
was attempting to compile C++ programs.  Some searching on the
Internet led me to believe that perhaps this is an issue with
VirtualBox on aarch64 physical hosts when the number of vCPUs for the
VM is more than 1.  However, even when I configured the VM to have
only 1 vCPU, I still saw that occur.  When that happened, I removed
whatever directory that was in the middle of being build when the
error occurred (grpc, PI, behavioral-model, or p4c), then reran the
install script.  It is written so that for any of those directories
that exist before the script started, it assumes that it has been
installed successfully and skips over it.


# Results of testing the system after the script completes successfully

This is the version of the p4-guide repository that I used when
getting the test results reported below:

```
 git log -n 1 | cat
commit 28e198805b58bcdebe95ba08fe49c16d1c4278a5
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Wed Sep 30 06:03:47 2026 -0400

    Add separate case for which version of grpcio Python package to install
```

The script installs the versions of Python packages show below.

Note that the script first installs protobuf version 6.31.0, but then
later when it is running the command `uv pip install .` within the
`p4runtime-shell` repository, that causes protobuf version 3.20.3 to
replace version 6.31.0.  The test results below are for when the
3.20.3 protobuf Python package is installed.

```
$ uv pip list
Using Python 3.14.4 environment at: /home/p4/src/p4dev-python-venv
Package                  Version                           Editable project location
------------------------ --------------------------------- -------------------------
backcall                 0.2.0
cffi                     2.1.1
crcmod                   1.7
decorator                5.3.1
getmac                   0.9.5
googleapis-common-protos 1.73.0
grpcio                   1.75.1
ipython                  7.31.1
jedi                     0.17.2
matplotlib-inline        0.2.2
mininet                  2.3.1b4                           /home/p4/src/mininet
netifaces                0.11.0
p4runtime                1.4.1
p4runtime-shell          0.0.6.post28+ge6fa803ce.d20260930
packaging                26.3
parso                    0.7.1
pexpect                  4.9.0
pickleshare              0.7.5
ply                      3.11
prompt-toolkit           3.0.53
protobuf                 3.20.3
psutil                   7.2.2
ptf                      0.12.3
ptyprocess               0.7.0
pycparser                3.0
pygments                 2.21.0
pynng                    0.9.0
pyperclip                1.8.2
scapy                    2.5.0
scapy-helper             0.14.8
setuptools               84.0.0
six                      1.17.0
sniffio                  1.3.1
tabulate                 0.8.10
thrift                   0.22.0
traitlets                5.16.1
typing-extensions        4.16.0
wcwidth                  0.9.1
wheel                    0.48.0
```

```bash
cd src/p4c/build
make -j3 check |& tee out-check1.txt

# If many tests fail, sometimes I run recheck without sudo
# a few times ...
make -j1 recheck |& tee out-recheck1.txt

# Some of the tests only pass if run as root
sudo PATH=${PATH} VIRTUAL_ENV=${VIRTUAL_ENV} ${P4_EXTRA_SUDO_OPTS} make -j1 recheck |& tee out-recheck1.txt
```

The following tests still failed with the version of the install
script mentioned earlier, on both x86_64 and aarch64 systems.  I have
not analyzed why these tests fail yet, nor what changes are required
to enable them to pass, but I suspect it is primarily to do with how
the p4c EBPF back end is installed, and in particular libbpf.

```
The following tests FAILED:
	4848 - testgen-p4c-ebpf/action_call_ebpf.p4 (Failed)     testgen-p4c-ebpf
	4849 - testgen-p4c-ebpf/action_call_table_ebpf.p4 (Failed) testgen-p4c-ebpf
	4850 - testgen-p4c-ebpf/advance_ebpf.p4 (Failed)         testgen-p4c-ebpf
	4851 - testgen-p4c-ebpf/bool_ebpf.p4 (Failed)            testgen-p4c-ebpf
	4852 - testgen-p4c-ebpf/count_add_ebpf.p4 (Failed)       testgen-p4c-ebpf
	4853 - testgen-p4c-ebpf/count_ebpf.p4 (Failed)           testgen-p4c-ebpf
	4854 - testgen-p4c-ebpf/hit_ebpf.p4 (Failed)             testgen-p4c-ebpf
	4855 - testgen-p4c-ebpf/init_ebpf.p4 (Failed)            testgen-p4c-ebpf
	4856 - testgen-p4c-ebpf/issue2791_ebpf.p4 (Failed)       testgen-p4c-ebpf
	4857 - testgen-p4c-ebpf/issue2793_ebpf.p4 (Failed)       XFAIL testgen-p4c-ebpf
	4858 - testgen-p4c-ebpf/issue2797_ebpf.p4 (Failed)       testgen-p4c-ebpf
	4859 - testgen-p4c-ebpf/issue2816-1_ebpf.p4 (Failed)     testgen-p4c-ebpf
	4860 - testgen-p4c-ebpf/issue2816_ebpf.p4 (Failed)       testgen-p4c-ebpf
	4861 - testgen-p4c-ebpf/issue870_ebpf.p4 (Failed)        testgen-p4c-ebpf
	4862 - testgen-p4c-ebpf/key-issue-1020_ebpf.p4 (Failed)  testgen-p4c-ebpf
	4863 - testgen-p4c-ebpf/key_ebpf.p4 (Failed)             testgen-p4c-ebpf
	4864 - testgen-p4c-ebpf/length_ebpf.p4 (Failed)          testgen-p4c-ebpf
	4865 - testgen-p4c-ebpf/lpm_ebpf.p4 (Failed)             XFAIL testgen-p4c-ebpf
	4867 - testgen-p4c-ebpf/stack_ebpf.p4 (Failed)           testgen-p4c-ebpf
	4868 - testgen-p4c-ebpf/switch_ebpf.p4 (Failed)          testgen-p4c-ebpf
	4869 - testgen-p4c-ebpf/ternary_ebpf.p4 (Failed)         XFAIL testgen-p4c-ebpf
	4870 - testgen-p4c-ebpf/test_ebpf.p4 (Failed)            testgen-p4c-ebpf
	4871 - testgen-p4c-ebpf/two_ebpf.p4 (Failed)             testgen-p4c-ebpf
	4872 - testgen-p4c-ebpf/valid_ebpf.p4 (Failed)           testgen-p4c-ebpf
	4873 - testgen-p4c-ebpf/value_set_ebpf.p4 (Failed)       testgen-p4c-ebpf
	4874 - testgen-p4c-ebpf/verify_ebpf.p4 (Failed)          testgen-p4c-ebpf
	4875 - testgen-p4c-ebpf/ebpf_conntrack_extern.p4 (Failed) testgen-p4c-ebpf
	4967 - gtestp4c (Failed)                                 gtest
```
