# Copy the subset of files from sonic-pins repo that are needed to compile v1model P4 source files

Steps followed on 2024-Nov-29 to copy files into this directory and
its subdirectories are detailed below.

```bash
$ git clone https://github.com/sonic-net/sonic-pins/

$ cd sonic-pins

$ git log -n 1 | cat
commit d4495ee2da1cdb5a46e8454050a64fdc1c9a4e01
Author: VSuryaprasad-hcl <159443973+VSuryaprasad-HCL@users.noreply.github.com>
Date:   Wed Nov 27 23:09:35 2024 +0000

    [Dvaas] adding Data plane validation header to Dvaas. (#789)
    
    
    
    Co-authored-by: kishanps <kishanps@google.com>

$ cd ..
```

All P4 source files are in sonic-pins/sai_p4 or some subdirectory of
that, so copy that part of the repo here.  Remove the full sonic-pins
repo.

```bash
cp -pr sonic-pins/sai_p4/ .
```

All P4 source files have file names with the suffix `.p4` or `.h`.
Remove all other files.

```bash
find sai_p4 ! -type d | grep -v '\.h$' | grep -v '\.p4$'
```

Many files with a suffix of .h are _not_ included by any P4 source
file.  Try to keep only the ones that are.  To find a complete list of
those that are, one way is to start with this list and remove all of
the duplicates.  I do not have an automated command to do that for
you:

```bash
find . -name '*.p4' | xargs grep include | grep '\.h'
```

For the version of the sonic-pins repo, these are the only .h files
included from P4 source files:

```bash
ids.h
roles.h
versions.h
bmv2_intrinsics.h
```

Remove all .h files with names that are not one in that list:

```bash
find . -name '*.h' | egrep -v '(ids|roles|versions|bmv2_intrinsics)\.h' | xargs rm
```

Run this command once to remove all directories that contain no files.
Run it again if you wish to remove directories that might have become
empty from running it the previous time.  It will print error messages
about any directories that are not empty, and _not_ remove them.

```bash
find sai_p4 -type d | xargs rmdir
```


# Find and compile those P4 source files that are "top level"

Here is a quick way to find all P4 source files that are "top level"
for the v1model archicture, because they instantiate the package named
V1Switch.

```bash
$ find sai_p4 -name '*.p4' | xargs grep V1Switch
sai_p4/instantiations/google/tor.p4:V1Switch(packet_parser(), verify_ipv4_checksum(), ingress(), egress(),
sai_p4/instantiations/google/wbb.p4:V1Switch(packet_parser(), verify_ipv4_checksum(), ingress(), egress(),
sai_p4/instantiations/google/middleblock.p4:V1Switch(packet_parser(), verify_ipv4_checksum(), ingress(), egress(),
sai_p4/instantiations/google/fabric_border_router.p4:V1Switch(packet_parser(), verify_ipv4_checksum(), ingress(), egress(),
```

Verify that each of those files can be compiled without errors (even
if there might be many warnings):

I built this version of p4c from soruce code on 2024-Nov-07:

```bash
$ p4c --version
p4c 1.2.4.17 (SHA: b29334c8f BUILD: Release)
```

```bash
$ cd sai_p4/instantiations/google

$ p4c --target bmv2 --arch v1model tor.p4
[ ... long output with many warnings omitted ... ]
$ wc tor.json
 12447  30043 362892 tor.json

$ p4c --target bmv2 --arch v1model wbb.p4
[ Note: NO warnings or errors at all! ]
$ wc wbb.json 
 1025  2508 27811 wbb.json

$ p4c --target bmv2 --arch v1model middleblock.p4
[ ... long output with many warnings omitted ... ]
$ wc middleblock.json 
 12664  30557 368377 middleblock.json

$ p4c --target bmv2 --arch v1model fabric_border_router.p4
[ ... long output with many warnings omitted ... ]
$ wc fabric_border_router.json 
 12341  29814 359909 fabric_border_router.json
```
