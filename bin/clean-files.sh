#! /bin/bash

# Delete files that are typically produced as output of commands like
# p4c, simple_switch_grpc, and ptf, at least using the file naming
# conventions in this repository.

/bin/rm -f *.p4i *.p4info.txt *.json ss-log.txt ptf.log ptf.pcap
sudo rm -fr __pycache__ ptf/__pycache__
