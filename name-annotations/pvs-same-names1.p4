#include "before-parser.p4"

{
    value_set<bit<16>>(4) pvs1;
    value_set<bit<16>>(4) pvs1;
    
    state start {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.etherType) {
            pvs1: st1;
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
