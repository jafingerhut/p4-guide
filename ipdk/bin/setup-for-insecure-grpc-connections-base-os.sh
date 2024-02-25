#! /bin/bash

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

set -x
/bin/cp -pr ${THIS_SCRIPT_DIR_ABSOLUTE} ${THIS_SCRIPT_DIR_ABSOLUTE}/../../testlib ${HOME}/.ipdk/volume
cd ${IPDK_HOME}
ipdk execute --- /tmp/bin/setup-for-insecure-grpc-connections-in-cont.sh
