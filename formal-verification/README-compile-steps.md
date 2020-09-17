```bash
$ export B="../bin"
$ $B/p4c-dump-many-passes.sh v1model-undef2.p4
v1model-undef2.p4(58): [--Wwarn=uninitialized_use] warning: undef may be uninitialized
        x = undef;
            ^^^^^

$ $B/p4c-delete-duplicate-passes.sh v1model-undef2.p4 tmp

[ ... many lines of output omitted here ... ]

$ ls tmp
v1model-undef2-BMV2::SimpleSwitchMidEnd_29_LocalCopyPropagation.p4
v1model-undef2-FrontEnd_0_P4V1::getV1ModelVersion.p4
v1model-undef2-FrontEnd_11_TypeInference.p4
v1model-undef2-FrontEnd_13_BindTypeVariables.p4
v1model-undef2-FrontEnd_21_PassRepeated.p4
v1model-undef2-FrontEnd_28_UniqueNames.p4
v1model-undef2-FrontEnd_52_UniqueNames.p4
v1model-undef2-FrontEnd_54_UniqueNames.p4
```
