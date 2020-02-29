This is just a little bit of experimentation to see what the C
preprocessor actually accepts as legal input.

I know you can use #include to include files that are not full top
level constructs of the host language, whether that is P4, C, or C++,
e.g. you can include a file that contains part of the definition of a
function, or P4 control.

And a #include'd file can have #ifdef ... #endif code in it.

But can you split a single #ifdef ... #endif across two consecutive
#include'd files, e.g. with the #ifdef and some lines of code in the
first file, and some more lines followed by the #endif in the second
file?  That is, does the C preprocessor work by effectively first
doing all of the #include directives, and then a second pass that
looks at the result text for #ifdef ... #endif constructs?

The answer, at least for the versions of code I tested shown below, is
no: it is an error to attempt to process such input files.

```bash
$ cpp --version
cpp (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0
Copyright (C) 2017 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

$ cpp -I/usr/local/share/p4c/p4include exper1a.p4 > exper1a.cpp-out.txt
In file included from exper1a.p4:22:0:
exper1b.p4:2:0: error: unterminated #ifdef
 #ifdef DEFINE_A
 
In file included from exper1a.p4:23:0:
exper1c.p4:2:2: error: #else without #if
 #else
  ^~~~
exper1c.p4:6:2: error: #endif without #if
 #endif
  ^~~~~

$ p4c --version
p4c 1.2.0 (SHA: 62fd40a0)

$ p4c exper1a.p4 
In file included from exper1a.p4:22:0:
exper1b.p4:2:0: error: unterminated #ifdef
 #ifdef DEFINE_A
 
In file included from exper1a.p4:23:0:
exper1c.p4:2:2: error: #else without #if
 #else
  ^~~~
exper1c.p4:6:2: error: #endif without #if
 #endif
  ^~~~~
```
