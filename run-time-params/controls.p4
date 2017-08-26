#include <core.p4>

// Architecture
control C1();
control C2();
control C3();
package S(C3 c3);

// User Program
control MyC1() {
    apply { }
}
control MyC2(C1 c1) {
    // README
    // 2017-Aug-16 version of p4test gives the following error on the
    // line above:
    //
    // controls.p4(13): error: c1: parameter cannot have type control C1
    // control MyC2(C1 c1) {
    //                 ^^
    // controls.p4(4)
    // control C1();
    //         ^^
    apply {
        c1.apply();
    }
}
control MyC3() {
    MyC1() c1;
    apply {
        MyC2.apply(c1);
    }
}

S(MyC3()) main;
