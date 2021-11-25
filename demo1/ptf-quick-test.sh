#! /bin/bash

# A quick way for me to run the PTF test, to ensure that at least the
# part of the open soure P4 tools necessary for that are installed.

set -ex
sudo ../bin/veth_setup.sh
p4c --target bmv2 --arch v1model --p4runtime-files demo1.p4_16.p4rt.txt demo1.p4_16.p4
sudo simple_switch_grpc --log-console -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8 -i 5@veth10 -i 6@veth12 -i 7@veth14 --no-p4 &
SS_PID=$!
sleep 2
sudo ./runptf.sh
sleep 2
sudo pkill -9 simple_switch
ps axguwww | grep simple_switch
