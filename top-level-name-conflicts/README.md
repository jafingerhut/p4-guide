# Determine P4_16 top level objects that p4c allows to have the same name

Recommended commands to generate many small P4_16 test programs,
compile them all using `p4test`, and categorize their results into one
of a few common categories that I have seen:

+ no error
+ 'foo duplicates foo' error
+ 'Re-declaration of foo' error
+ other error

```
$ mkdir auto-gen-test-programs
$ ../generate-p416-test-programs.py
$ ../compile-all.sh *.p4
```

After the last command is complete, the results of a `p4test`
compilation run are categorized and put into a file with a `.txt`
suffix in its name.

There is also a command to run
[Petr4](https://github.com/cornell-netlab/petr4) on all test programs:

```
$ ../petr4-all.sh *.p4
```

Again, look for results in one of several files with a `.txt` suffix in
its name.
