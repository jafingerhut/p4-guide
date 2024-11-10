#! /bin/bash

print_p4c_dir_message() {
    1>&2 echo "To run this script successfully, either:"
    1>&2 echo ""
    1>&2 echo "(a) Use the following commands to create a clone of the p4c repository there:"
    1>&2 echo "    cd `dirname $P4C_CLONE_DIR`"
    1>&2 echo "    git clone https://github.com/p4lang/p4c"
    1>&2 echo ""
    1>&2 echo "(b) Edit the script '$0' and change the definition"
    1>&2 echo "    of P4C_CLONE_DIR to be the path to a copy of the"
    1>&2 echo "    p4c repository that you have installed on your system."
}

P4C_CLONE_DIR="$HOME/p4c"
if [ ! -d ${P4C_CLONE_DIR} ]; then
    1>&2 echo "No such directory: $P4C_CLONE_DIR"
    1>&2 echo "Expected to find a clone of the repository there."
    print_p4c_dir_message
    exit 1
fi

BASE_TEST_DIR="$P4C_CLONE_DIR/tools/ptf"
if [ -r "${BASE_TEST_DIR}/base_test.py" ]; then
    echo "Found p4c base_test.py package: ${BASE_TEST_DIR}/base_test.py"
else
    1>&2 echo "Did not find p4c base_test.py package: ${BASE_TEST_DIR}/base_test.py"
    print_p4c_dir_message
fi

P4TESTGEN_OUTPUT_DIR="out-p4testgen"

T="`realpath ${BASE_TEST_DIR}`"
if [ x"${PYTHONPATH}" == "x" ]
then
    P="${T}"
else
    P="${T}:${PYTHONPATH}"
fi

print_usage() {
    1>&2 echo "Usage:"
    1>&2 echo "    $0 <progname.p4>"
}

if [ $# -ne 1 ]; then
    print_usage
    exit 1
fi

P4PROG="$1"
/bin/cp ${P4PROG} testme.p4

set -x
p4c --target bmv2 \
    --arch v1model \
    --p4runtime-files testme.p4info.txtpb \
    testme.p4

p4testgen \
    --target bmv2 \
    --arch v1model \
    --max-tests 1000 \
    --out-dir ${P4TESTGEN_OUTPUT_DIR} \
    --test-backend ptf \
    testme.p4

# Remove any log file written in an earlier run, otherwise
# simple_switch_grpc will append the new log messages to the end of
# the existing file.
/bin/rm -f ss-log.txt

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
     --no-p4 &
echo ""
echo "Started simple_switch_grpc.  Waiting 2 seconds before starting PTF test ..."
sleep 2

# Note that the mapping between switch port number and Linux interface
# names is best to make it correspond with those given when starting
# the simple_switch_grpc process.  The `ptf` process has no other way
# of getting this mapping other than by telling it on its command
# line.

sudo ${P4GUIDE_SUDO_OPTS} `which ptf` \
    --pypath "$P" \
    -i 0@veth1 \
    -i 1@veth3 \
    -i 2@veth5 \
    -i 3@veth7 \
    -i 4@veth9 \
    -i 5@veth11 \
    -i 6@veth13 \
    -i 7@veth15 \
    --test-params="grpcaddr='localhost:9559';p4info='testme.p4info.txtpb';config='testme.json'" \
    --test-dir ${P4TESTGEN_OUTPUT_DIR}

echo ""
echo "PTF test finished.  Waiting 2 seconds before killing simple_switch_grpc ..."
sleep 2
sudo pkill --signal 9 --list-name simple_switch
echo ""
echo "Verifying that there are no simple_switch_grpc processes running any longer in 4 seconds ..."
sleep 4
ps axguwww | grep simple_switch
