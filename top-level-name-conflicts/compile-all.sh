#! /bin/bash
# Copyright 2019 Andy Fingerhut
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


TMPF="my-tempfile.txt"
NOERRORF="no-error.txt"
FOO_DUPLICATES_FOO_F="foo-duplicates-foo-error.txt"
REDECLARATION_OF_FOO_F="redeclaration-of-foo-error.txt"
OTHER_F="other-error.txt"

for j in ${NOERRORF} ${FOO_DUPLICATES_FOO_F} ${REDECLARATION_OF_FOO_F} ${OTHER_F}
do
    /bin/cp /dev/null $j
done

for j in $*
do
    /bin/rm ${TMPF} >& /dev/null
    #p4c --target bmv2 --arch v1model $j
    p4test $j >& ${TMPF}
    status=$?
    if [ ${status} == 0 ]
    then
	echo "----------------------------------------------------------------------" >> ${NOERRORF}
	echo "$j status=$status" >> ${NOERRORF}
	cat ${TMPF} >> ${NOERRORF}
	continue
    fi
    
    grep --quiet 'foo duplicates foo' ${TMPF}
    zero_if_found=$?
    if [ ${zero_if_found} == 0 ]
    then
	echo "----------------------------------------------------------------------" >> ${FOO_DUPLICATES_FOO_F}
	echo "$j status=$status" >> ${FOO_DUPLICATES_FOO_F}
	cat ${TMPF} >> ${FOO_DUPLICATES_FOO_F}
	continue
    fi
    
    grep --quiet 'Re-declaration of foo with different type' ${TMPF}
    zero_if_found=$?
    if [ ${zero_if_found} == 0 ]
    then
	echo "----------------------------------------------------------------------" >> ${REDECLARATION_OF_FOO_F}
	echo "$j status=$status" >> ${REDECLARATION_OF_FOO_F}
	cat ${TMPF} >> ${REDECLARATION_OF_FOO_F}
	continue
    fi
    
    echo "----------------------------------------------------------------------" >> ${OTHER_F}
    echo "$j status=$status" >> ${OTHER_F}
    cat ${TMPF} >> ${OTHER_F}
done

/bin/rm ${TMPF}
