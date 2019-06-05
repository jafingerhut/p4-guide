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

// Inspired by example program snippet from Nate Foster here:
// https://github.com/p4lang/p4-spec/issues/361#issuecomment-318515644

typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

struct headers_t {
    ethernet_t    ethernet;
}

struct metadata_t {
}

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

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control IdxUpdater(in bit<32> idx);

control leaf_ctrl(in bit<32> idx) {
    counter(256, CounterType.packets) c;
    apply {
        c.count(idx);
    }
}

control ctrl1(in bit<32> idx)(IdxUpdater iupd) {
    apply {
        iupd.apply(idx);
    }
}

control ctrl2(in bit<32> idx)(IdxUpdater iupd) {
    apply {
        iupd.apply(idx+1);
        iupd.apply(idx+2);
    }
}

control ctrl3(in bit<32> idx)(IdxUpdater iupd1, IdxUpdater iupd2) {
    apply {
        iupd1.apply(idx+10);
        iupd2.apply(idx+20);
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    leaf_ctrl() my_leaf;
    ctrl1(my_leaf) ctrl1_inst;
    ctrl2(my_leaf) ctrl2_inst;
    ctrl3(ctrl1_inst, ctrl2_inst) ctrl3_inst;
    apply {
        stdmeta.egress_spec = 0;
        ctrl3_inst.apply((bit<32>) hdr.ethernet.dstAddr[7:0]);
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{
    apply { }
}

control updateChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control deparserImpl(packet_out packet,
                     in headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
    }
}

// This program should create a graph of extern object, control,
// parser, and package instantiations that looks like this, where a
// directed edge from instantiation A to B means that B is in some way
// called by A, e.g. via a method call for an extern object B, or an
// apply call for a control or parser B.

//           main (type V1Switch, package)
//             |
//             |
//     +-------+-+-----------+------+---- ... also updateChecksum,
//     |         |           |      |              deparserImpl
//     |         V           |      V
//     |  verifyChecksum     |  egressImpl
//     |      (type          |    (type
//     |   verifyChecksum,   |  egressImpl,
//     |      control)       |    control)
//     V                     V
// parserImpl           ingressImpl
//   (type                (type
//  parserImpl,         ingressImpl,
//   parser)              control)
//                           |
//          +----------+-----+------+--+
//          |          |            |  |
//          |      ctrl3_inst       |  |
//          | (type ctrl3, control) |  |
//          |      /   |   \        |  |
//          |     /    |    \       |  |
//          |    /     |     \      |  |
//          |   /      |      \     |  |
//          |  |       |       |    |  |
//          V  V       |       V    V  |
//         ctrl1_inst  |   ctrl2_inst  |
//        (type ctrl1, |  (type ctrl2, |
//          control)   |    control)   |
//             |       |       |      /
//              \      |      / ------
//               \     |     / /
//                \    |    / /
//                 \   |   / /
//                  \  |  / /
//                   V V V V
//                  my_leaf
//            (type leaf_ctrl, control)
//                     |
//                     V
//                     c
//          (type counter, extern object)
 

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
