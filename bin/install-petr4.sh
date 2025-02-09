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
#
# SPDX-License-Identifier: Apache-2.0

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"

warning() {
    1>&2 echo "This install script has only been tested on Ubuntu 18.04 so far."
    1>&2 echo "Proceed installing manually at your own risk of significant time"
    1>&2 echo "spent figuring out how to make it all work, or consider getting"
    1>&2 echo "VirtualBox and creating an Ubuntu 18.04 virtual machine."
}

lsb_release >& /dev/null
if [ $? != 0 ]
then
    1>&2 echo "No 'lsb_release' found in your command path."
    warning
    exit 1
fi

distributor_id=`lsb_release -si`
release=`lsb_release -sr`
if [ "${distributor_id}" = "Ubuntu" -a "${release}" = "18.04" ]
then
    echo "Found distributor '${distributor_id}' release '${release}'.  Continuing with installation."
else
    warning
    1>&2 echo ""
    1>&2 echo "Here is what command 'lsb_release -a' shows this OS to be:"
    lsb_release -a
    exit 1
fi

echo "------------------------------------------------------------"
echo "Time and disk space used before installation begins:"
date
df -h .
df -BM .

# Install Ubuntu packages needed for a C compiler, which 'opam init'
# command requires.  The build-essential package might be more than
# the minimum required by 'opam init', but probably not a lot more.
sudo apt-get --yes install curl git build-essential

echo "----------------------------------------------------------------------"
echo "Installing opam:"
set -x
curl --location --output /tmp/opam https://github.com/ocaml/opam/releases/download/2.0.4/opam-2.0.4-x86_64-linux
sudo /bin/cp /tmp/opam /usr/local/bin/opam
sudo chmod 755 /usr/local/bin/opam
/bin/rm /tmp/opam
set +x

echo "----------------------------------------------------------------------"
echo "Because I do not know how to invoke the 'opam init' command in a way that"
echo "avoids asking you several questions that require interactive answers, you"
echo "will need to respond to two prompts during the execution of 'opam init'."
echo ""
echo "When the questions below are asked, you can choose the default answer of"
echo "'no' by simply pressing return, and this is how I have tested this script."
echo "You are free to adventure out on your own with different answers, of"
echo "course, and see what happens."
echo ""
echo "    Do you want opam to modify ~/.profile? [N/y/f]"
echo "    A hook can be added to opam's init scripts to ensure that the shell remains in sync with the opam environment when they are loaded. Set that up? [y/N]"
echo "----------------------------------------------------------------------"
echo ""
echo -n "Press return to proceed after reading the above: "
read

set -x
opam init

opam env
eval `opam env`

# Show version of ocamlc installed, in case it is older than what
# is required by petr4
ocamlc -v
set +x

echo "----------------------------------------------------------------------"
echo "Installing petr4:"

# According to petr4 README, these packages should be installed.
set -x
sudo apt-get --yes install m4 libgmp-dev
git clone https://github.com/cornell-netlab/petr4
cd petr4
opam pin --yes add petr4 .
set +x

echo "------------------------------------------------------------"
echo "Time and disk space used when installation was complete:"
date
df -h .
df -BM .

cd "${INSTALL_DIR}"
# Note that single quotes are necessary around the echo string below, otherwise
# the command 'opam env' will be executed and its output be echoed and written
# to the petr4setup.bash file.
echo 'eval `opam env`' > petr4setup.bash

echo ""
echo "Created file: petr4setup.bash"
echo ""
echo "If you use a Bash-like command shell, you may wish to copy the"
echo "lines of the file petr4setup.bash to your .bashrc or .profile"
echo "files in your home directory to add the command petr4 to your"
echo "command path every time you log in or create a new shell."
