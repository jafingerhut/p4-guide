## Testing your installation

Note: Running any of the steps later in this section is _completely
optional_, and _not necessary_ to have a working installation of the
P4 development tools.  I run the commands below in my monthly test of
the install scripts, for additional assurance that they have been
installed correctly.


### Run tests included with `p4c`

One way to test your installation is to run the `p4c` P4 compiler's
included tests, which will compile well over 1000 test P4 programs,
and for several hundred of them it also runs the compiled code on
`simple_switch` and checks that the right packets come out.

Starting from the directory where you ran the install script, enter
these commands in a terminal.  No superuser privileges are required.
```bash
$ cd p4c/build
$ make -j2 check |& tee out.txt
```

With the current install script, it is normal for about 500 of these
tests to fail.  Many of those will pass if you re-run them as the user
`root` with a command like this:

```bash
$ sudo PATH=${PATH} VIRTUAL_ENV=${VIRTUAL_ENV} ${P4_EXTRA_SUDO_OPTS} make -j2 recheck |& tee out2.txt
```


### Send ping packets in the solution to `basic` exercise of `p4lang/tutorials` repository

A quick test is to try running the solution to the `basic` exercise in
the tutorials repository.  To do so, follow these steps:

```bash
$ git clone https://github.com/p4lang/tutorials
$ cd tutorials/exercises/basic
$ cp solution/basic.p4 basic.p4
$ make run
```

If at the end of many lines of logging output you see a prompt
`mininet>`, you can try entering the command `h1 ping h2` to ping from
virtual host `h1` in the exercise to `h2`, and it should report a
successful ping every second.  It will not stop on its own.  You can
type Control-C to stop it and return to the `mininet>` prompt, and you
can type Control-D to exit from mininet and get back to the original
shell prompt.

You may restore the modified `basic.p4` program back to its original
contents with the command:

```bash
$ git checkout basic.p4
```

This test exercises at least `p4c` for the v1model architecture,
`simple_switch_grpc`, and a portion of the P4Runtime API
implementation in `simple_switch_grpc` for adding table entries.

Historical note: If you are trying to use versions of the install
script older than `install-p4dev-v4.sh` (no longer tested by me, so
use at your own risk of lost time trying to make things work), you may
need to use a version of the `p4lang/tutorials` repository at version
`4914893445ae24bd1fa3b4aeea4910eeb412f7de` or older (end of year
2020), since the next commit after that updated all Python code to
Python3, not Python2.

If you are using the `install-p4dev-v5.sh` or `install-p4dev-v6.sh`
script, that should install only Python3 packages, and should work
with the latest version of the `p4lang/tutorials` repository.


## Details

You can find the (long) output files from my test runs of these
scripts that I do about once per month in [the bin/output
directory](output/) of this repository.  The dates on those files show
when I last ran them.

Things I did that helped this process go smoothly:

+ I started from an _unmodified_ _fresh_ installation of Ubuntu Linux.
  These install scripts install many packages using `apt-get`, and
  although I do not know how to determine a complete list of which
  Ubuntu packages conflict with each other, I know there are some that
  when simultaneously installed on a system, _can_ cause problems for
  each other.  Thus if you start from an Ubuntu machine with many
  packages installed on it already, and one of them conflicts with the
  packages installed by these scripts, you may not end up with a
  working installation of the open source P4 development tools.
  
  In my testing, I installed Ubuntu Desktop Linux as a virtual machine
  using VirtualBox on a Mac running a relatively recent version of
  macOS as the host operating system.  Installing them as a virtual
  machine on a different host operating system, or on a bare machine,
  should also work.
+ My machine had 2 GBytes of RAM available.  Less than 2 Gbytes will
  almost certainly not be enough.


## Version of P4 tools installed in Release VM images

The version of the P4 tools compiled and included with the
"Development" VM images is always the latest version of the source
code available for that project on Github as of the date of the image,
for these projects:

