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
    @hidden action loopvarinlistelemsmodified1l58() {
        n_0 = n_0 + i_0;
    }
    @hidden action loopvarinlistelemsmodified1l53() {
        n_0 = 8w0;
    }
    @hidden action loopvarinlistelemsmodified1l69() {
        hdr.ethernet.srcAddr[7:0] = n_0;
        hdr.ethernet.srcAddr[15:8] = 8w32;
        hdr.ethernet.srcAddr[23:16] = 8w64;
        hdr.ethernet.srcAddr[31:24] = 8w128;
        stdmeta.egress_spec = 9w1;
    }
    @hidden table tbl_loopvarinlistelemsmodified1l53 {
        actions = {
            loopvarinlistelemsmodified1l53();
        }
        const default_action = loopvarinlistelemsmodified1l53();
    }
    @hidden table tbl_loopvarinlistelemsmodified1l58 {
        actions = {
            loopvarinlistelemsmodified1l58();
        }
        const default_action = loopvarinlistelemsmodified1l58();
    }
    @hidden table tbl_loopvarinlistelemsmodified1l69 {
        actions = {
            loopvarinlistelemsmodified1l69();
        }
        const default_action = loopvarinlistelemsmodified1l69();
    }
    apply {
        tbl_loopvarinlistelemsmodified1l53.apply();
        for (@name("ingressImpl.i") bit<8> i_0 in (list<bit<8>>){8w1,8w2,8w4,8w8,8w16}) {
            tbl_loopvarinlistelemsmodified1l58.apply();
        }
        tbl_loopvarinlistelemsmodified1l69.apply();
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
