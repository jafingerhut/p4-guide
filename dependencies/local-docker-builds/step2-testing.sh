#!/bin/bash
THIRD_PARTY_IMAGE=${1:-mypi:latest}

EXIT_STATUS=0
function test_python_import() {
  echo "- Checking '$1'..."
  docker run $THIRD_PARTY_IMAGE python -c "$1"
  if [ $? -eq 0 ]; then
    echo "  - PASS"
  else
    echo "  - FAIL"
    EXIT_STATUS=1
  fi
}

echo "--> docker run $THIRD_PARTY_IMAGE cat $HOME/.bashrc:"
docker run $THIRD_PARTY_IMAGE bash -c 'cat $HOME/.bashrc'
echo "--> docker run $THIRD_PARTY_IMAGE printenv:"
docker run $THIRD_PARTY_IMAGE printenv | sort
echo "--> docker run $THIRD_PARTY_IMAGE which uv"
docker run $THIRD_PARTY_IMAGE which uv
echo "--> docker run $THIRD_PARTY_IMAGE uv pip list"
docker run $THIRD_PARTY_IMAGE uv pip list

SAVE=$PWD
for j in $(docker run $THIRD_PARTY_IMAGE find / -name site-packages 2>/dev/null)
do
    echo "--> run_tests site-packages ----------------------------------------------------------------------"
    echo $j
    docker run $THIRD_PARTY_IMAGE find $j
done
for j in $(docker run $THIRD_PARTY_IMAGE find / -name dist-packages 2>/dev/null)
do
    echo "--> run_tests dist-packages ----------------------------------------------------------------------"
    echo $j
    docker run $THIRD_PARTY_IMAGE find $j
done
cd $SAVE

test_python_import "import thrift"
test_python_import "import grpc"
test_python_import "import p4.tmp"
test_python_import "import ptf"
test_python_import "from p4.v1 import p4runtime_pb2, p4runtime_pb2_grpc"
test_python_import "from google.rpc import code_pb2, status_pb2"

exit $EXIT_STATUS
