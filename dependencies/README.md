# Introduction

There are several kinds of dependencies between programs and libraries
implemented in repositories in the organization
https://github.com/p4lang, both between each other, and dependencies
on the code in those repositories on code published elsewhere.

This article is not yet a complete description of all such
dependencies -- only a few that I have had time to write about.


## Docker dependencies

Setup, which downloads several gigabytes of files:

```bash
CLONES_DIR="/full/path/to/desired/path"
cd ${CLONES_DIR}
~/p4-guide/bin/clone-public-p4lang-repos.sh
alias f0n='find . -name .git -prune -o -name .snapshot -prune -o \! -type d -a \! -type l -print0'
alias x0='xargs -0'
```

If you execute the command below, you can find all places where a
Dockerfile defines a dependency on another Docker image.

```bash
$ f0n | x0 grep '^FROM ' | grep -v '/forks/'
./other/p4c/Dockerfile:FROM ${BASE_IMAGE}
./other/open-p4studio/pkgsrc/switch-p4-16/submodules/SAI/bm/behavioral-model/Dockerfile.grpc:FROM ubuntu:16.04
./other/open-p4studio/pkgsrc/switch-p4-16/submodules/SAI/bm/behavioral-model/Dockerfile:FROM p4lang/third-party:stable
./other/open-p4studio/pkgsrc/bf-drivers/third-party/p4runtime/p4runtime/CI/Dockerfile:FROM p4lang/third-party:latest
./other/open-p4studio/pkgsrc/bf-drivers/third-party/p4runtime/p4runtime/docs/tools/Dockerfile.madoko:FROM ubuntu:16.04
./other/open-p4studio/pkgsrc/bf-utils/Dockerfile:FROM ${DOCKER_PROJECT}/bf-syslibs:latest
./other/p4runtime-shell/Dockerfile:FROM ubuntu:22.04 AS deps
./other/p4runtime-shell/Dockerfile:FROM ubuntu:22.04
./other/p4runtime-shell/Dockerfile.dev:FROM ${BASE_IMAGE}
./other/p4-spec/tools/Dockerfile.asciidoc_v1:FROM ubuntu:22.04
./other/p4-spec/tools/Dockerfile.asciidoc_v2:FROM  ruby:3.3.5
./other/p4runtime/docs/tools/Dockerfile.asciidoc:FROM  ruby:3.3.5
./other/p4runtime/codegen/Dockerfile:FROM p4lang/third-party:latest
./other/p4-constraints/Dockerfile:FROM ubuntu:16.04
./other/p4app-switchML/dev_root/dockerfiles/rdma.dockerfile:FROM nvidia/cuda:11.2.2-devel-ubuntu18.04
./other/p4app-switchML/dev_root/dockerfiles/dpdk.dockerfile:FROM nvidia/cuda:11.2.2-devel-ubuntu18.04
./other/p4app-switchML/dev_root/dockerfiles/dummy.dockerfile:FROM nvidia/cuda:11.2.2-devel-ubuntu18.04
./other/p4app-switchML/dev_root/dockerfiles/controller.dockerfile:FROM ubuntu:18.04
./other/p4app-switchML/dev_root/dockerfiles/rdma_pytorch.dockerfile:FROM nvidia/cuda:11.2.2-devel-ubuntu18.04
./other/p4app-switchML/dev_root/dockerfiles/dpdk_pytorch.dockerfile:FROM nvidia/cuda:11.2.2-devel-ubuntu18.04
./other/p4app/Dockerfile:FROM p4lang/p4c:latest
./other/PI/Dockerfile:FROM p4lang/third-party:latest
./other/PI/Dockerfile.bmv2:FROM p4lang/behavioral-model:no-pi
./other/p4-dpdk-target/Dockerfile:FROM p4lang/p4c@sha256:c1cbb66cea83de50b43d7ef78d478dd5e43ce9e1116921d6700cc40bb505e12a as p4c
./other/p4-dpdk-target/Dockerfile:FROM ubuntu:20.04 as p4-dpdk-target
./other/p4-dpdk-target/Dockerfile:FROM ubuntu:20.04
./other/switch/docker/Dockerfile:FROM ubuntu:14.04
./other/switch/docker/bmv2/Dockerfile:FROM      ubuntu:14.04
./other/third-party/Dockerfile:FROM ubuntu:20.04 as base-builder
./other/third-party/Dockerfile:FROM base-builder as ccache
./other/third-party/Dockerfile:FROM base-builder as ptf
./other/third-party/Dockerfile:FROM base-builder as nanomsg
./other/third-party/Dockerfile:FROM base-builder as nnpy
./other/third-party/Dockerfile:FROM base-builder as thrift
./other/third-party/Dockerfile:FROM base-builder as protobuf
./other/third-party/Dockerfile:FROM base-builder as grpc
./other/third-party/Dockerfile:FROM base-builder as libyang
./other/third-party/Dockerfile:FROM base-builder as sysrepo
./other/third-party/Dockerfile:FROM ubuntu:20.04
./other/p4pi/pi-gen/Dockerfile:FROM ${BASE_IMAGE}
./other/behavioral-model/Dockerfile:FROM p4lang/pi:${PARENT_VERSION}
./other/behavioral-model/Dockerfile.noPI:FROM p4lang/third-party:latest
./archived/p4factory/docker/Dockerfile:FROM      ubuntu:14.04
./archived/p4factory/travis/Dockerfile:FROM      ubuntu:14.04
```

