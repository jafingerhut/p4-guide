action foo (in bit<8> x, out bit<8> y) { y = (x >> 2); }
action foo (inout bit<8> x) { x = (x >> 3); }

#include "before-ingress.p4"

{
    bit<8> tmp1;
    bit<8> tmp2;

    table t1 {
        actions = { NoAction; foo; }
        key = { hdr.ethernet.etherType: exact; }
        default_action = foo(tmp1, tmp2);
        size = 512;
    }
    table t2 {
        actions = { NoAction; foo; }
        key = { hdr.ethernet.etherType: exact; }
        default_action = foo(tmp1);
        size = 128;
    }
    apply {
        tmp1 = hdr.ethernet.srcAddr[7:0];
        tmp2 = hdr.ethernet.dstAddr[7:0];
        t1.apply();
        t2.apply();
        // This is here simply to ensure that the compiler cannot
        // optimize away the effects of t1 and t2, which can only
        // assign values to variables tmp1 and tmp2.
        hdr.ethernet.etherType = (bit<16>) (tmp1 - tmp2);
    }
}

#include "after-ingress.p4"
