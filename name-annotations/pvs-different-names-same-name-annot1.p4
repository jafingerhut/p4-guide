#include "before-parser.p4"

{
    @name("foo") value_set<bit<16>>(4) pvs1;
    @name("foo") value_set<bit<16>>(4) pvs2;
    
    state start {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.etherType) {
            pvs1: st1;
            pvs2: st2;
            default: accept;
        }
    }

    state st1 {
        transition accept;
    }

    state st2 {
        transition accept;
    }
}

#include "after-parser.p4"
