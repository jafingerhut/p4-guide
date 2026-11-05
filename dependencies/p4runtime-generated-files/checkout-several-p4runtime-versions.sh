#! /bin/bash

# SPDX-FileCopyrightText: 2026 Andy Fingerhut
# Copyright 2026 Andy Fingerhut
#
# SPDX-License-Identifier: Apache-2.0

if [ -d p4runtime ]; then
    echo "Directory p4runtime already exists."
else
    git clone https://github.com/p4lang/p4runtime
fi

# The p4lang/p4runtime reposiory has the file google/rpc/status.proto
# copied into it from the googleapis repository, I think just for
# convenience, but perhaps also pinning its version without having to
# clone the entire googleapis repository, which is sizeable.

if [ -d googleapis ]; then
    echo "Directory googleapis already exists."
else
    git clone --depth 1 https://github.com/googleapis/googleapis.git
fi

for v in v1.2.0 v1.3.0 v1.4.0-rc1 v1.4.0 v1.4.1 v1.5.0 v1.6.0
do
    TAG=$v
    if [ ${v} = "v1.4.0-rc1" ]; then
        # This is the version that as of 2026-Nov-01 is the one
        # specified as a submodule of the https://github.com/p4lang/PI
        # repository.
        TAG="ec4eb5ef70dbcbcbf2f8357a4b2b8c2f218845a5"
    fi
    if [ -d p4runtime-${v} ]; then
	echo "Directory p4runtime-${v} already exists."
    else
	/bin/cp -pr p4runtime p4runtime-${v}
	cd p4runtime-${v}
	git checkout ${TAG}
	cd ..
    fi
done
