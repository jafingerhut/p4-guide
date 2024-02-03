#! /bin/bash

# This is a command line I used to compile add_on_miss1.p4 using the
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

# This section of the script is intended to enable you to
# enable/disable these preprocessor #define symbols by
# commenting/uncommenting individual lines.
MACRO_DEFINES=""
#MACRO_DEFINES="-DDONT_USE_IDLE_TIMEOUT_WITH_AUTO_DELETE $MACRO_DEFINES"
# As of the version of p4c shown above, p4c-dpdk always gives an error
# if you attempt to assign a value of PNA_IdleTimeout_t.AUTO_DELETE to
# table property pna_idle_timeout, because AUTO_DELETE is not in
# DPDK's versionn of pna.p4 yet.
#MACRO_DEFINES="-DUSE_PNA_IDLE_TIMEOUT_AUTO_DELETE $MACRO_DEFINES"

p4c-dpdk ${MACRO_DEFINES} \
    --arch pna \
    --p4runtime-files p4Info.txt \
    --bf-rt-schema bf-rt.json \
    --context pipe/context.json \
    -o pipe/add_on_miss1.spec \
    add_on_miss1.p4
