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
