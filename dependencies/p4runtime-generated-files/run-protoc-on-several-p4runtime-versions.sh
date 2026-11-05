#! /bin/bash

# SPDX-FileCopyrightText: 2026 Andy Fingerhut
# Copyright 2026 Andy Fingerhut
#
# SPDX-License-Identifier: Apache-2.0

print_usage() {
    1>&2 echo "usage: `basename $0` <directory_to_run>"
}

if [ $# -ne 1 ]
then
    print_usage
    exit 1
fi
cd "$1"

echo "------------------------------------------------------------"
echo "/etc/os-release"
echo "------------------------------------------------------------"
cat /etc/os-release
echo "------------------------------------------------------------"
echo "PWD=$PWD"
set -x
apt-get update
apt-get install --yes git
protoc --version
which protoc
ls -l `which protoc`
which grpc_python_plugin
ls -l `which grpc_python_plugin`
which grpc_cpp_plugin
ls -l `which grpc_cpp_plugin`
GRPC_PYTHON_PLUGIN=$(which grpc_python_plugin)
ls -l
echo $HOME
echo $PATH
set +x

PROTOBASE="proto"

#    google/rpc/status.proto \

PROTOFILES=" \
    ${PROTOBASE}/p4/v1/p4data.proto \
    ${PROTOBASE}/p4/v1/p4runtime.proto \
    ${PROTOBASE}/p4/config/v1/p4info.proto \
    ${PROTOBASE}/p4/config/v1/p4types.proto"

for d in p4runtime-*
do
    cd ${d}
    echo "----------------------------------------"
    git status .
    LOCAL_GOOGLE_STATUS_PROTO="${PROTOBASE}/google/rpc/status.proto"
    if [ -r "${LOCAL_GOOGLE_STATUS_PROTO}" ]; then
        LOCAL_GOOGLE_PROTO_DIR="${PROTOBASE}"
        ADDITIONAL_INCLUDE_DIR=""
    else
        LOCAL_GOOGLE_PROTO_DIR="../googleapis"
        ADDITIONAL_INCLUDE_DIR="-I${LOCAL_GOOGLE_PROTO_DIR}"
    fi
    P="${LOCAL_GOOGLE_PROTO_DIR}/google/rpc/status.proto ${PROTOFILES}"
    mkdir -p py_out
    set -x
    protoc \
        ${P} \
       ${ADDITIONAL_INCLUDE_DIR} \
       -I${PROTOBASE} \
        --python_out ./py_out \
        --grpc_out ./py_out \
        --plugin=protoc-gen-grpc=${GRPC_PYTHON_PLUGIN}
    set +x
    find py_out ! -type d -ls | sort
    cd ..
done
