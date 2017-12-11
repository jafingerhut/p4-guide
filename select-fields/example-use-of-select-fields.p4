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
#include <v1model.p4>


typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

header data_in_t {
    bit<64> data;
    bit<16> select_control_expanded;
}

header data_out_t {
    bit<32> data;
}

struct fwd_metadata_t {
}

struct metadata {
    fwd_metadata_t fwd_metadata;
}

struct headers {
    ethernet_t       ethernet;
    data_in_t        data_in;
    data_out_t       data_out;
}


//#include "select-fields1.p4"
//#include "select-fields2.p4"
//#include "select-fields3.p4"
#include "select-fields4.p4"

// This version compiles with p4c-bm2-ss to a bmv2 JSON file, but one
// that p4pktgen gives an error message on.  The error occurs because
// multiple ingress pipeline condition nodes have the same source
// info, so if we tried to analyze the console log output from
// simple_switch, the source info included when evaluating conditions
// would not be sufficient to determine which node was being executed,
// only one of potentially many different condition nodes could be
// inferred.

// One way to improve on this is to make simple_switch include the
// node name in its console log output when evaluating if conditions,
// and modify p4pktgen to parse and use that node name.

//#include "select-fields3.p4"


parser IngressParserImpl(packet_in buffer,
                         out headers hdr,
                         inout metadata user_meta,
                         inout standard_metadata_t standard_metadata)
{
    state start {
        buffer.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_data_in;
            default: accept;
        }
    }
    state parse_data_in {
        buffer.extract(hdr.data_in);
        buffer.extract(hdr.data_out);
        transition accept;
    }
}


control ingress(inout headers hdr,
                inout metadata user_meta,
                inout standard_metadata_t standard_metadata) {
//    Select8BitFields_8_to_4_pure_function() sf;
//    bit<12> select_control;
//    bit<32> selected_data;
    Select8BitFields_4_to_2_pure_function() sf;
    bit<4> select_control;
    bit<16> selected_data;
    apply {
        if (hdr.data_in.isValid() && hdr.data_out.isValid()) {
            // This assignment is here simply to make the input
            // select_control easier to read in hexadecimal.
//            select_control = (
//                hdr.data_in.select_control_expanded[14:12] ++
//                hdr.data_in.select_control_expanded[10:8] ++
//                hdr.data_in.select_control_expanded[6:4] ++
//                hdr.data_in.select_control_expanded[2:0]
//            );
            select_control = (
                hdr.data_in.select_control_expanded[5:4] ++
                hdr.data_in.select_control_expanded[1:0]
            );
            sf.apply(hdr.data_in.data[31:0], select_control,
                selected_data);
            // The == 0 and == 0xff conditions are here to cause
            // p4pktgen to pick more distinctive-looking values for
            // input packets than those, when finding a solution for
            // the false branch of the 'if' condition.
            if (selected_data != hdr.data_out.data[15:0] ||
//                selected_data[31:24] == 0 || selected_data[31:24] == 0xff ||
//                selected_data[23:16] == 0 || selected_data[23:16] == 0xff ||
                selected_data[15:8] == 0 || selected_data[15:8] == 0xff ||
                selected_data[7:0] == 0 || selected_data[7:0] == 0xff)
            {
                exit;
            }
        }
    }
}

control egress(inout headers hdr,
               inout metadata user_meta,
               inout standard_metadata_t standard_metadata)
{
    apply { }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.data_in);
        packet.emit(hdr.data_out);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

V1Switch(IngressParserImpl(),
         verifyChecksum(),
         ingress(),
         egress(),
         computeChecksum(),
         DeparserImpl()) main;
