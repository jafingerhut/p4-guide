#! /bin/bash

#for j in /usr/lib/x86_64-linux-gnu/*

for j in "$@"
do
    if [ ! -d "$j" ]
    then
#        grep RSA_set0_key "$j"
#        if [ $? -eq 0 ]
#        then
#            echo $j " <------ grep found RSA_set0_key -------------------------"
#        fi
        nm -D "$j" | grep RSA_set0_key
        if [ $? -eq 0 ]
        then
            echo "$j" " <--- see previous line(s) for occurrences of RSA_set0_key in 'nm -D' output of this file"
        fi
    fi
done
