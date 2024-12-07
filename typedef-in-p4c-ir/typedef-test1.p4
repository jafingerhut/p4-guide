/*
Copyright 2020 Andy Fingerhut

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


@p4runtime_translation("co2.com/EthAddr", 50)
typedef bit<48> Eth0_t;
type    bit<48> Eth1_t;
@p4runtime_translation("mycompany.com/EthernetAddress", 49)
type    bit<48> Eth2_t;

header ethernet_t {
    Eth0_t  addr0;
    Eth1_t  addr1;
    bit<16> etherType;
    Eth2_t  addr2;
}

struct headers_t {
    ethernet_t ethernet;
}

struct metadata_t {
}

parser ParserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    state start {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

control ingress(inout headers_t hdr,
                inout metadata_t meta,
                inout standard_metadata_t stdmeta)
{
    Eth0_t local0 = (bit<48>) stdmeta.ingress_port;
    Eth1_t local1 = 0;
    Eth2_t local2 = 0;
    bit<48> local3 = 0;
    
    action set_headers(Eth0_t addr0, Eth1_t addr1, Eth2_t addr2, bit<16> etherType) {
        hdr.ethernet.addr0 = addr0;
        hdr.ethernet.addr1 = addr1;
        hdr.ethernet.addr2 = addr2;
        hdr.ethernet.etherType = etherType;
    }
    action my_drop() {
        mark_to_drop(stdmeta);
    }
    table custom_table {
        key = {
            hdr.ethernet.addr0 : exact;
            hdr.ethernet.addr1 : exact;
            hdr.ethernet.addr2 : exact;
            hdr.ethernet.addr0 & 48w0xffff : exact;
            (bit<48>) hdr.ethernet.addr1 & 48w0xffff : exact @name("foo");
            local0: exact;
            local1: exact;
            local2: exact;
            local3: exact;
        }
        actions = {
            set_headers;
            my_drop;
        }
        default_action = my_drop;
    }
    apply {
        if (hdr.ethernet.isValid()) {
            custom_table.apply();
        }
    }
}

control egress(inout headers_t hdr,
               inout metadata_t meta,
               inout standard_metadata_t stdmeta)
{
    apply { }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.ethernet);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

V1Switch(ParserImpl(),
         verifyChecksum(),
         ingress(),
         egress(),
         computeChecksum(),
         DeparserImpl()) main;

