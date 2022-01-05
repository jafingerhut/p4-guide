#include <core.p4>
#include <v1model.p4>

struct headers_t {
}

struct metadata_t {
}

parser parserImpl(
    packet_in pkt,
    out headers_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t stdmeta)
{
    state start {
        transition accept;
    }
}

control verifyChecksum(
    inout headers_t hdr,
    inout metadata_t meta)
{
    apply { }
}

control ingressImpl(
    inout headers_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t stdmeta)
{
    apply {
        bit<9> a;
        bit<9> b;
        bit<9> c;

        // Note: P4 precedence of + is higher than ^,
        // Thus this:         a + 5 ^ a
        // is equal to this: (a + 5) ^ a

        // That is important when reading the output from passes of
        // the compiler, which do not print parentheses when they are
        // unnecessary according to operator precedence rules.

        // b becomes initialized, even though a is still uninitialized
        b = a + 5;
        c = b;
        if (stdmeta.ingress_port == 5) {
            c = c ^ (b ^ 1);
        } else {
            c = c << 1;
        }
        stdmeta.egress_spec = c;
    }
}

control egressImpl(
    inout headers_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t stdmeta)
{
    apply { }
}

control updateChecksum(
    inout headers_t hdr,
    inout metadata_t meta)
{
    apply { }
}

control deparserImpl(
    packet_out pkt,
    in headers_t hdr)
{
    apply {
    }
}

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
