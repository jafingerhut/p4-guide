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
    @name("ingressImpl.k1") bit<8> k1_0;
    @name("ingressImpl.j1") bit<8> j1_0;
    @name("ingressImpl.k2") bit<8> k2_0;
    @name("ingressImpl.n") bit<8> n_1;
    @name("ingressImpl.j2") bit<8> j2_0;
    apply {
        n_0 = hdr.ethernet.srcAddr[15:8];
        k1_0 = n_0 + 8w1;
        j1_0 = n_0 + 8w8;
        k2_0 = n_0 + 8w1;
        n_1 = n_0 + 8w5;
        j2_0 = n_1 + 8w3;
        if (k1_0 != k2_0) {
            hdr.ethernet.dstAddr[47:47] = 1w1;
        } else {
            hdr.ethernet.dstAddr[47:47] = 1w0;
        }
        if (j1_0 != j2_0) {
            hdr.ethernet.dstAddr[46:46] = 1w1;
        } else {
            hdr.ethernet.dstAddr[46:46] = 1w0;
        }
        if (n_1 != k2_0) {
            hdr.ethernet.dstAddr[45:45] = 1w1;
        } else {
            hdr.ethernet.dstAddr[45:45] = 1w0;
        }
        hdr.ethernet.srcAddr[23:16] = k2_0;
        hdr.ethernet.srcAddr[15:8] = n_1;
        hdr.ethernet.srcAddr[7:0] = j2_0;
        stdmeta.egress_spec = 9w1;
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
