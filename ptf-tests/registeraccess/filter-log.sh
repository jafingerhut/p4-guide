#! /bin/bash

# grep for some selected lines of interest in the simple_switch_grpc log

#cat ss-log.txt | egrep '((Received|Sending) packet of length|Transmitting packet of size |Transmitting packet-in|Extracting header '.*'|Pipeline '.*': start|(Read|Wrote) register |Processing (packet-out|IPv4 packet|non-IPv4 packet:) )' | grep -v log_msg

cat ss-log.txt | egrep '((Received) packet of length|(Read|Wrote) register |Processing (packet-out|IPv4 packet|non-IPv4 packet:) )' | grep -v log_msg
