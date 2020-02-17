# Instructions to generate and compile code for Example 1

First, run this Python program:

```bash
$ ./example1-generator.py --num-fields 32
```

That will write to these two files:

+ generated_my_custom_hdr_fields.p4
+ generated_read_write_custom_header_at_index.p4

Copies of the files as generated on my system when I was developing it
are included in the [`generated-files`](generated-files/) directory,
in case you want to look at them without generating them yourself.

Both of those files have `#include` directives in the program
`example1.p4`, which you can now compile:

```bash
$ p4c --target bmv2 --arch v1model example1.p4
```

When developing and debugging programs where parts of them are
auto-generated, it can often be helpful to look at the final version
after all of the code generation is complete, and the `#include`
directives have been processed.  Executing the `p4c` command will
create a file `example1.p4i` that contains exactly that.  It will
still contain some lines that look like this:

```
# 39 "example1.p4" 2
```

These are used by the P4 compiler to track which original input file
and line number each line of code came from, so when it generates
error or warning messages, they can mention the correct file and line
number of the files before the preprocessor ran, rather than after.
Such lines have no effect on the execution behavior of the P4 program.

Such a `.p4i` file will also contain the full contents of the
`v1model.p4` #include file, which you will likely want to skip over.
Using your text editor to search for occurrences of the file name you
are interested in, e.g. `example.p4`, can be useful for that.

Note that I have written the `example1-generator.py` program to accept
a command line parameter with the number of fields to generate.  This
can be generalized to any number of parameters you wish, or files of
data, etc., that can be used by your Python (or other language)
program to generate the code you wish, subject only to the limits of
your imagination and time.
