This is a simple test program that when no preprocessor symbols are
defined, passes all tests auto-generated by p4testgen.

```bash
./compile.sh
./create-ptf-test.sh
```

However, if you define preprocessor symbol `USE_RANGE_MATCH_KIND`,
which changes only one line of the P4 program, defining an 8-bit table
key field as match kind `range` instead of `exact`, the attempt to
install an entry in that table fails.

```bash
./compile.sh -DUSE_RANGE_MATCH_KIND
./create-ptf-test.sh -DUSE_RANGE_MATCH_KIND
```

```bash
./compile.sh -DUSE_128BIT_ACTION_PARAMETER
./create-ptf-test.sh -DUSE_128BIT_ACTION_PARAMETER
```

After running the commands above, I used the following commands to try running the PTF tests:

```bash
BASENAME="testprog3"
/bin/rm -fr ~/.ipdk/volume/testprog3 ; cp -pr $HOME/p4-guide/ipdk/testprog3 ~/.ipdk/volume/
start-infrap4d-and-load-p4-base-os.sh ${BASENAME} ${BASENAME}
with-ptf-env ./runptf.sh
```

Results when using the IPDK networking container v23.07:

Without any preprocessor symbols defined: all tests passed

With `-DUSE_RANGE_MATCH_KIND`: All tests passed except the one that
tried to add an entry to table `t1` with a range match criteria.

With `-DUSE_128BIT_ACTION_PARAMETER`: First 2 tests passed, which did
not try to add any table entries, only sent in a packet.  The 3rd test
tried to add a table entry to `t1` with action `send`, which takes a
128-bit action parameter.  During that test, it appears that the
`infrap4d` process crashed.  Evidence: all later tests also failed,
whether they tried to add a table entry or not, and there was no
`infrap4d` process running within the container any longer after the
PTF tests were complete.