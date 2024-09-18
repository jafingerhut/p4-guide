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
    @name("ingressImpl.p") bit<8> p_0;
    @name("ingressImpl.i") bit<8> i_0;
    @hidden action loopvarinlistelemsmodified2l56() {
        p_0 = hdr.ethernet.dstAddr[23:16];
    }
    @hidden action loopvarinlistelemsmodified2l58() {
        p_0 = ~hdr.ethernet.dstAddr[23:16];
    }
    @hidden action loopvarinlistelemsmodified2l53() {
        n_0 = 8w0;
    }
    @hidden action loopvarinlistelemsmodified2l65() {
        p_0 = 8w64;
    }
    @hidden action loopvarinlistelemsmodified2l67() {
        p_0 = 8w1;
    }
    @hidden action loopvarinlistelemsmodified2l62() {
        n_0 = n_0 + i_0;
    }
    @hidden action loopvarinlistelemsmodified2l77() {
        hdr.ethernet.srcAddr[7:0] = n_0;
        hdr.ethernet.srcAddr[15:8] = 8w32;
        hdr.ethernet.srcAddr[23:16] = p_0;
        hdr.ethernet.srcAddr[31:24] = 8w128;
        stdmeta.egress_spec = 9w1;
    }
    @hidden table tbl_loopvarinlistelemsmodified2l53 {
        actions = {
            loopvarinlistelemsmodified2l53();
        }
        const default_action = loopvarinlistelemsmodified2l53();
    }
    @hidden table tbl_loopvarinlistelemsmodified2l56 {
        actions = {
            loopvarinlistelemsmodified2l56();
        }
        const default_action = loopvarinlistelemsmodified2l56();
    }
    @hidden table tbl_loopvarinlistelemsmodified2l58 {
        actions = {
            loopvarinlistelemsmodified2l58();
        }
        const default_action = loopvarinlistelemsmodified2l58();
    }
    @hidden table tbl_loopvarinlistelemsmodified2l62 {
        actions = {
            loopvarinlistelemsmodified2l62();
        }
        const default_action = loopvarinlistelemsmodified2l62();
    }
    @hidden table tbl_loopvarinlistelemsmodified2l65 {
        actions = {
            loopvarinlistelemsmodified2l65();
        }
        const default_action = loopvarinlistelemsmodified2l65();
    }
    @hidden table tbl_loopvarinlistelemsmodified2l67 {
        actions = {
            loopvarinlistelemsmodified2l67();
        }
        const default_action = loopvarinlistelemsmodified2l67();
    }
    @hidden table tbl_loopvarinlistelemsmodified2l77 {
        actions = {
            loopvarinlistelemsmodified2l77();
        }
        const default_action = loopvarinlistelemsmodified2l77();
    }
    apply {
        tbl_loopvarinlistelemsmodified2l53.apply();
        if (hdr.ethernet.etherType == 16w5) {
            tbl_loopvarinlistelemsmodified2l56.apply();
        } else {
            tbl_loopvarinlistelemsmodified2l58.apply();
        }
        for (@name("ingressImpl.i") bit<8> i_0 in (list<bit<8>>){8w1,8w2,hdr.ethernet.dstAddr[15:8],p_0,hdr.ethernet.dstAddr[31:24]}) {
            tbl_loopvarinlistelemsmodified2l62.apply();
            if (hdr.ethernet.etherType == 16w5) {
                tbl_loopvarinlistelemsmodified2l65.apply();
            } else {
                tbl_loopvarinlistelemsmodified2l67.apply();
            }
        }
        tbl_loopvarinlistelemsmodified2l77.apply();
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
