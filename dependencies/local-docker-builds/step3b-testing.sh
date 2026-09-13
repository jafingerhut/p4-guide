#!/bin/bash
PI_IMAGE=${1:-mypi2:latest}

docker run $PI_IMAGE bash -c \
    'uv run make check -j2 || (find . -name "test-suite.log" | xargs cat)'
