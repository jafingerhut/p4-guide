# Instructions to generate and compile code for Example 1

First, run this Python program:

```bash
$ ./example1-generator.py --num-fields 32
```

That will write to these two files:

+ generated_my_custom_hdr_fields.p4
+ generated_read_write_custom_header_at_index.p4

Copies of the files as generated on my system when I was developing it
are included in the `[generated-files](generated-files/)` directory,
in case you want to look at them without generating them yourself.

Both of those files have `#include` directives in the program
`example1.p4`, which you can now compile:

```bash
$ p4c --target bmv2 --arch v1model example1.p4
```

Note that I have written the `example1-generator.py` program to accept
a command line parameter with the number of fields to generate.  This
can be generalized to any number of parameters you wish, or files of
data, etc., that can be used by your Python (or other language)
program to generate the code you wish, subject only to the limits of
your imagination and time.
