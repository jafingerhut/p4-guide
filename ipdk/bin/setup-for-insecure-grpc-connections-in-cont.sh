#! /bin/bash

# Remove all certificate files, so that programs run after this time
# that check for the existence of those files will fall back to using
# insecure P4Runtime gRPC connections.
echo "Removing all certificate files from /usr/share/stratum/certs ..."
/bin/rm -f /usr/share/stratum/certs/*

# Replace run_infrap4d.sh script with a slightly modified version that
# also checks for the existence of the certificate files, and falls
# back to starting infrap4d, in a mode where it allows insecure gRPC
# connections to be made.
echo "Replace run_infrap4d.sh with slightly enhanced version ..."
/bin/cp -p /tmp/bin/run_infrap4d.sh /root/scripts/run_infrap4d.sh