+ p4c https://github.com/p4lang/p4c
+ behavioral-model https://github.com/p4lang/behavioral-model
+ PI https://github.com/p4lang/PI
+ ptf https://github.com/p4lang/ptf

The version of the P4 tools installed with the "Release" VM images is
the latest version of the Ubuntu 20.04 package published as of the
date of the release image, which can be an older version of the source
code, since the Ubuntu 20.04 packages do not have new versions
published as often as commits are made to the repositories above.

| Date published | Operating system | p4c version | behavioral-model version |
| -------------- | ---------------- | ----------- | ------------------------ |
| 2023-Jul-01 | Ubuntu 20.04 | SHA: 71a06fe 2023-Jun-02 | SHA: 7a8843ff 2023-May-17 |
| 2022-Nov-01 | Ubuntu 20.04 | SHA: 1576090 2022-Aug-02 | SHA: f745e1db 2022-Feb-10 |
| 2022-Mar-01 | Ubuntu 20.04 | SHA: a9aa5ff 2022-Feb-08 | SHA: c76a03c3 2022-Feb-08 |
| 2022-Feb-03 | Ubuntu 20.04 | SHA: b28fbbb 2021-Nov-23 | SHA: 2de095c7 This is not the SHA of any behavioral-model commit SHA in the main branch of its source repository |


## Historical notes

+ Ubuntu 18.04 reached its [end of standard
  support](https://wiki.ubuntu.com/Releases) in April 2023.  I tested
  `install-p4dev-v4.sh` on Ubuntu 18.04 monthly until Feb 2023, and
  `install-p4dev-v6.sh` monthly until March 2023, but discontinued
  testing those combinations at that time.  They might continue
  working after that, but I have no plans to update those scripts to
  work on Ubuntu 18.04 after those dates.
+ Similarly Ubuntu 16.04 reached its end of standard support in April
  2021.  I tested the `install-p4dev-v2.sh` script on Ubuntu 16.04
  monthly until August 2021, but I do not plan to test it any longer.

The scripts in the next table below are no longer tested by me.  They
are listed here only for possible historical interest.

| Script | Versions of Ubuntu it was formerly tested on | Last tested | P4Runtime API support? | Mininet installed? | Uses Python3 only? | PTF installed? | Free disk space required | Time to run on 2019 MacBook Pro with VirtualBox | Data downloaded from Internet | protobuf | grpc |
| ------ | ------------------------------ | ----------- | ---------------------- | ------------------ | ------------------ | -------------- | ------------------------ | ----------------------------------------------- | ----------------------------- | -------- | ---- |
| install-p4dev-v7.sh | 22.04, 20.04 | 2024-Jun | yes | yes | yes | yes | 25 GB | 200 mins | 2 GB | v3.21.6 | v1.51.3 |
| install-p4dev-v6.sh | 22.04, 20.04 | 2024-Jun | yes | yes | yes | yes | 25 GB | 160 mins | 2 GB | v3.18.1 | v1.43.2 |
| install-p4dev-v4.sh | 20.04, 18.04 | 2023-Feb | yes | yes | yes | yes | 12 GB | 100 mins | 2 GB | v3.6.1 | v1.17.2 |
| install-p4dev-v3.sh | DO NOT USE | Not tested | -- | -- | -- | -- | -- | -- | -- | -- | -- |
| install-p4dev-v2.sh | 18.04, 16.04 | 18.04 in 2022-Mar, 16.04 in 2021-Aug | yes | yes | no, Python2 | no | 11 GB | 100 mins |   2 GB | v3.6.1 | v1.17.2 |
| install-p4dev-p4runtime.sh | 18.04, 16.04 | 2020-Mar | yes | yes | no, Python2 | no | 8.5 GB |  70 mins | ? | v3.2.0 | v1.3.2 |
| install-p4dev.sh | -- | 2019-Oct |  no |  no | no, Python2 | no |  5 GB |  40 mins | ? | v3.2.0 | not installed |
