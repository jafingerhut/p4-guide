#include <core.p4>
#define V1MODEL_VERSION 20180101
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

parser parserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta, inout standard_metadata_t stdmeta) {
    state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
}

control ingressImpl(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t stdmeta) {
    @name("ingressImpl.n") bit<8> n_0;
    @hidden action loopvarcanbedeclaredbeforeloop1l52() {
        n_0 = hdr.ethernet.srcAddr[15:8] + 8w3;
        n_0 = hdr.ethernet.srcAddr[15:8] + 8w3 + 8w3;
        n_0 = hdr.ethernet.srcAddr[15:8] + 8w3 + 8w3 + 8w3;
        n_0 = hdr.ethernet.srcAddr[15:8] + 8w3 + 8w3 + 8w3 + 8w3;
        n_0 = hdr.ethernet.srcAddr[15:8] + 8w3 + 8w3 + 8w3 + 8w3 + 8w3;
        n_0 = hdr.ethernet.srcAddr[15:8] + 8w3 + 8w3 + 8w3 + 8w3 + 8w3 + 8w3;
        n_0 = hdr.ethernet.srcAddr[15:8] + 8w3 + 8w3 + 8w3 + 8w3 + 8w3 + 8w3 + 8w3;
        n_0 = hdr.ethernet.srcAddr[15:8] + 8w3 + 8w3 + 8w3 + 8w3 + 8w3 + 8w3 + 8w3 + 8w3;
    }
    @hidden action loopvarcanbedeclaredbeforeloop1l48() {
        n_0 = hdr.ethernet.srcAddr[15:8];
    }
    @hidden action loopvarcanbedeclaredbeforeloop1l54() {
        hdr.ethernet.srcAddr[7:0] = 8w8;
        hdr.ethernet.srcAddr[15:8] = n_0;
        stdmeta.egress_spec = 9w1;
    }
    @hidden table tbl_loopvarcanbedeclaredbeforeloop1l48 {
        actions = {
            loopvarcanbedeclaredbeforeloop1l48();
        }
        const default_action = loopvarcanbedeclaredbeforeloop1l48();
    }
    @hidden table tbl_loopvarcanbedeclaredbeforeloop1l52 {
        actions = {
            loopvarcanbedeclaredbeforeloop1l52();
        }
        const default_action = loopvarcanbedeclaredbeforeloop1l52();
    }
    @hidden table tbl_loopvarcanbedeclaredbeforeloop1l54 {
        actions = {
            loopvarcanbedeclaredbeforeloop1l54();
        }
        const default_action = loopvarcanbedeclaredbeforeloop1l54();
    }
    apply {
        tbl_loopvarcanbedeclaredbeforeloop1l48.apply();
        tbl_loopvarcanbedeclaredbeforeloop1l52.apply();
        tbl_loopvarcanbedeclaredbeforeloop1l54.apply();
    }
}

control egressImpl(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t stdmeta) {
    apply {
    }
}

control deparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

control updateChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

V1Switch<headers_t, metadata_t>(parserImpl(), verifyChecksum(), ingressImpl(), egressImpl(), updateChecksum(), deparserImpl()) main;
