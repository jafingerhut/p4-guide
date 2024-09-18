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
    @name("ingressImpl.i") bit<8> i_0;
    @hidden action loopvarexprsnotconstant1l51() {
        n_0 = n_0 + 8w1;
    }
    @hidden action loopvarexprsnotconstant1l48() {
        n_0 = 8w0;
    }
    @hidden action loopvarexprsnotconstant1l53() {
        hdr.ethernet.srcAddr[15:8] = n_0;
        stdmeta.egress_spec = 9w1;
    }
    @hidden table tbl_loopvarexprsnotconstant1l48 {
        actions = {
            loopvarexprsnotconstant1l48();
        }
        const default_action = loopvarexprsnotconstant1l48();
    }
    @hidden table tbl_loopvarexprsnotconstant1l51 {
        actions = {
            loopvarexprsnotconstant1l51();
        }
        const default_action = loopvarexprsnotconstant1l51();
    }
    @hidden table tbl_loopvarexprsnotconstant1l53 {
        actions = {
            loopvarexprsnotconstant1l53();
        }
        const default_action = loopvarexprsnotconstant1l53();
    }
    apply {
        tbl_loopvarexprsnotconstant1l48.apply();
        for (i_0 = hdr.ethernet.dstAddr[7:0]; i_0 < hdr.ethernet.dstAddr[15:8]; i_0 = i_0 + 8w1) {
            tbl_loopvarexprsnotconstant1l51.apply();
        }
        tbl_loopvarexprsnotconstant1l53.apply();
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
