#! /bin/bash

F=typedef-test1.p4

B=`basename $F .p4`

# TBD: Change this to your local p4c executable, or if you leave this
# as is it will use the first one in your shell's command path.
P4C=p4c
#P4C=$HOME/forks/p4c/build/p4c

set -x
$P4C --target bmv2 --arch v1model --p4runtime-files ${B}.p4info.txtpb --dump . --top4 FrontEndLast,FrontEndDump,MidEndLast --toJson ${B}.ir.json $F
$P4C --version
