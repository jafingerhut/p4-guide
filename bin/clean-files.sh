#! /bin/bash
# Copyright 2021 Andy Fingerhut
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


# Delete files that are typically produced as output of commands like
# p4c, simple_switch_grpc, and ptf, at least using the file naming
# conventions in this repository.

/bin/rm -f *.p4i *.p4info.txt *.p4info.txtpb *.json ss-log.txt ptf.log ptf.pcap
sudo rm -fr __pycache__ ptf/__pycache__
