#! /bin/bash
# Copyright 2024 Andy Fingerhut
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
