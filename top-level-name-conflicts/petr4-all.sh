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
ERRSTATUSF="error-exit-status.txt"
ERRORINOUTPUTF="error-in-output.txt"
OTHER_F="other-error.txt"

for j in ${ERRSTATUSF} ${ERRORINOUTPUTF} ${OTHER_F}
do
    /bin/cp /dev/null $j
done

for j in $*
do
    /bin/rm ${TMPF} >& /dev/null
    petr4 -I $HOME/p4c/p4include $j >& ${TMPF}
    status=$?
    if [ ${status} != 0 ]
    then
	echo "----------------------------------------------------------------------" >> ${ERRSTATUSF}
	echo "$j status=$status" >> ${ERRSTATUSF}
	cat ${TMPF} >> ${ERRSTATUSF}
	continue
    fi
    
    grep --quiet -i 'error:' ${TMPF}
    zero_if_found=$?
    if [ ${zero_if_found} == 0 ]
    then
	echo "----------------------------------------------------------------------" >> ${ERRORINOUTPUTF}
	echo "$j status=$status" >> ${ERRORINOUTPUTF}
	cat ${TMPF} >> ${ERRORINOUTPUTF}
	continue
    fi
    
    echo "----------------------------------------------------------------------" >> ${OTHER_F}
    echo "$j status=$status" >> ${OTHER_F}
    cat ${TMPF} >> ${OTHER_F}
done

/bin/rm ${TMPF}
