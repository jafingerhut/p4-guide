#! /bin/bash

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
