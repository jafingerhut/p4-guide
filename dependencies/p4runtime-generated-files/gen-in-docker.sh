#! /bin/bash

IMG="p4lang/third-party:latest"

RUN_DIR="${PWD}"

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
export THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

D=${RUN_DIR}/docker-work
mkdir -p $D
cd $D
"${THIS_SCRIPT_DIR_ABSOLUTE}/checkout-several-p4runtime-versions.sh"
cp -p "${THIS_SCRIPT_DIR_ABSOLUTE}/run-protoc-on-several-p4runtime-versions.sh" $D/

CONTAINER_DIR=/root/work

docker run -v ${D}:${CONTAINER_DIR} ${IMG} ${CONTAINER_DIR}/run-protoc-on-several-p4runtime-versions.sh ${CONTAINER_DIR}
