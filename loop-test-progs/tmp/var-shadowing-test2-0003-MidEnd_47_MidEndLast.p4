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
    @name("ingressImpl.n") bit<8> n_1;
    @name("ingressImpl.j2") bit<8> j2_0;
    @hidden action varshadowingtest2l61() {
        hdr.ethernet.dstAddr[47:47] = 1w1;
    }
    @hidden action varshadowingtest2l63() {
        hdr.ethernet.dstAddr[47:47] = 1w0;
    }
    @hidden action varshadowingtest2l55() {
        n_1 = hdr.ethernet.srcAddr[15:8] + 8w5;
        j2_0 = hdr.ethernet.srcAddr[15:8] + 8w5 + 8w3;
    }
    @hidden action varshadowingtest2l68() {
        hdr.ethernet.dstAddr[46:46] = 1w1;
    }
    @hidden action varshadowingtest2l70() {
        hdr.ethernet.dstAddr[46:46] = 1w0;
    }
    @hidden action varshadowingtest2l73() {
        hdr.ethernet.dstAddr[45:45] = 1w1;
    }
    @hidden action varshadowingtest2l77() {
        hdr.ethernet.dstAddr[45:45] = 1w0;
    }
    @hidden action varshadowingtest2l79() {
        hdr.ethernet.srcAddr[23:16] = hdr.ethernet.srcAddr[15:8] + 8w1;
        hdr.ethernet.srcAddr[15:8] = n_1;
        hdr.ethernet.srcAddr[7:0] = j2_0;
        stdmeta.egress_spec = 9w1;
    }
    @hidden table tbl_varshadowingtest2l55 {
        actions = {
            varshadowingtest2l55();
        }
        const default_action = varshadowingtest2l55();
    }
    @hidden table tbl_varshadowingtest2l61 {
        actions = {
            varshadowingtest2l61();
        }
        const default_action = varshadowingtest2l61();
    }
    @hidden table tbl_varshadowingtest2l63 {
        actions = {
            varshadowingtest2l63();
        }
        const default_action = varshadowingtest2l63();
    }
    @hidden table tbl_varshadowingtest2l68 {
        actions = {
            varshadowingtest2l68();
        }
        const default_action = varshadowingtest2l68();
    }
    @hidden table tbl_varshadowingtest2l70 {
        actions = {
            varshadowingtest2l70();
        }
        const default_action = varshadowingtest2l70();
    }
    @hidden table tbl_varshadowingtest2l73 {
        actions = {
            varshadowingtest2l73();
        }
        const default_action = varshadowingtest2l73();
    }
    @hidden table tbl_varshadowingtest2l77 {
        actions = {
            varshadowingtest2l77();
        }
        const default_action = varshadowingtest2l77();
    }
    @hidden table tbl_varshadowingtest2l79 {
        actions = {
            varshadowingtest2l79();
        }
        const default_action = varshadowingtest2l79();
    }
    apply {
        tbl_varshadowingtest2l55.apply();
        if (hdr.ethernet.srcAddr[15:8] + 8w1 != hdr.ethernet.srcAddr[15:8] + 8w1) {
            tbl_varshadowingtest2l61.apply();
        } else {
            tbl_varshadowingtest2l63.apply();
        }
        if (hdr.ethernet.srcAddr[15:8] + 8w8 != hdr.ethernet.srcAddr[15:8] + 8w5 + 8w3) {
            tbl_varshadowingtest2l68.apply();
        } else {
            tbl_varshadowingtest2l70.apply();
        }
        if (hdr.ethernet.srcAddr[15:8] + 8w5 != hdr.ethernet.srcAddr[15:8] + 8w1) {
            tbl_varshadowingtest2l73.apply();
        } else {
            tbl_varshadowingtest2l77.apply();
        }
        tbl_varshadowingtest2l79.apply();
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
