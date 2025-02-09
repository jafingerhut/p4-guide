#!/bin/bash
# Copyright 2024 Andy Fingerhut
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


# I found the code for this script here, copied it, and made small
# non-functional changes to it on 2023-Jan-13:
#
# https://gist.github.com/heralight/c34fc27048ff8c13862a

installPackage=false

function process {
    packageName="$1"
    echo "######### key  : $packageName"
    v=$(eval "apt-cache policy  $packageName | grep 'Candidate:' | cut -c 14-")
    echo "######### version: $v"
#    array[$packageName]=$v
#    echo "value: ${array[$packageName]}"
    equivs-control $packageName
    r1="sed -i -- 's/Standards-Version:.*/Version: $v/g' $packageName"
    eval $r1
    r2="sed -i -- 's/Package:.*/Package: $packageName/g' $packageName"
    eval $r2
    equivs-build $packageName

    if [ "$installPackage" = true ]
    then
	genFile="${packageName}_${v}_all.deb"
	echo "######### install $genFile"
	sudo dpkg -i $genFile
    fi
}

function usage {
    echo "usage: $0 [ --install | -i ] <packageName>+"
    echo ""
    echo "e.g: $0 -i rfkill nome-bluetooth bluez"
    echo "Note: to remove a deb without removing its dependencies: sudo dpkg -r --force-depends \"package\""
}

which equivs-control
exit_status=$?
if [ ${exit_status} -ne 0 ]
then
    1>&2 echo "No command 'equivs-control' found."
    1>&2 echo "You can install it using the command:"
    1>&2 echo ""
    1>&2 echo "    sudo apt-get install equivs"
    exit 1
fi


if [ $#  -lt 1 ]
then
    usage
    exit 1
fi

while [ "$1" != "" ]
do
    case $1 in
        -i | --install)
            echo "Install"
	    installPackage=true
            ;;
        -h | --help)
            usage
            exit
            ;;
        *)
            process $1
    esac
    shift
done
