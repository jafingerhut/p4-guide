#!/bin/bash
PI_IMAGE=${1:-mypi2:latest}

docker run $PI_IMAGE bash -c \
    'ec=0; uv run make check -j2 || ec=$?; echo "got here #1 ec=${ec}"; (find . -name "test-suite.log" | xargs cat); exit $ec'
