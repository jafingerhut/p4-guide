# Introduction

This document contains notes as I (Andy Fingerhut) learn some things
about EBPF, and comparing it to P4.  Much of what is here assumes
knowledge of P4, but not about EBPF.


# A few introductory facts about EBPF

EBPF programs are written in instructions of a simple virtual machine
that is specific to EBPF.  This instruction set has some similarities
to the Java virtual machine byte code instructions:

+ Programs in both are intended to at least usually have an automated
  verifier program perform checks on them that can guarantee that
  executing the program is safe in multiple ways.
  + Both guarantee no stray memory references to arbitrary memory locations.
  + EBPF's verifier also disallows programs that can execute
    arbitrarily large numbers of instructions.
+ There are compilers for multiple source languages that compile to
  JVM byte codes (not only Java, e.g. Scala, Clojure), and similarly
  for multiple source langauges that compile to EBPF instructions (at
  least C using LLVM C compiler with EBPF back end, not sure where to
  find a list of others).

EBPF programs are designed for safe execution within the Linux kernel.
User-space programs with appropriate privileges (typically super-user)
choose an event or hook in the kernel, and specify an EBPF program to
run when that event occurs.  Examples of such events include:

+ For XDP, when a packet is received from the NIC, and I believe also
  just before a packet is sent to the NIC.
+ For hundreds of other EBPF programs that many developers use every
  day, there are trace points written by Linux kernel developers in
  the kernel code that can be treated as events that trigger the
  execution of EBPF programs, too.  Also any function in the kernel
  with a name (perhaps with some restrictions).  See the book "BPF
  Performance Tools" for a wealth of examples, where triggers include:
  + a process being started
  + a block read/write operation being initiated in the file system
    code, or completed.
  + a TCP socket being created

My guess is that most users of EBPF might not even be aware that it
can be used to process packets.  But I will not say much more about
non-packet-processing uses of EBPF here.

It is possible to disable the EBPF verifier and execute EBPF programs
without passing the verifier's checks, but I believe very few people
want to do so.  They want the extra safety that comes with passing the
verification step, that their EBPF programs will not cause problems
because of bugs in their programs.

Taking C programs as one example source code language for targeting
EBPF, clearly not all C programs can pass the verification checks,
e.g. those with loops with arbitrary numbers of iterations, or those
that calculate arbitrary integer values, cast them to pointers, and
dereference those pointers.  So there is some "EBPF safe subset of C"
that one must write their C programs in if they want them to pass the
verifier.


## xdping_kern.c - an EBPF program that 

C program that can be compiled to EBPF using clang with EBPF back end.

https://github.com/xdp-project/bpf-next/blob/master/tools/testing/selftests/bpf/progs/xdping_kern.c

This is the corresponding user space program:

https://github.com/xdp-project/bpf-next/blob/master/tools/testing/selftests/bpf/xdping.c



## References

https://qmonnet.github.io/whirl-offload/2016/09/01/dive-into-bpf/

This book is 880 pages of examples of Linux performance and behavior
monitoring tools created using EBPF, and only a fraction of them are
related to the networking part of the Linux kernel.  Of those, I doubt
any of them involve EBPF programs that process packets.

The entire focus of the book is on using EBPF to hook into various
trace points and hooks in the Linux kernel, such that when events of
interest occur, the EBPF program(s) configured will execute, typically
modifying some EBPF maps in the process.  User space programs
typically read the contents of these maps and present statistical or
other kinds of summary results to the user.

"BPF Performance Tools", 1st Ed., Brendan Gregg, 2019, Addison-Wesley
Professional,
https://www.amazon.com/gp/product/0136554822?pf_rd_r=8HZM1ZFCW9GG1Y376295&pf_rd_p=9d9090dd-8b99-4ac3-b4a9-90a1db2ef53b
