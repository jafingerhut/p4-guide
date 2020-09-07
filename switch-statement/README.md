# p4c test programs containing switch statements

As of the indicated version of the p4lang/p4c repository, the programs
in the `egrep` command output below appear to be all of the P4_16 test
programs that contain switch statements.  Note that the `egrep` regex
pattern used below cannot be used to find P4_14 switch statements,
since the syntax there is different, and I do not see any
straightforward way to use grep-like methods to find P4_14 switch
statements.  Thus this will focus on the P4_16 test programs with
switch statements.

```
$ git clone https://github.com/p4lang/p4c
$ cd p4c
$ git checkout 790e06c1c4dda3031961fc8ce4b648f2ec93a548
$ git log -n 1 | head -n 5
commit 790e06c1c4dda3031961fc8ce4b648f2ec93a548
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Sun Sep 6 17:41:09 2020 -0400

    Add a test case verifying that p4c gives compile time error for bad switch label (#2526)



$ find . -name '*.p4' | xargs egrep '\bswitch *\(' | egrep -v '/p4_1[46]_samples_outputs/' | egrep -v '/p4_16_errors_outputs/' | sort
./testdata/p4_16_errors/duplicate-label.p4:        switch (t.apply().action_run) {
./testdata/p4_16_errors/incorrect-label.p4:        switch (t1.apply().action_run) {
./testdata/p4_16_errors/switch_expression.p4:        switch (hdr.field) {
./testdata/p4_16_samples/apply-cf.p4:        switch (t.apply().action_run) {
./testdata/p4_16_samples/basic_routing-bmv2.p4:            switch (ipv4_fib.apply().action_run) {
./testdata/p4_16_samples/cases.p4:        switch (t.apply().action_run) {
./testdata/p4_16_samples/default-switch.p4:        switch (t.apply().action_run) {
./testdata/p4_16_samples/def-use.p4:        switch(t.apply().action_run) {
./testdata/p4_16_samples/exit5.p4:        switch (t.apply().action_run) {
./testdata/p4_16_samples/inline-switch.p4:        switch (t.apply().action_run) {
./testdata/p4_16_samples/issue1595-1.p4:        switch(t.apply().action_run) {
./testdata/p4_16_samples/issue1595.p4:        switch (t1.apply().action_run) {
./testdata/p4_16_samples/issue-2123.p4:            switch (ipv4_fib.apply().action_run) {
./testdata/p4_16_samples/issue2153-bmv2.p4:        switch (simple_table.apply().action_run) {
./testdata/p4_16_samples/issue2170-bmv2.p4:        switch (simple_table.apply().action_run) {
./testdata/p4_16_samples/stack_ebpf.p4:        switch (Check_src_ip.apply().action_run) {
./testdata/p4_16_samples/switch_ebpf.p4:        switch (Check_src_ip.apply().action_run) {
./testdata/p4_16_samples/ternary2-bmv2.p4:        switch (ex1.apply().action_run) {
./testdata/p4_16_samples/uninit.p4:        switch (t.apply().action_run) {
```

The table below lists various kinds of cases that seem useful to test
a P4_16 compiler for its capability in compiling the existing P4_16
switch statement in version 1.2.1 and earlier of the language
specification, which is restricted to a switch expression of the form
`table_name.apply().action_run`:

All test programs listed in the table are in the
`p4c/testdata/p4_16_samples` directory, except for those with
`p4_16_errors/` at the beginning that are in the
`p4c/testdata/p4_16_errors` directory.

| Kind of switch statement | Test program name | Expected result | p4c as of version above gives expected result? |
| ------------------------ | ----------------- | --------------- | ---------------------------------------------- |
| no body after the last label | last-switch-label-without-body.p4 attached to p4c issue #2527 | compile-time error?  The P4_16 version 1.2.1 spec is silent on this issue, as far as I can see. | no error.  Behaves as if there was an empty body `{ }` after the last label. |
| duplicate switch labels, which are not `default` | p4_16_errors/duplicate-label.p4 | compile-time error | yes |
| duplicate `default` switch labels | None yet.  See proposed test program in p4c issue #2525 | compile-time error | Warning about one of the default cases being not last, but no error.  Probably will be fixed in p4c soon. |
| `default` switch label in any but the last case of the switch statement | default-switch.p4 | compile-time warning only | compile-time warning |
| a switch statement with no `default` label, and labels that include all possible values of the switch expression | | no error or warning | tbd |
| a switch statement with no `default` label, and labels that DO NOT include all possible values of the switch expression | issue2153-bmv2.p4 and several others.  issue2153-bmv2.stf is a packet processing test that makes visible in the output packets, and has expected output packets that would cause the test to fail if the switch statement executed the one branch rather than doing nothing, if the one label is not matched, | no error or warning | While some P4 developers might want an option to get a warning when the switch branches are not exhaustive, there seems to be a multi-year history of using such non-exhaustive switch statements. The P4_16 language specification 1.2.1 and earlier has always explicitly stated that "if no case matches, execution of the program simply continues" (Section 11.7 "Switch statement").  The fix for p4c issue #2153 was to change p4c's internals so that it no longer assumed that the cases of a switch statement in the source code were exhaustive. |
| a switch statement with a label that is not any of the possible values of evaluating the switch expression | p4_16_errors/incorrect-label.p4 | compile-time error | yes |
| a switch statement with an expression not of the form `table_name.apply().action_run` | p4_16_errors/switch_expression.p4 | compile-time error | yes, but the reason for writing these notes is to present to the P4 LDWG a generalized switch statement that would allow other types of switch expressions |
| a switch statement where the non-`default` labels are exhaustive, but there is still an explicit `default` label that can never be executed | inline-switch.p4 | might be nice to have a warning that default branch is unreachable code? | no warning.  Output of mid-end includes the default case still, which seems correct but unnecessary. |

issue2170-bmv2.p4 and corresponding STF test exercise the behavior
that if a table gets a miss, and executes its default action, then the
branch of the switch statement that should be executed is the one with
that action as the label.  That matches what the spec says the
behavior should be.  It also exercises the use of a `return` statement
inside of a switch case.

Which of these programs in p4_16_samples directory contain STF tests?

```
no  apply-cf.p4
no  basic_routing-bmv2.p4
no  cases.p4
no  def-use.p4
no  default-switch.p4
no  exit5.p4
no  inline-switch.p4
no  issue-2123.p4
no  issue1595-1.p4
no  issue1595.p4
yes issue2153-bmv2.p4   switch has no `default` label, and labels not exhaustive
yes issue2170-bmv2.p4
no  stack_ebpf.p4
yes switch_ebpf.p4
yes ternary2-bmv2.p4
no  uninit.p4
```
