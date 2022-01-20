#include "before-ingress.p4"

{
    @name(".foo") action act1() {
        hdr.ethernet.etherType = hdr.ethernet.etherType >> 2;
    }
    @name(".foo") action act2() {
        hdr.ethernet.etherType = hdr.ethernet.etherType << 3;
    }
    table t1 {
        key = { hdr.ethernet.etherType : exact; }
        actions = { act1; act2; NoAction; }
        const default_action = NoAction;
    }
    apply {
        t1.apply();
    }
}

#include "after-ingress.p4"
