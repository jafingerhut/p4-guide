#! /bin/bash

# This is a command line I used to compile add_on_miss0.p4 using the
# version of p4c built from this source code of repository
# https://github.com/p4lang/p4c

# $ git log -n 1 | head -n 5
# commit ca1f3474d532aa5c8eea5db5adbd838bc8b52d07
# Author: Fabian Ruffy <5960321+fruffy@users.noreply.github.com>
# Date:   Thu Feb 23 10:40:19 2023 -0500
# 
#     Deprecate unified build in favor of unity build. (#3491)

set -x
mkdir -p pipe

#p4c --arch pna --target dpdk \
#    --output pipe \
#    --p4runtime-files p4Info.txt \
#    --bf-rt-schema bf-rt.json \
#    --context pipe/context.json \
#    add_on_miss0.p4

p4c-dpdk --arch pna \
    --p4runtime-files p4Info.txt \
    --bf-rt-schema bf-rt.json \
    --context pipe/context.json \
    -o pipe/add_on_miss0.spec \
    add_on_miss0.p4
