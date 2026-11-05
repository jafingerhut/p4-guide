#! /bin/bash

# SPDX-FileCopyrightText: 2026 Andy Fingerhut
# Copyright 2026 Andy Fingerhut
#
# SPDX-License-Identifier: Apache-2.0

# Copy all Python files generated during a build of the p4lang/PI
# repository code into a Python venv.

print_usage() {
    1>&2 echo "usage: `basename $0` <python_venv_dir_to_install_into>"
}

if [ $# -ne 1 ]
then
    print_usage
    exit 1
fi

VIRTUAL_ENV="$1"
shopt -s nullglob
DIRS=( ${VIRTUAL_ENV}/lib/python*/site-packages )
shopt -u nullglob
if [ ${#DIRS[@]} -eq 0 ]; then
    1>&2 echo "No file found matching glob pattern ${VIRTUAL_ENV}/lib/python*/site-packages"
    print_usage
    exit 1
fi
if [ ${#DIRS[@]} -gt 1 ]; then
    1>&2 echo "More than one file found matching glob pattern ${VIRTUAL_ENV}/lib/python\*/site-packages.  Aborting without copying files."
    print_usage
    exit 1
fi
VIRTUAL_ENV_SITE_PACKAGES=${DIRS[0]}
echo "VIRTUAL_ENV_SITE_PACKAGES=${VIRTUAL_ENV_SITE_PACKAGES}"
if [ ! -d "${VIRTUAL_ENV_SITE_PACKAGES}" ]
then
    1>&2 echo "Unique matching file ${VIRTUAL_ENV_SITE_PACKAGES} is not a directory.  Aborting without copying files."
    print_usage
    exit 1
fi

for d in \
    gnmi \
    google \
    google/rpc \
    p4 \
    p4/config \
    p4/config/v1 \
    p4/server \
    p4/server/v1 \
    p4/tmp \
    p4/v1
do
    set -x
    mkdir -p "${VIRTUAL_ENV_SITE_PACKAGES}/${d}"
    install -c -m 644 ${d}/*.py "${VIRTUAL_ENV_SITE_PACKAGES}/${d}"
    set +x
done
