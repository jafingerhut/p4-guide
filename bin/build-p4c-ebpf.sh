#! /bin/bash

# Tested on Ubuntu 22.04 Linux only so far

export CTEST_PARALLEL_LEVEL="4"
export IMAGE_TYPE="test"
export CMAKE_UNITY_BUILD="ON"
export INSTALL_PTF_EBPF_DEPENDENCIES="ON"
export BUILD_GENERATOR="Ninja"

./tools/ci-build.sh

echo "To run p4c-ebpf tests:"
echo "    cd backends/ebpf/tests"
echo "    sudo -E env PATH=\"\$PATH\" uv run ./test.sh"
