/* -*- mode: P4_16 -*- */
/*
Copyright 2019 Cisco Systems, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

struct fwd_metadata_t {
    bit<32> l2ptr;
}

struct metadata_t {
    fwd_metadata_t fwd_metadata;
}

struct headers_t {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    const bit<16> ETHERTYPE_IPV4 = 0x0800;

    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    action my_drop() {
        mark_to_drop(stdmeta);
        // Skip the rest of ingress processing.
        exit;
    }

    action set_mcast_grp (bit<16> mcast_grp) {
        stdmeta.mcast_grp = mcast_grp;
        // See Section 6.4 of RFC 1112
        hdr.ethernet.dstAddr = (24w0x01005E ++
            ((bit<24>) hdr.ipv4.dstAddr[22:0]));
        // The P4_16 |-| operator is a saturating operation, meaning
        // that since the operands are unsigned integers, the result
        // cannot wrap around below 0 back to the maximum possible
        // value, the way the result of the - operator can.
        hdr.ipv4.ttl = hdr.ipv4.ttl |-| 1;
    }
    table ipv4_mc_route_lookup {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_mcast_grp;
            my_drop;
        }
        const default_action = my_drop;
    }
    
    action set_l2ptr(bit<32> l2ptr) {
        meta.fwd_metadata.l2ptr = l2ptr;
    }
    table ipv4_da_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_l2ptr;
            my_drop;
        }
        const default_action = my_drop;
    }

    action set_dmac_intf(bit<48> dmac, bit<9> intf) {
        hdr.ethernet.dstAddr = dmac;
        stdmeta.egress_spec = intf;
        hdr.ipv4.ttl = hdr.ipv4.ttl |-| 1;
    }
    table mac_da {
        key = {
            meta.fwd_metadata.l2ptr: exact;
        }
        actions = {
            set_dmac_intf;
            my_drop;
        }
        const default_action = my_drop;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            // An IPv4 address with the most significant 4 bits equal
            // to 0xe is a multicast address.
            if (hdr.ipv4.dstAddr[31:28] == 0xe) {
                // In this demo program, we will only look up the
                // destination address in a multicast route table.  A
                // more complete IPv4 multicast routing implementation
                // that supported PIM-SM (Sparse Mode) would typically
                // also have a lookup table that performed exact match
                // on both the IPv4 source and destination addresses.
                ipv4_mc_route_lookup.apply();
            } else {
                ipv4_da_lpm.apply();
                mac_da.apply();
            }
            if (hdr.ipv4.ttl == 0) {
                // Many commercial switches will have an option to
                // send the packet to a controller instead, with rate
                // limiting, for debug/logging of such packets.  We
                // will simply drop them here.
                my_drop();
            }
        } else {
            // A real L2/L3 switch would do something else than this
            // simple demo program does.
            my_drop();
        }
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{
    table dbg1 {
        key = {
            stdmeta.egress_port: exact;
            stdmeta.egress_rid: exact;
        }
        actions = { NoAction; }
        const default_action = NoAction;
    }
    action my_drop() {
        mark_to_drop(stdmeta);
        // Skip the rest of ingress processing.
        exit;
    }
    // In this demo program, assume that it is enough that the
    // packet's outgoing source MAC address is determined solely by
    // the output port.  A switch that supported multiple VLANs might
    // instead determine this via (output port, VLAN), or an
    // switch-internal metadata field called "bridge domain" that
    // identifies each L2 forwarding domain.
    action rewrite_mac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    table send_frame {
        key = {
            stdmeta.egress_port: exact;
        }
        actions = {
            rewrite_mac;
            my_drop;
        }
        const default_action = my_drop;
    }

    apply {
        // This "debug table" is here not to change how the packet is
        // processed, but only to show the values of its table key
        // fields in simple_switch_grpc's log when it is run with the
        // `--log-console` or `--log-file` command line options.  It
        // is effectively a "debug print statement".
        dbg1.apply();

        send_frame.apply();
    }
}

control deparserImpl(packet_out packet,
                     in headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        verify_checksum(hdr.ipv4.isValid() && hdr.ipv4.ihl == 5,
            { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control updateChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        update_checksum(hdr.ipv4.isValid() && hdr.ipv4.ihl == 5,
            { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
