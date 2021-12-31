#! /bin/bash

for j in *
do
    if [ -d $j ]
    then
	cd $j
	../../bin/clean-files.sh
	cd ..
    fi
done
