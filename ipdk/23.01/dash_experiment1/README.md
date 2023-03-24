dash_experiment1 is an experimental subset of the P4 program in the
sibling directory 'dash', attempting to test a version of the .spec
file that never does 'mov' on entire header variables, which is
apparently not supported by the DPDK software switch.

See dash/README.md for more details on the original program from which
this was modified.
