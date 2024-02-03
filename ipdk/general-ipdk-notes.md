# Running commands in the base OS vs. running commands in the container

Every time the instructions say to run a command "in the base OS",
that means you should have some command shell that is running in the
base Ubuntu 20.04 operating system.  You should _not_ have run `ipdk
connect` or `docker exec it ...` in this shell.

Every time the instructions say to run a command "in the container",
that means you should have some shell at a prompt reached by running
the `ipdk connect` or `docker exec it ...` command below.

The file system contents (and thus which software packages are
available for use), the Linux networking namespaces, and probably many
other things, are different when running commands in the base OS
vs. running commands in the container.

You will likely find it convenient to have at least two command shell
windows open at the same time, one at a prompt in the base OS, and the
other at a prompt in the container.

Note: Every time you run `ipdk connect`, a script run in the container
creates new cryptographic authentication keys for the `infrap4d`
server in the directory `/usr/share/stratum/certs` (or perhaps
`/var/stratum/certs` in older versions of IPDK).  You want this to
happen once per container process that you start.  One way to achieve
this is to only do `ipdk connect` exactly once each time you run `ipdk
start`.  If you then want additional terminals to be at a shell prompt
within that same container process, you can use the following command
instead of `ipdk connect`:

```bash
docker exec -it -w /root 8e0d6ad594af /bin/bash
```

Replace `8e0d6ad594af` with the value in the `CONTAINER ID` column in
the output of `docker ps`, for the container with IMAGE name like
`ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:<something>`.


# Sharing files between the base OS and container

The following two directories are different 'views' of one underlying
directory:

+ In the base OS: `$HOME/.ipdk/volume`
+ In the container: `/tmp`

Thus, in the base OS, if you copy files to the directory
`$HOME/.ipdk/volume`, they will be visible in directory `/tmp` in the
container, and vice versa.


# Useful extra software to install in the base OS

If you like using Wireshark, or the tshark variant of that program, in the base OS for viewing the contents of pcap files that contain packets recorded during a test run, you can install it as follows.

In the base OS:
```bash
sudo apt-get install --yes tshark wireshark
```


# Useful extra software to install in the container

Every time the container is started on a system, via some variant of
the `ipdk start` command, its file system is in the same initial state
as every other time it is started.

Commands like `git`, `tcpdump`, and `tcpreplay` are not installed in
the container when it is first built.  Thus every time you start
another instance of the container, those commands will not be
available.

A simple bash script is included in this repository that will install
those commands, and a few other useful software packages, in the
container.

In the base OS:
```bash
cp -pr ~/p4-guide/ipdk/*.sh ~/p4-guide/pylib ~/.ipdk/volume/
```

In the container:
```bash
/tmp/install-ipdk-container-extra-pkgs.sh
```


# Notes on running `ipdk` commands

There is an `ipdk start` command to start an instance of the
container, an `ipdk connect` command that gets you to a bash prompt
running in of the container, and several other `ipdk` sub-commands
that are useful for various purposes.

If you run one of these commands, and you see an error message like
`fatal: not a git repository` followed later by `Unable to find image
'<some-name>' locally`, as shown in the example output below:

```
$ ipdk start -d
fatal: not a git repository (or any of the parent directories): .git
Loaded /home/andy/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
Can't find update-binfmts.
Using docker run!
Unable to find image 'ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:sha-none' locally
docker: Error response from daemon: manifest unknown.
See 'docker run --help'.
```

This is most likely because you are trying to run the command when the
current directory is not one that is inside of your cloned copy of the
`ipdk` repository.  To avoid this error, simply `cd $HOME/ipdk` and
try the command again.

Note: The docker image name is created containing a string of hex
digits at the end.  This hex string is part of the commit SHA of the
ipdk git repository at the time the docker image was created, so if
that changes because you updated your clone of the `ipdk` repo, you
may need to rebuild the docker image.
