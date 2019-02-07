#! /bin/bash

# Copyright 2019 Cisco Systems, Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -e

# The maximum number of gcc/g++ jobs to run in parallel.  3 can easily
# take 1 to 1.5G of RAM, and the build will fail if you run out of RAM,
# so don't make this number huge on a machine with 4G of RAM, for example.
MAX_PARALLEL_JOBS=3

if [ -d .git -a -d midend ]
then
    echo "Found directories .git and midend"
else
    2>&1 echo "At least one of .git and midend directories is not present."
    2>&1 echo ""
    2>&1 echo "This command must be run from inside top level directory of"
    2>&1 echo "a clone of the Github repository https://github.com/p4lang/p4c"
    exit 1
fi

usage() {
    2>&1 echo "usage: $0 <file_containing_git_shas> <script_to_run>"
    2>&1 echo ""
    2>&1 echo "For each of a list of git commit SHAs given in the file"
    2>&1 echo "<file_containing_git_shas>, build p4c at that version,"
    2>&1 echo "and run a shell script <script_to_run>."
    2>&1 echo "<script_to_run> will be given two command line"
    2>&1 echo "arguments.  The first is the full path name to the p4c"
    2>&1 echo "executable that was built, and the second is a string"
    2>&1 echo "in the form <number>-<sha>, where <number> begins at 1"
    2>&1 echo "and increments by 1 for each <sha>."
}

if [ $# -ne 2 ]
then
    usage
    exit 0
fi

VERSION_LIST_FILE="$1"
CMD_TO_RUN_FOR_EACH_VERSION="$2"

i=0
for version in `cat ${VERSION_LIST_FILE}`
do
    let "i = $i + 1"
    num=`printf "%03d" $i`
    echo "Run $num with version ${version}"
    git checkout ${version}

    # Do this, in case the version of submodules changes across p4c
    # versions
    git submodule update --init --recursive

    /bin/rm -fr build
    mkdir build
    cd build
    # Configure for a debug build
    cmake .. -DCMAKE_BUILD_TYPE=DEBUG
    make -j${MAX_PARALLEL_JOBS}
    cd ..

    echo ${CMD_TO_RUN_FOR_EACH_VERSION} ${PWD}/build/p4c ${num}-${version}
    ${CMD_TO_RUN_FOR_EACH_VERSION} ${PWD}/build/p4c ${num}-${version}
done
