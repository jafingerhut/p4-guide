# Copyright 2024 Andy Fingerhut
# SPDX-License-Identifier: Apache-2.0

P4GUIDE=$(HOME)/p4-guide

all: p4test \
	demo-if-stmts1.json \
	demo-if-stmts2.spec \
	demo-if-stmts3.spec

p4test:
	p4test demo-if-stmts1.p4
	p4test demo-if-stmts2.p4
	p4test demo-if-stmts3.p4

demo-if-stmts1.json: demo-if-stmts1.p4
	p4c-bm2-ss demo-if-stmts1.p4 -o demo-if-stmts1.json
	$(P4GUIDE)/bin/p4c-dump-many-passes.sh demo-if-stmts1.p4
	$(P4GUIDE)/bin/p4c-delete-duplicate-passes.sh demo-if-stmts1.p4 tmp

demo-if-stmts2.spec: demo-if-stmts2.p4
	p4c-dpdk --arch pna demo-if-stmts2.p4 -o demo-if-stmts2.spec

demo-if-stmts3.spec: demo-if-stmts3.p4
	p4c-dpdk --arch psa demo-if-stmts3.p4 -o demo-if-stmts3.spec

clean:
	/bin/rm -f demo-if-stmts1.json demo-if-stmts2.spec demo-if-stmts3.spec
	/bin/rm -fr tmp
