all: \
	demo1_psa.json \
	demo1_tna.json \
	demo1_v1model.json \
	psa_ethernet_parsing_only.json \
	psa_skeleton.json \
	tna_ethernet_parsing_only.json \
	tna_skeleton.json \
	v1model_ethernet_parsing_only.json \
	v1model_skeleton.json

# To perform syntax-checking on the TNA architecture files in this
# directory, you need either the proprietary Intel Tofino P4 compiler
# header files, or the open ones in this repository, which are assumed
# by the definition below to be created by going one directory up from
# your copy of the p4-guide repository, and using this command:

# git clone https://github.com/barefootnetworks/Open-Tofino

OPEN_TOFINO_DIR=../../Open-Tofino

clean:
	/bin/rm -f *.json *.p4i

demo1_psa.json: demo1_psa.p4
	p4c-bm2-psa -I../stdlib $< -o $@

demo1_tna.json: demo1_tna.p4
	p4test -I$(OPEN_TOFINO_DIR)/share/p4c/p4include -I../stdlib $<
	touch $@

demo1_v1model.json: demo1_v1model.p4
	p4c -I../stdlib --target bmv2 --arch v1model $<

psa_ethernet_parsing_only.json: psa_ethernet_parsing_only.p4
	p4c-bm2-psa -I../stdlib $< -o $@

psa_skeleton.json: psa_skeleton.p4
	p4c-bm2-psa -I../stdlib $< -o $@

tna_ethernet_parsing_only.json: tna_ethernet_parsing_only.p4
	p4test -I$(OPEN_TOFINO_DIR)/share/p4c/p4include -I../stdlib $<
	touch $@

tna_skeleton.json: tna_skeleton.p4
	p4test -I$(OPEN_TOFINO_DIR)/share/p4c/p4include -I../stdlib $<
	touch $@

v1model_ethernet_parsing_only.json: v1model_ethernet_parsing_only.p4
	p4c -I../stdlib --target bmv2 --arch v1model $<

v1model_skeleton.json: v1model_skeleton.p4
	p4c -I../stdlib --target bmv2 --arch v1model $<
