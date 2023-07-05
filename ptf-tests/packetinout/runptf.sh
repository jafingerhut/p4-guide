#! /bin/bash

T="`realpath ../../testlib`"
if [ x"${PYTHONPATH}" == "x" ]
then
    P="${T}"
else
    P="${T}:${PYTHONPATH}"
fi

#echo "P is: $P"

# Only show a list of tests
#ptf --pypath "$P" --test-dir . --list
#exit 0

set -x
p4c --target bmv2 \
    --arch v1model \
    --p4runtime-files packetinout.p4info.txt \
    packetinout.p4

# Remove any log file written in an earlier run, otherwise
# simple_switch_grpc will append the new log messages to the end of
# the existing file.
/bin/rm -f ss-log.txt

# Note that in order for PacketIn and PacketOut messages from the
# controller from/to the switch to work with `simple_switch_grpc`, you
# must start it with the `--cpu-port` command line option.  The
# `packetinout.py` PTF test has been written assuming that the CPU
# port is number 510.

sudo simple_switch_grpc \
     --log-file ss-log \
     --log-flush \
     --dump-packet-data 10000 \
     -i 0@veth0 \
     -i 1@veth2 \
     -i 2@veth4 \
     -i 3@veth6 \
     -i 4@veth8 \
     -i 5@veth10 \
     -i 6@veth12 \
     -i 7@veth14 \
     --no-p4 \
     -- --cpu-port 510 &
echo ""
echo "Started simple_switch_grpc.  Waiting 2 seconds before starting PTF test ..."
sleep 2

# Note that the mapping between switch port number and Linux interface
# names is best to make it correspond with those given when starting
# the simple_switch_grpc process.  The `ptf` process has no other way
# of getting this mapping other than by telling it on its command
# line.

sudo `which ptf` \
    --pypath "$P" \
    -i 0@veth1 \
    -i 1@veth3 \
    -i 2@veth5 \
    -i 3@veth7 \
    -i 4@veth9 \
    -i 5@veth11 \
    -i 6@veth13 \
    -i 7@veth15 \
    --test-params="grpcaddr='localhost:9559';p4info='packetinout.p4info.txt';config='packetinout.json'" \
    --test-dir .

echo ""
echo "PTF test finished.  Waiting 2 seconds before killing simple_switch_grpc ..."
sleep 2
sudo pkill --signal 9 --list-name simple_switch
echo ""
echo "Verifying that there are no simple_switch_grpc processes running any longer in 4 seconds ..."
sleep 4
ps axguwww | grep simple_switch


# Add the option below to the ptf command line if you want to test
# only a restricted list of tests, not all of them.

#    --test-file testnamelist.txt \
