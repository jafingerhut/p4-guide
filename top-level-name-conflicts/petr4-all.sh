#! /bin/bash

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
