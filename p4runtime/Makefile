P4C_PSA=p4c-bm2-psa
P4C_V1MODEL=p4c-bm2-ss

# It is not really expected that p4c-bm2-ss should produce useful
# output for P4_16 programs written for the PSA architecture, but for
# now, it can sometimes be useful to compare the results produced by
# p4c-bm2-ss vs. p4c-bm2-psa, to see things that the output of
# p4c-bm2-psa is missing.

all: psa-example-digest-bmv2.psa.p4info.txtpb \
	psa-example-digest-bmv2.v1model.p4info.txtpb

psa-example-digest-bmv2.psa.p4info.txtpb: psa-example-digest-bmv2.p4
	$(P4C_PSA) --p4runtime-files $@ $<

psa-example-digest-bmv2.v1model.p4info.txtpb: psa-example-digest-bmv2.p4
	$(P4C_V1MODEL) --p4runtime-files $@ $<
