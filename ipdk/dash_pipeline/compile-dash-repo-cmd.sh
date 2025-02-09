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


# The p4c-dpdk command line below is as close to the one used in the
# DASH repo file dash-pipeline/Makefile as I can make it.

P4_DPDK_OUTDIR="output"
P4_MAIN="dash_pipeline.p4"
mkdir -p ${P4_DPDK_OUTDIR}

set -x

p4c-dpdk -DTARGET_DPDK_PNA -DPNA_CONNTRACK --pp ${P4_DPDK_OUTDIR}/dash_pipeline.pp.p4 \
	-o ${P4_DPDK_OUTDIR}/dash_pipeline.spec --arch pna \
	--bf-rt-schema ${P4_DPDK_OUTDIR}/dash_pipeline.p4.bfrt.json \
	--p4runtime-files ${P4_DPDK_OUTDIR}/dash_pipeline.p4.p4info.txt \
	${P4_MAIN}
