#! /bin/bash

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
    /usr/bin/protoc \
        ${P} \
       ${ADDITIONAL_INCLUDE_DIR} \
       -I${PROTOBASE} \
        --python_out ./py_out \
        --grpc_out ./py_out \
        --plugin=protoc-gen-grpc=/usr/bin/grpc_python_plugin
    set +x
    find py_out ! -type d -ls | sort
    cd ..
done
