# 

```bash
p4test demo-if-stmts1.p4
p4c-bm2-ss demo-if-stmts1.p4 -o demo-if-stmts.json
~/p4-guide/bin/p4c-dump-many-passes.sh demo-if-stmts1.p4
~/p4-guide/bin/p4c-delete-duplicate-passes.sh demo-if-stmts1.p4 tmp
```

The pass "RemoveParserIfs" does what its name implies: it tranforms
the program into one with no if statements in parser states, but is
equivalent to the original program.

To see what it does for this program, you can do this:

```bash
diff -c tmp/demo-if-stmts1-FrontEnd_17_BindTypeVariables.p4 tmp/demo-if-stmts1-FrontEnd_22_RemoveParserIfs.p4
```

The pass "InlineFunctions" replaces function calls with appropriately
modified versions of their bodies.  Here are the changes made by this
pass:

```bash
diff -c tmp/demo-if-stmts1-FrontEnd_56_RemoveActionParameters.p4 tmp/demo-if-stmts1-FrontEnd_57_InlineFunctions.p4
```

The Predication pass replaces `if` statements that contain only
assignments in their branches, with (usually, except sometimes for
some bugs) equivalent sequences of assignment statements that use
ternary conditional expressions on the right hand side.

```bash
diff -c tmp/demo-if-stmts1-BMV2::SimpleSwitchMidEnd_24_FlattenInterfaceStructs.p4 tmp/demo-if-stmts1-BMV2::SimpleSwitchMidEnd_26_Predication.p4
```

The LocalCopyPropagation pass eliminates some assignments, by
replacing later occurrences of the variables on their left-hand sides,
with the right-hand side expression.  This reduces the number of
assignment statements, with the tradeoff of making some expressions
longer.

```bash
diff -c tmp/demo-if-stmts1-BMV2::SimpleSwitchMidEnd_28_ConstantFolding.p4 tmp/demo-if-stmts1-BMV2::SimpleSwitchMidEnd_29_LocalCopyPropagation.p4
```
