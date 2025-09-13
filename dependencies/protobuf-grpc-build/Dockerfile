# Shared Dockerfile for third party dependencies used in projects in the p4lang
# organization.
#
# Best practices for multi-stage builds are available at
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
#
# The approach used in this Dockerfile is as follows:
#
# A multi-stage build creates a separate image for each third party dependency and
# then copies only the binaries to a single output image at the end.
#
# If you add a new dependency, please:
#   (1) Create a new build image for it. (It should have its own FROM section.)
#   (2) Ensure that it installs everything that should be included in the final
#       image to `/output/usr/local`. Use DESTDIR and PYTHONUSERBASE for this.
#       Be sure to install python packages and code using
#       `pip install --user --ignore-installed`. If you absolutely *must* use
#       `python setup.py install`, take a look at the protobuf build image and
#       then reconsider.
#   (3) Use COPY to place the contents of the build image's `/output/usr/local`
#       in the final image.
#   (4) If the new dependency requires that certain apt packages be installed at
#       runtime (as opposed to at build time), create a new _DEPS variable and
#       install the new packages with all of the others; look at how the final
#       image is constructed and you'll understand the pattern.
#
# In general you don't have to worry about the size of intermediate build images,
# but please minimize the amount of data and the number of layers that end up in the
# final image.

# Create an image with tools used as a base for the next layers
FROM ubuntu:24.04 AS base-builder
ARG MAKEFLAGS=-j2
ENV DEBIAN_FRONTEND=noninteractive \
    CFLAGS="-Os" \
    CXXFLAGS="-Os" \
    LDFLAGS="-Wl,-s" \
    LD_LIBRARY_PATH=/output/usr/local/lib/
RUN apt-get update -qq && apt-get install -qq --no-install-recommends \
        build-essential \
        cmake \
        g++ \
        git \
        libtool \
        make \
        pkg-config \
        python3 \
        python3-dev \
        python3-venv && \
    mkdir -p /output/usr/local && \
    python3 -m venv /output/usr/local

# Build Protocol Buffers.
FROM base-builder AS protobuf
WORKDIR /
SHELL ["/bin/bash", "-c"]
RUN mkdir -p /build && \
    cd /build && \
    git clone https://github.com/google/protobuf && \
    cd protobuf && \
    git checkout v5.26.1 && \
    git submodule update --init --recursive
RUN cd /build/protobuf && \
    cmake -Dprotobuf_BUILD_SHARED_LIBS=ON . && \
    make -j$(nproc)
RUN cd /build/protobuf && \
    make DESTDIR=/output install && \
    source /output/usr/local/bin/activate && \
    python3 -m pip install protobuf==5.26.1

# Build gRPC
FROM base-builder AS grpc
COPY --from=protobuf /output/usr/local /usr/local/
RUN ldconfig
WORKDIR /
SHELL ["/bin/bash", "-c"]
RUN cd / && \
    git clone https://github.com/grpc/grpc && \
    cd grpc && \
    git checkout v1.64.3 && \
    git submodule update --init --recursive
RUN cd /grpc && \
    mkdir -p cmake/build && \
    cd cmake/build && \
    cmake ../.. \
      -DgRPC_INSTALL=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DgRPC_PROTOBUF_PROVIDER=package \
      -DgRPC_SSL_PROVIDER=module && \
    make DESTDIR=/output install && \
    ldconfig && \
    source /output/usr/local/bin/activate && \
    python3 -m pip install grpcio==1.64.3

# Construct the final image.
FROM ubuntu:24.04
LABEL maintainer="P4 Developers <p4-dev@lists.p4.org>"
ARG DEBIAN_FRONTEND=noninteractive
ARG MAKEFLAGS=-j2
RUN GRPC_RUNTIME_DEPS="libssl-dev python3-minimal python3-setuptools libre2-dev" && \
    apt-get update && \
    apt-get install -y --no-install-recommends $GRPC_RUNTIME_DEPS && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/*
# Copy files from the build containers.
COPY --from=protobuf /output/usr/local /usr/local/
COPY --from=grpc /output/usr/local /usr/local/

RUN ldconfig
