#! /bin/bash

for j in $*
do
    echo "Starting tcpdump on port $j to file tcpdump-$j.pcap"
    tcpdump -i $j -w tcpdump-${j}.pcap &
done
