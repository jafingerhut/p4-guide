%.p4i: %.p4
	mkdir -p tmp
	p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast $<

all: \
	loop-var-can-be-declared-before-loop1.p4i \
	loop-var-can-be-used-in-slice1.p4i \
	loop-var-in-scope-outside-of-loop1.p4i \
	loop-var-modifiable-in-body1.p4i \
	var-shadowing-test1.p4i

var-shadowing-test2-p4testgen: var-shadowing-test2.p4
	p4testgen --target bmv2 --arch v1model --max-tests 10 --out-dir out-p4testgen --test-backend ptf $<