And the command below will find all places where a Github Action YAML
file defines the name of a Docker image to publish, after earlier
commands in that action have created the Docker image.

```bash
$ find . \( -name '*.yml' -o -name '*.yaml' \) -print0 | x0 grep 'tags:' | grep -v '/open-p4studio/p4studio/dependencies/'
./other/p4c/.github/workflows/ci-release.yml:          tags: p4lang/p4c:${{ env.VERSION }}
./other/p4c/.github/workflows/ci-container-image.yml:          tags: p4lang/p4c:${{ steps.get-tag.outputs.tag }}
./other/open-p4studio/pkgsrc/bf-drivers/third-party/p4runtime/p4runtime/.travis.yml:      tags: true
./other/p4runtime-shell/.github/workflows/test.yml:        tags: localhost:5000/p4lang/p4runtime-sh
./other/p4runtime-shell/.github/workflows/test.yml:        tags: p4lang/p4runtime-sh-dev
./other/p4runtime-shell/.github/workflows/test.yml:        tags: p4lang/p4runtime-sh
./other/p4runtime-shell/.github/workflows/pypi.yml:    tags:
./other/p4runtime/.github/workflows/tag-uploads.yml:    tags:
./other/PI/.github/workflows/build.yml:        tags: p4lang/pi:${{ steps.get-tag.outputs.tag }}
./other/ptf/.github/workflows/pypi.yml:    tags:
./other/third-party/.github/workflows/build.yml:        tags: p4lang/third-party:${{ steps.get-tag.outputs.tag }}
./other/third-party/.github/workflows/build.yml:        tags: p4lang/third-party:${{ steps.get-tag.outputs.tag }}
./other/behavioral-model/.github/workflows/build.yml:        tags: p4lang/behavioral-model:${{ steps.get-tag.outputs.tag }}
./other/behavioral-model/.github/workflows/build.yml:        tags: p4lang/behavioral-model:no-pi
```

All of these relationships are represented in a directed graph form in
the file `docker-images.dot`.

By drawing this and analyzing it, here is the longest path through it,
that is also the one that leads from an unmodified Ubuntu Linux image
to one with behavioral-model and p4c installed on it.

+ `docker build -f third-party/Dockerfile` starts `FROM ubuntu:20.04`
  and produces image `p4lang/third-party`
+ `docker build -f PI/Dockerfile` starts `FROM p4lang/third-party` and
  produces image `p4lang/pi`
+ `docker build -f behavioral-model/Dockerfile` starts `FROM
  p4lang/pi` and produces image `p4lang/behavioral-model`
+ `docker build -f p4c/Dockerfile` starts `FROM
  p4lang/behavioral-model` and produces image `p4lang/p4c`
