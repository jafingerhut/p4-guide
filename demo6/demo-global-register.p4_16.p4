/* -*- mode: P4_16 -*- */
/*
Copyright 2020 Cisco Systems, Inc.

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

struct metadata_t {
}

struct headers_t {
    ethernet_t ethernet;
}

typedef bit<32> PktCount_t;

// P4_16 the language allows implementations to have instantiations of
// extern objects at the top level, and access them from multiple
// different controls in your program.  This demo program shows that
// the BMv2 software switch does support this, with the same register
// array being updated in both ingress and egress controls.

// WARNING: While the P4_16 language specification allows
// implementations to do this, it does not _require_ that all
// implementations support this, and it is very likely that several do
// not.  Check with your P4 device vendor before expecting that code
// like this will work on their device.  There are perfectly valid
// reasons of implementation complexity and/or cost that a target
// device might not support this.  For some details on why, see the
// appendix named "Multi-pipeline PSA devices" in the the Portable
// Switch Architecture specification:

// https://p4.org/p4-spec/docs/PSA-v1.1.0.html#appendix-multi-pipeline-psa-devices

register<PktCount_t>(8) approx_queue_depth_pkts;

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    state start {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<3> output_port;
    PktCount_t tmp_count;

    apply {

        // Note: In the P4_16 v1model architecture,
        // stdmeta.egress_spec is writable and readable standard
        // metadata field, intended only for access during ingress
        // processing, and to control which output port the packet
        // will be directed to.

        // stdmeta.egress_port is intended to be read only, and only
        // during egress processing, and it contains the output port
        // that the packet is destined to.

        // See v1model documentation here for more details:
        // https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md
        
        // There is nothing magic about having 3 bits for output_port
        // in this example program.  This is an example for an
        // imagined device that has 8 switch ports, numbered 0 to 7.
        output_port = hdr.ethernet.dstAddr[2:0];

        stdmeta.egress_spec = (bit<9>) output_port;

        // Increment count of packets destined for port output_port.

        // Note: Doing this for multicast packets would require
        // incrementing multiple entries in the register array in
        // general, and many P4 implementations do not make it
        // straightforward to do this.  We are not attempting to solve
        // that problem in this example program.

        approx_queue_depth_pkts.read(tmp_count, (bit<32>) output_port);
        tmp_count = tmp_count + 1;
        log_msg("Ingress incremented approx_queue_depth_pkts[p] for p={} to {}",
            {output_port, tmp_count});
        approx_queue_depth_pkts.write((bit<32>) output_port, tmp_count);
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{
    bit<3> output_port;
    PktCount_t tmp_count;

    apply {
        output_port = (bit<3>) stdmeta.egress_port;
        
        // Decrement count of packets destined for port output_port.
        approx_queue_depth_pkts.read(tmp_count, (bit<32>) output_port);
        tmp_count = tmp_count - 1;
        log_msg("Egress decremented approx_queue_depth_pkts[p] for p={} to {}",
            {output_port, tmp_count});
        approx_queue_depth_pkts.write((bit<32>) output_port, tmp_count);
    }
}

control deparserImpl(packet_out packet,
                     in headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control updateChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
