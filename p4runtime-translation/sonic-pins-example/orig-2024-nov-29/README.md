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


# In what ways does the original code use P4 `type` and the `p4runtime_translation` annotation?

Also how often it uses `typedef`, which I show mostly for my own
curiosity.  It has little to do directly with the use of the
`p4runtime_translation` annotation.

```bash
$ find sai_p4 ! -type d | xargs egrep '\btypedef\b'
sai_p4/fixed/metadata.p4:typedef bit<ROUTE_METADATA_BITWIDTH> route_metadata_t;
sai_p4/fixed/metadata.p4:typedef bit<ACL_METADATA_BITWIDTH> acl_metadata_t;
sai_p4/fixed/metadata.p4:typedef bit<MULTICAST_GROUP_ID_BITWIDTH> multicast_group_id_t;
sai_p4/fixed/metadata.p4:typedef bit<REPLICA_INSTANCE_BITWIDTH> replica_instance_t;
sai_p4/fixed/headers.p4:typedef bit<48> ethernet_addr_t;
sai_p4/fixed/headers.p4:typedef bit<32> ipv4_addr_t;
sai_p4/fixed/headers.p4:typedef bit<128> ipv6_addr_t;
sai_p4/fixed/headers.p4:typedef bit<12> vlan_id_t;
sai_p4/fixed/headers.p4:typedef bit<16> ether_type_t;
```

Now `type`:

```bash
$ find sai_p4 ! -type d | xargs egrep '\btype\b'
sai_p4/instantiations/google/acl_ingress.p4:      headers.icmp.type : ternary @name("icmp_type") @id(19)
sai_p4/instantiations/google/acl_ingress.p4:      headers.icmp.type : ternary @name("icmpv6_type") @id(14)
sai_p4/instantiations/google/acl_ingress.p4:      headers.icmp.type : ternary
sai_p4/instantiations/google/acl_ingress.p4:      headers.icmp.type : ternary
sai_p4/instantiations/google/acl_pre_ingress.p4:      headers.icmp.type : ternary
sai_p4/fixed/metadata.p4:type bit<NEXTHOP_ID_BITWIDTH> nexthop_id_t;
sai_p4/fixed/metadata.p4:type bit<TUNNEL_ID_BITWIDTH> tunnel_id_t;
sai_p4/fixed/metadata.p4:type bit<WCMP_GROUP_ID_BITWIDTH> wcmp_group_id_t;
sai_p4/fixed/metadata.p4:type bit<VRF_BITWIDTH> vrf_id_t;
sai_p4/fixed/metadata.p4:type bit<ROUTER_INTERFACE_ID_BITWIDTH> router_interface_id_t;
sai_p4/fixed/metadata.p4:type bit<PORT_BITWIDTH> port_id_t;
sai_p4/fixed/metadata.p4:type bit<MIRROR_SESSION_ID_BITWIDTH> mirror_session_id_t;
sai_p4/fixed/metadata.p4:type bit<QOS_QUEUE_BITWIDTH> qos_queue_t;
sai_p4/fixed/metadata.p4:  // applied regardless of instance type of a packet.
sai_p4/fixed/metadata.p4:  // has port_id_t as the type for all fields that match on ports. This allows
sai_p4/fixed/ids.h:// type: INSERT
sai_p4/fixed/packet_io.p4:      // Cast is necessary, because v1model does not define port using `type`.
sai_p4/fixed/routing.p4:  // Models SAI IPMC entries of type (*,G) whose destination is an IPv4 address.
sai_p4/fixed/routing.p4:  // Models SAI IPMC entries of type (*,G) whose destination is an IPv6 address.
sai_p4/fixed/routing.p4:    // Cast is necessary, because v1model does not define port using `type`.
sai_p4/fixed/headers.p4:  bit<8> type;
sai_p4/fixed/ingress_cloning.p4:  // | type       | match fields             | action           | entry count  |
```

Trim that list of result lines to actual uses of the P4_16 `type`
keyword and type-defining mechanism.  I did this manually, since I
know of no easily automated way to do it.

```bash
sai_p4/fixed/metadata.p4:type bit<NEXTHOP_ID_BITWIDTH> nexthop_id_t;
sai_p4/fixed/metadata.p4:type bit<TUNNEL_ID_BITWIDTH> tunnel_id_t;
sai_p4/fixed/metadata.p4:type bit<WCMP_GROUP_ID_BITWIDTH> wcmp_group_id_t;
sai_p4/fixed/metadata.p4:type bit<VRF_BITWIDTH> vrf_id_t;
sai_p4/fixed/metadata.p4:type bit<ROUTER_INTERFACE_ID_BITWIDTH> router_interface_id_t;
sai_p4/fixed/metadata.p4:type bit<PORT_BITWIDTH> port_id_t;
sai_p4/fixed/metadata.p4:type bit<MIRROR_SESSION_ID_BITWIDTH> mirror_session_id_t;
sai_p4/fixed/metadata.p4:type bit<QOS_QUEUE_BITWIDTH> qos_queue_t;
```

And the `p4runtime_translation` annotation:

```bash
$ find sai_p4 ! -type d | xargs egrep p4runtime_translation
sai_p4/instantiations/google/bitwidths.p4:  // Number of bits used for types that use @p4runtime_translation("", string).
sai_p4/fixed/metadata.p4:// BMv2 does not support @p4runtime_translation.
sai_p4/fixed/metadata.p4:@p4runtime_translation("", string)
sai_p4/fixed/metadata.p4:@p4runtime_translation("", string)
sai_p4/fixed/metadata.p4:@p4runtime_translation("", string)
sai_p4/fixed/metadata.p4:@p4runtime_translation("", string)
sai_p4/fixed/metadata.p4:@p4runtime_translation_mappings({
sai_p4/fixed/metadata.p4:@p4runtime_translation("", string)
sai_p4/fixed/metadata.p4:@p4runtime_translation("", string)
sai_p4/fixed/metadata.p4:@p4runtime_translation("", string)
sai_p4/fixed/metadata.p4:@p4runtime_translation("", string)
```

Here are a list of `type` names, and which ones have a
`p4runtime_translation` on them, and how often they appear in the
source code:

Columns:

+ A - Number of uses of the type name in the P4 code, not counting
  comments, and not counting the line defining the type.
+ B - The type name.
+ C - The underlying type.

```
 4 nexthop_id_t          bit<NEXTHOP_ID_BITWIDTH>
 2 tunnel_id_t           bit<TUNNEL_ID_BITWIDTH>
 3 wcmp_group_id_t       bit<WCMP_GROUP_ID_BITWIDTH>
 2 vrf_id_t              bit<VRF_BITWIDTH>
 4 router_interface_id_t bit<ROUTER_INTERFACE_ID_BITWIDTH>
16 port_id_t             bit<PORT_BITWIDTH>
 2 mirror_session_id_t   bit<MIRROR_SESSION_ID_BITWIDTH>
 9 qos_queue_t           bit<QOS_QUEUE_BITWIDTH>
```

All of these type definitions have an annotation of
`@p4runtime_translation("", string)`, unless the preprocessor symbol
`PLATFORM_BMV2` is defined, in which case there is no such annotation
on any type definitions.

```bash
cd sai_p4/instantiations/google
for p in tor wbb middleblock fabric_border_router
do
    p4c --target bmv2 --arch v1model $p.p4 --p4runtime-files $p.txtpb
done
```
