#! /bin/bash

p4c --version

for j in $*
do
    k=`basename $j .p4`
    #echo $k
    if [ "$k" == "before-ingress" -o "$k" == "after-ingress" ]
    then
	#echo "Skipping"
	continue
    fi
    echo "----------------------------------------"
    set -x
    p4c --target bmv2 --arch v1model --p4runtime-files $k.p4info.txtpb $k.p4
    exit_status=$?
    set +x
    #echo "Exit status: $exit_status"
done

