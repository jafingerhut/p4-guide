#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> eth_type;
}

header H {
    bit<0> b0a;
    bit<8> b8;
    bit<0> b0b;
    // commented out, because p4test does not allow type int with 0 width
    //int<0> i0a;
    int<8> i8;
}

struct Meta {}

struct Headers {
    ethernet_t eth_hdr;
    H          h;
}

parser p(packet_in pkt, out Headers hdr, inout Meta m, inout standard_metadata_t sm) {
    state start {
        transition parse_hdrs;
    }
    state parse_hdrs {
        pkt.extract(hdr.eth_hdr);
        pkt.extract(hdr.h);
        transition accept;
    }
}

control vrfy(inout Headers h, inout Meta m) { apply {} }
control update(inout Headers h, inout Meta m) { apply {} }

control ingress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {

    action a1(bit<0> x, bit<48> y) {
        h.eth_hdr.dst_addr = y;
        h.h.b0b = x;
    }

    table match_on_bit0_test {
        key = {
            h.eth_hdr.dst_addr: exact;
            h.h.b8: exact;
            h.h.b0b: exact;
        }
        actions = {
            a1;
        }
        size = 16;
    }
    
    apply {
        h.h = {...};
        // p4test allows bit<0> values to be cast to wider bit<W>
        // values with W > 1.  I believe that all such values are cast
        // to a value of 0 with the wider bit value type.
        h.h.b8 = (bit<8>) h.h.b0a;
        if (h.eth_hdr.isValid()) {
            match_on_bit0_test.apply();
        }
        // p4test gives a warning about the next line, because the
        // value 1 "does not fit in 0 bits".  Seems like a reasonable
        // warning.
        h.h.b0a = 1;
        // p4test gives no warning about the following line, even
        // though it is arguable that _no_ value fits into 0 bits, not
        // even 0.  But it seems the p4c implementers have allowed 0
        // to be considered to fit into 0 bits.
        h.h.b0b = 0;
        h.h.i8 = (int<8>) (bit<8>) h.h.b0a;
    }
}

control egress(inout Headers h, inout Meta m, inout standard_metadata_t sm) { apply {} }

control deparser(packet_out b, in Headers h) {
    apply {
        b.emit(h.eth_hdr);
        b.emit(h.h);
    }
}

V1Switch(p(), vrfy(), ingress(), egress(), update(), deparser()) main;
