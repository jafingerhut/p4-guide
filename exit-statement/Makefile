P4GUIDE=$(HOME)/p4-guide

all: \
	exit-1-bmv2.p4i

%.p4i: %.p4
	/bin/mkdir -p tmp out-p4testgen
	@echo "------ p4test ----------------------------------"
	p4test $<
	@echo "------ p4c-bm2-ss ----------------------------------"
	p4c-bm2-ss $< -o `basename $< .p4`.json
	$(P4GUIDE)/bin/p4c-dump-many-passes.sh $<
	$(P4GUIDE)/bin/p4c-delete-duplicate-passes.sh $< tmp
	p4testgen --target bmv2 --arch v1model --max-tests 1000 --out-dir out-p4testgen --test-backend ptf $<

clean:
	/bin/rm -f *.p4i *.json *.spec *.txtpb testme.p4 ptf.log ptf.pcap ss-log.txt
	/bin/rm -fr tmp
