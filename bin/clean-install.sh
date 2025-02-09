#! /bin/bash
# Copyright 2023 Andy Fingerhut
#
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
#
# SPDX-License-Identifier: Apache-2.0


# To reduce disk space used by the virtual machine, delete many build
# files created during execution of install-p4dev-v6.sh script

# This script is _not_ automatically run during creation of the VM, so
# that if anything goes wrong during the build, all of the resulting
# files are left behind for examination.

DF1_BEFORE=`df -h .`
DF2_BEFORE=`df -BM .`

sudo rm -fr protobuf grpc

cd behavioral-model
make clean
cd ..

cd p4c
/bin/rm -fr build
cd ..

######################################################################
# I found this script here:
# https://www.linuxuprising.com/2019/04/how-to-remove-old-snap-versions-to-free.html

# In this discussion I found that it should be safe to delete the snap
# cache directory:
# https://askubuntu.com/questions/1075050/how-to-remove-uninstalled-snaps-from-cache

BEFORE=`df -BM .`
LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done
# askubuntu.com Q&A where I found the following command:
# https://askubuntu.com/questions/1075050/how-to-remove-uninstalled-snaps-from-cache
sudo sh -c 'rm -rf /var/lib/snapd/cache/*'
sudo apt clean
sudo apt autoremove
sudo apt clean
######################################################################

# Zero out unused disk blocks.  Results in significantly smaller VM
# image files.

echo "Writing zeros to unused disk blocks (be patient) ..."
FNAME=`mktemp --tmpdir big-empty-zero-file-XXXXXXXX`
dd if=/dev/zero of=${FNAME} bs=4096k
/bin/rm -f ${FNAME}

echo "Disk usage before running this script:"
echo "$DF1_BEFORE"
echo "$DF2_BEFORE"

echo ""
echo "Disk usage after running this script:"
df -h .
df -BM .
