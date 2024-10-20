#include "before-ingress.p4"

{
    bit<8> tmp1;
    bit<8> tmp2;

    counter((bit<32>)1024, CounterType.packets) cntr1;
    counter((bit<32>)1024, CounterType.packets) cntr1;

    apply {
        tmp1 = hdr.ethernet.srcAddr[7:0];
        tmp2 = hdr.ethernet.dstAddr[7:0];
        cntr1.count((bit<32>) tmp1);
        cntr2.count((bit<32>) tmp2);
    }
}

#include "after-ingress.p4"
