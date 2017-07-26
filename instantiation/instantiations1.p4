/*
Copyright 2017 Cisco Systems, Inc.

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
#include "psa-local-copy.p4"


typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

struct fwd_metadata_t {
}

struct metadata {
    fwd_metadata_t fwd_metadata;
}

#define BYTE_COUNT_SIZE 48
typedef bit<48> ByteCounter_t;
typedef bit<32> PacketCounter_t;
typedef bit<80> PacketByteCounter_t;

const PortId_t NUM_PORTS = 512;

struct headers {
    ethernet_t       ethernet;
}

parser ParserImpl(packet_in buffer,
                  out headers parsed_hdr,
                  inout metadata user_meta,
                  in psa_parser_input_metadata_t istd)
{
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        buffer.extract(parsed_hdr.ethernet);
        transition accept;
    }
}


action nop() {
}

/* control foo1 is instantiated 0 times, because it isn't mentioned
 * anywhere else in the program. */

control foo1(inout headers hdr,
             inout metadata user_meta)
{
    /* reg1 here is also instantiated 0 times, because its containing
     * control foo1 is instantiated 0 times. */
    Register<bit<32>, bit<7>>(64) reg1;
    apply { }
}


/* Note: The parameters of foo2 are the same _types_ as some
 * parameters of the ingress and egress control blocks, but the
 * parameter _names_ are different than their parameter names. */

/* control foo2 is instantiated 2 times, once locally inside of
 * control ingress, and once locally inside of control egress.
 * There are thus also 2 instances of table foo2_table.
 */

control foo2(inout headers my_headers,
             inout metadata meta)
{
    action foo2_action() {
        my_headers.ethernet.dstAddr[40:40] = 1;
    }
    table foo2_table {
        key = {
            my_headers.ethernet.srcAddr : exact;
        }
        actions = {
            foo2_action;
            NoAction;
        }
        default_action = NoAction;
    }
    apply {
        foo2_table.apply();
    }
}


/* While actions can be declared at the top level, tables may not.
 *
 * Tables _must_ be declared inside of a control block.
 *
 * Every time a control is instantiated, it automatically instantiates
 * all of the tables declared within it.  If a control is instantiated
 * more than once, they do _not_ share the same instances of the
 * enclosed tables -- they always each have their own independent
 * instances. */

/*
action foo3_action() {
    my_headers.ethernet.dstAddr[40:40] = 1;
}
table foo3_table {
    key = {
        my_headers.ethernet.srcAddr : exact;
    }
    actions = {
        foo3_action;
        NoAction;
    }
    default_action = NoAction;
}
*/

/* TBD: Is it possible in P4_16 to apply() the _same_ instance of a
 * control from both the ingress and egress control blocks?  If so,
 * how?
 *
 * If it were legal to instantiate a control at the top level of a
 * P4_16 program, then this would be straightforward:
 *
 * control c1() { ... }
 * c1() c1_inst;
 * control ingress() { apply { c1_inst.apply(); } }
 * control egress()  { apply { c1_inst.apply(); } }
 *
 * But the P4_16 v1.0.0 spec explicitly disallows top-level
 * instantiations of controls and parsers.
 *
 * Note: I am not saying I think this is necessary to be able to do in
 * a P4_16 program.  Just wondering if it is possible or impossible
 * using the language as specified in P4_16 v1.0.0 spec. */

control ingress(inout headers hdr,
                inout metadata user_meta,
                PacketReplicationEngine pre,
                in  psa_ingress_input_metadata_t  istd,
                out psa_ingress_output_metadata_t ostd)
{
    Counter<ByteCounter_t, PortId_t>(NUM_PORTS, BYTE_COUNT_SIZE,
        CounterType_t.bytes) port_bytes_in;
    Register<bit<32>, bit<7>>(64) reg1;
    foo2() foo2_inst;
    apply {
        bit<32> tmp;
        port_bytes_in.count(istd.ingress_port,
                            (ByteCounter_t) hdr.ethernet.etherType);
        tmp = reg1.read((bit<7>) istd.ingress_port[5:0]);
        tmp = tmp + 0xdeadbeef;
        reg1.write((bit<7>) istd.ingress_port[5:0], tmp);
        ostd.egress_port = 0;
        foo2_inst.apply(hdr, user_meta);
    }
}

control egress(inout headers hdr,
               inout metadata user_meta,
               BufferingQueueingEngine bqe,
               in  psa_egress_input_metadata_t  istd)
{
    Counter<ByteCounter_t, PortId_t>(NUM_PORTS, BYTE_COUNT_SIZE,
        CounterType_t.bytes) port_bytes_out;
    Meter<bit<9>>(256, MeterType_t.bytes) meter1;
    foo2() foo2_inst;
    apply {
        MeterColor_t c1;
        port_bytes_out.count(istd.egress_port,
                             (ByteCounter_t) hdr.ethernet.etherType);
        c1 = meter1.execute((bit<9>) istd.egress_port[7:0], MeterColor_t.GREEN);
        if (c1 == MeterColor_t.RED) {
            bqe.drop();
        }
        foo2_inst.apply(hdr, user_meta);
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply { }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

PSA_Switch(ParserImpl(),
           verifyChecksum(),
           ingress(),
           egress(),
           computeChecksum(),
           DeparserImpl()) main;
