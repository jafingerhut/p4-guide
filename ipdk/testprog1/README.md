`testprog1.p4` is intended to be close to the simplest P4 program one
can write that exercises a bug in the p4c-dpdk compiler as of
2023-Mar-24: sometimes it generates 'mov' instructions in the '.spec'
output file that move a header variable to another header variable.
The DPDK software switch does not support these, and p4c-dpdk should
expand them into copying all fields individually, plus correct code
for handling the valid bit.

Update: I believe this bug was fixed via this PR in 2023-Sep:
https://github.com/p4lang/p4c/pull/4153
