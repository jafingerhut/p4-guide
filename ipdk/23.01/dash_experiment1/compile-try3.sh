#! /bin/bash

# This p4c-dpdk command is like compile-dash-repo-cmd.sh but somewhat
# closer to a different command I tried that gave a compiler bug.
# Just experimenting here to see what causes the bug.

P4_DPDK_OUTDIR="output"
P4_MAIN="dash_pipeline.p4"
mkdir -p ${P4_DPDK_OUTDIR}

set -x

# try2 - Command used in DASH repo for CI
# no compiler bug
p4c-dpdk -DTARGET_DPDK_PNA -DPNA_CONNTRACK \
	--pp ${P4_DPDK_OUTDIR}/dash_pipeline.pp.p4 \
	-o ${P4_DPDK_OUTDIR}/dash_pipeline.spec --arch pna \
	--bf-rt-schema ${P4_DPDK_OUTDIR}/dash_pipeline.p4.bfrt.json \
	--p4runtime-files ${P4_DPDK_OUTDIR}/dash_pipeline.p4.p4info.txt \
	${P4_MAIN}

# try3 - omit generation of pretty-printed P4 output
# no compiler bug
#p4c-dpdk -DTARGET_DPDK_PNA -DPNA_CONNTRACK \
#	-o ${P4_DPDK_OUTDIR}/dash_pipeline.spec --arch pna \
#	--bf-rt-schema ${P4_DPDK_OUTDIR}/dash_pipeline.p4.bfrt.json \
#	--p4runtime-files ${P4_DPDK_OUTDIR}/dash_pipeline.p4.p4info.txt \
#	${P4_MAIN}

# try4 - move '--arch pna' command line option earlier
# no compiler bug
#p4c-dpdk -DTARGET_DPDK_PNA -DPNA_CONNTRACK \
#	--arch pna \
#	-o ${P4_DPDK_OUTDIR}/dash_pipeline.spec \
#	--bf-rt-schema ${P4_DPDK_OUTDIR}/dash_pipeline.p4.bfrt.json \
#	--p4runtime-files ${P4_DPDK_OUTDIR}/dash_pipeline.p4.p4info.txt \
#	${P4_MAIN}

# try5 - add '--context <filename>' command line option to generate context.json
# Compiler Bug!
# It appears that there is a compiler bug for this program while trying
# to generate the context.json output file.
# TODO: Is that file needed for running the program within IPDK
# container on DPDK software switch?
#p4c-dpdk -DTARGET_DPDK_PNA -DPNA_CONNTRACK \
#	--arch pna \
#	-o ${P4_DPDK_OUTDIR}/dash_pipeline.spec \
#	--bf-rt-schema ${P4_DPDK_OUTDIR}/dash_pipeline.p4.bfrt.json \
#	--p4runtime-files ${P4_DPDK_OUTDIR}/dash_pipeline.p4.p4info.txt \
#        --context ${P4_DPDK_OUTDIR}/context.json \
#	${P4_MAIN}

# try6 - remove almost all output options except --context to see if
# Compiler Bug still occurs.
#p4c-dpdk -DTARGET_DPDK_PNA -DPNA_CONNTRACK \
#	--arch pna \
#        --context ${P4_DPDK_OUTDIR}/context.json \
#	${P4_MAIN}
