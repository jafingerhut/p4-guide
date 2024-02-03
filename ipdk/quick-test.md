# A quick test of the IPDK installation

These steps are not necessary for installing or using IPDK.  They are
one quick way to test your installation to see if it is working as
expected.

To start running an instance of the container:

In the base OS:
```bash
$ cd $HOME/ipdk
$ ipdk start -d
Loaded /home/andy/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env
Missing QEMU.
Using docker run!
c75e8bbdcbac8e33c231a6f3348069089854d7f77ec6bf2f91373a98ea3ef42a
```

If this succeeds, there will now be a container process running, which
you can see in the output of the `docker ps` command as shown in the
example output below:

In the base OS:
```bash
$ docker ps
CONTAINER ID   IMAGE                                                COMMAND                  CREATED              STATUS              PORTS                                                                                  NAMES
c75e8bbdcbac   ghcr.io/ipdk-io/ipdk-ubuntu2004-x86_64:sha-7978695   "/root/scripts/start…"   27 seconds ago   Up 27 seconds   0.0.0.0:9339->9339/tcp, :::9339->9339/tcp, 0.0.0.0:9559->9559/tcp, :::9559->9559/tcp   ipdk
```

The `ipdk connect` command starts a bash shell in the container and
leaves you at a prompt where you can enter commands for running in
that container.  Sample output of this command is shown below:

In the base OS:
```bash
$ ipdk connect
Loaded /home/andy/ipdk/build/scripts/ipdk_default.env
Loaded /home/andy/.ipdk/ipdk.env

WORKING_DIR: /root
Generating TLS Certificates...
Generating RSA private key, 4096 bit long modulus (2 primes)
...........................................................................................++++
...............................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................++++
e is 65537 (0x010001)
Generating RSA private key, 4096 bit long modulus (2 primes)
.++++
.....................................................................................................................................................................................................................++++
e is 65537 (0x010001)
Signature ok
subject=C = US, ST = CA, L = Menlo Park, O = Open Networking Foundation, OU = Stratum, CN = localhost
Getting CA Private Key
Generating RSA private key, 4096 bit long modulus (2 primes)
............................................................................................................................................++++
.++++
e is 65537 (0x010001)
Signature ok
subject=C = US, ST = CA, L = Menlo Park, O = Open Networking Foundation, OU = Stratum, CN = Stratum client certificate
Getting CA Private Key
Deleting old installed certificates
Certificates generated and installed successfully in  /usr/share/stratum/certs/
root@c75e8bbdcbac:~/scripts# 
```

The IPDK instructions suggest the command below to verify that there
is a process named `infrap4d` running.

In the container:
```bash
root@c75e8bbdcbac:~/scripts# ps -ef | grep infrap4d
root          47       1 99 12:35 ?        00:02:06 /root/networking-recipe/install/sbin/infrap4d
root         113      84  0 12:37 pts/1    00:00:00 grep --color=auto infrap4d
```

It looks like it is.  Now try running the demo bash script to see what
happens.

In the container:
```bash
root@c75e8bbdcbac:~/scripts# /root/scripts/rundemo_TAP_IO.sh

[ ... most of output omitted here.  See link below for file containing full example output when things are working as expected ... ]

Programming P4 pipeline


Ping from TAP0 port to TAP1 port

PING 2.2.2.2 (2.2.2.2) 56(84) bytes of data.
64 bytes from 2.2.2.2: icmp_seq=1 ttl=64 time=0.119 ms
64 bytes from 2.2.2.2: icmp_seq=2 ttl=64 time=0.121 ms
64 bytes from 2.2.2.2: icmp_seq=3 ttl=64 time=0.097 ms
64 bytes from 2.2.2.2: icmp_seq=4 ttl=64 time=0.126 ms
64 bytes from 2.2.2.2: icmp_seq=5 ttl=64 time=0.120 ms

--- 2.2.2.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4088ms
rtt min/avg/max/mdev = 0.097/0.116/0.126/0.010 ms
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=64 time=0.092 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=64 time=0.141 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=64 time=0.098 ms
64 bytes from 1.1.1.1: icmp_seq=4 ttl=64 time=0.094 ms
64 bytes from 1.1.1.1: icmp_seq=5 ttl=64 time=0.146 ms

--- 1.1.1.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4092ms
rtt min/avg/max/mdev = 0.092/0.114/0.146/0.024 ms
root@c75e8bbdcbac:~/scripts# 
```

That looks like success!  [Here](output-rundemo_TAP_IO.txt) is the
full example output from a working IPDK installation.

Note that very early in running the script `rundemo_TAP_IO.sh`, it
kills any `infrap4d` process that may be running, and also deletes the
network namespaces `VM0` and `VM1` if they exist.  Later in the script
it creates new network namespaces with those names.  Thus if you want
to do things like run `tcpdump` to capture packets into and/or out of
`infrap4d`, you need to run those `tcpdump` commands after the script
is started, but before the packets start flowing.

Even better, you can create your own script based upon the contents of
`rundemo_TAP_IO.sh` that sets things up like running infrap4d and
creating namespaces and interfaces, but doesn't send any packets.
Several such script have already been written that you can use for
this, described in other articles in this collection.

