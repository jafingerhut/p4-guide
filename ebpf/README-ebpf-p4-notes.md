# Introduction

This document contains notes as I (Andy Fingerhut) learn some things
about EBPF, and comparing it to P4.  Much of what is here assumes
knowledge of P4, but not about EBPF.


# A few facts about EBPF

A short article that also has a nice summary of EBPF:
https://lwn.net/Articles/740157/ There is some overlap with this
article, but that article and this one each cover facts the other does
not.

EBPF programs are written in instructions of a simple virtual machine
that is specific to EBPF.  This instruction set has some similarities
to the Java virtual machine byte code instructions:

+ Programs in both are intended to have (at least usually) a verifier
  perform checks on them that guarantee that executing the program is
  safe in multiple ways.
  + Both guarantee no stray memory references to arbitrary memory
    locations. The JVM's verifier is also intended to make some
    guarantees of type safety in the Java type system.  I believe
    EBPF's verifier has no type system or guarantees of type safety
    more than C does, i.e. casts between arbitrary types are probably
    allowed.
  + EBPF's verifier also disallows programs that can execute
    arbitrarily large numbers of instructions.
+ There are compilers for multiple source languages to both:
  + For the JVM, source languages include Java, Scala, Groovy, and
    Clojure.
  + For EBPF, source languages include EBPF assembler, C (via LLVM
    Clang compiler EBPF back end), and Rust (see the
    [redbpf](https://github.com/redsift/redbpf) project).
+ Both have JIT compilers for translating VM instructions to the host
  CPUs native instruction set, for better performance.

EBPF programs are designed for safe execution within the Linux kernel.
User-space programs with super-user privileges choose an event or hook
in the kernel, and specify an EBPF program to run when that event
occurs.  Examples of such events include:

+ For XDP, when a packet is received from the NIC, before it begins
  processing in the rest of the Linux kernel networking code.
+ There are proposed patches for the Linux kernel that would enable an
  EBPF program to be run via XDP, just before the packet is sent to a
  NIC, after the rest of the Linux kernel network code has run on it.
  + The latest message I have seen with an updated, but not yet merged
    into the Linux kernel, is 2020-May-13 here:
    https://lore.kernel.org/netdev/20200513014607.40418-7-dsahern@kernel.org/T/
  + An earlier version of the proposed changes was described in this
    2020-Feb-26 message: https://lwn.net/Articles/813406/
+ There are also hooks in the Linux kernel tc (Traffic Control) module
  to invoke EBPF programs, both in receive and transmit direction.
  There is a fair amount of functionality in the Linux kernel
  networking code between these EBPF invocation points and
  transmit/receive on a NIC.
  + This 2017 presentation:
    https://archive.fosdem.org/2017/schedule/event/ebpf_xdp/attachments/slides/1800/export/events/attachments/ebpf_xdp/slides/1800/2017_fosdem.pdf
    describes some of the differences in XDP and tc invocation points
    for EBPF programs, but I do not know what kernel version it
    represents.  There is likely to be more recent information
    available for the latest kernel versions as of 2020.
+ For hundreds of other EBPF programs that are often used by many
  developers, there are trace points written by Linux kernel
  developers in the kernel code that can trigger the execution of EBPF
  programs, too.  Also many named functions in the kernel.  See the
  book "BPF Performance Tools" for a wealth of examples, where
  triggers include:
  + a process being started
  + a block read/write operation being initiated in the file system
    code, or completed.
  + a TCP socket being created

My guess is that most users of EBPF might not even care that it can be
used to process packets.  But I will not say much more about
non-packet-processing uses of EBPF here.

It is possible to disable the verifier and execute EBPF programs
without passing the verifier's checks, but I believe very few people
want to do so.  They want the extra safety that comes with passing the
verifier's checks.  Skipping those leaves you vulnerable to bugs in an
EBPF program causing memory corruption in kernel data structures.

Taking C programs as one example source language for targeting EBPF,
clearly not all C programs can pass the verification checks,
e.g. those with loops with arbitrary numbers of iterations, or those
that calculate arbitrary integer values, cast them to pointers, and
dereference those pointers.  So there is some "EBPF safe subset of C"
that one must write programs in if they want them to pass the
verifier.

Some of the restrictions on this "EBPF safe subset of C" are
documented on this page: https://docs.cilium.io/en/latest/bpf/ Search
for the word "pitfall" to find 11 numbered items describing some of
the rules you must follow when writing C code that can pass the EBPF
verifier.  Below is the list of the 11 headings in that part of the
document, as retrieved on 2020-Dec-18.  The linked document has many
more details, sometimes explaining the reason the restriction is
there, and often giving advice on how to write C programs that stay
within the restrictions.

1. Everything needs to be inlined, there are no function calls (on
   older LLVM versions) or shared library calls available.
2. Multiple programs can reside inside a single C file in different sections.
3. There are no global variables allowed.
4. There are no const strings or arrays allowed.
5. Use of LLVM built-in functions for memset()/memcpy()/memmove()/memcmp().
6. There are no loops available (yet).
7. Partitioning programs with tail calls.
8. Limited stack space of maximum 512 bytes.
9. Use of BPF inline assembly possible.
10. Remove struct padding with aligning members by using #pragma pack.
11. Accessing packet data via invalidated references

That page also mentions that some EBPF programs can be loaded into a
Netronome NIC.  Given my knowledge from a detailed hardware
presentation on Netronome's NICs from about 2018, where its design was
described as an array of RISC CPU cores with interconnections to many
specialized hardware blocks (e.g. TCAMs, specialized longest-prefix
match tables, hash logic, etc.), it makes sense that any EBPF programs
that passed the Linux kernel verifier would be straightforward to JIT
compile to a RISC CPU's instruction set.  Probably the most fiddly
bits of that would be handling EBPF maps correctly, and perhaps
Netronome might not support all EBPF map types.


# Packet processing in EBPF

From examination of the program `xdping_kern.c` later below, I believe
the following things are all true:

+ The packet to be processed is stored in a contiguous range of
  addresses in memory before your EBPF code begins executing.  Your
  code is given a pointer to the beginning and end of the packet.  You
  can read it or write it wherever you want, up to the end of the
  packet.
+ When you want to parse packets in an EBPF program, you use normal C
  pointers, pointer arithmetic, loads, stores, etc., reading whatever
  fields you want out of the packet, in any order, i.e. you can go
  backwards as well as forward in the packet.  There is nothing like
  P4's `extract` or `advance` calls, but you could easily write C
  functions that behave that way if you wanted to.  The point is that
  in EBPF, nothing _restricts_ you to writing code that looks like a
  P4 parser.
+ When you want to modify packets, you use the same mechanisms.  The
  resulting modified packet must also be in contiguous bytes in
  memory. Thus adding headers in the middle requires copying bytes of
  the original packet to make room in the middle at the desired place.
  There is nothing like P4's `emit` calls on headers.
  + For EBPF programs invoked by XDP, the modified packet can be
    longer or shorter than the original.  By default XDP allocates 256
    bytes of memory before the beginning of the packet, all of which
    could be used for making the packet longer at the beginning.
    Source: https://docs.cilium.io/en/latest/bpf/#xdp Search for the
    word "headroom".
+ You can access EBPF maps whenever you want, in whatever order you
  want relative to reading or writing the packet contents.  There is
  nothing like typical a P4 architecture's restrictions of "parse
  first, then do table lookups and header reading and/or
  modifications, then emit the modified packet".  You could write EBPF
  programs that were of that restricted form if you wanted to, but
  neither EBPF nor XDP does anything to mandate such a structure.
+ EBPF programs invoked by XDP have a small collection of return codes
  that XDP supports. When an EBPF program invoked by XDP returns, XDP
  uses this return code to decide what to do with the packet next,
  including drop, pass up the Linux networking TCP/IP stack normally,
  turn around and send back to the NIC, or redirect to a different
  NIC.  Details: https://docs.cilium.io/en/latest/bpf/#xdp Search for
  word "BPF program return codes".
+ TBD detail: I do not know if the result of processing a single
  packet can be exactly one packet, or more than one.  From the return
  codes discussion in the previous bullet item, I would guess that no
  packet replication is supported in XDP today.

Thus it seems like taking an arbitrary EBPF program that processes
packets, and using automated means to transform it into an equivalent
P4 program, would either be impossible for arbitrary EBPF
programs. Even if it is possible in all cases, it seems that it could
be very inefficient for many EBPF programs, e.g. recirculating back to
the parser as many times as the EBPF program switches between
table/map lookups and back to parsing.  Turning modifications of
arbitrary bytes within the packet, including arbitrarily deep into the
payload, would be a very odd looking P4 program, to say the least.

Mechanically transforming a P4 program into an EBPF program is
definitely feasible, and the open source
[`p4c`](https://github.com/p4lang/p4c) P4 compiler can handle a
significant subset of the P4 language as input.  Implementing an
arbitrary deparser might be challenging to make as efficient as a
hand-coded EBPF program could be, since there could be a fair amount
of memory copying involved, but it seems like a resulting EBPF program
that copies each valid header's memory once into the target packet
would be easy to do mechanically.

It _might_ be technically feasible to devise a more strict EBPF
verifier that only gives a "passes the verifier" result for EBPF
programs that were in a restricted form that could be mechanically
translated into an equivalent P4 program.  Even if this is feasible,
developers of such EBPF programs would need documentation on how to
write EBPF-assembler/C/Rust code that passed the more strict
verifier. In the end, writing a P4 program seems like the more
straightforward technical approach to writing code that targets a
device with restrictions similar to P4 architectures.


## XDP and EBPF tutorial

After writing the next section, I learned of this tutorial to XDP and
EBPF:

https://github.com/xdp-project/xdp-tutorial

It goes into step by step instructions, spread over multiple
exercises, to show:

+ How to compile and load EBPF programs into the kernel.
+ How to modify EBPF maps in an EBPF program running in the kernel,
  and read and print their contents from a user-space program.
+ How to write EBPF programs that modify packets.

I have done a few of the exercises, and skimmed over the rest, and it
seems like a quite good introduction for someone who wants to do these
things, and the exercises I tried all worked as described there on a
freshly installed Ubuntu 20.04 Linux system, plus the Ubuntu packages
it recommends installing.


## xdping_kern.c - An example EBPF program written in C to process packets

The link below is to a simple example C program that can be compiled
to the EBPF VM instruction set, and is intended to process packets by
being invoked from XDP:

https://github.com/xdp-project/bpf-next/blob/master/tools/testing/selftests/bpf/progs/xdping_kern.c

This is the corresponding user space program designed to interact with
the in-kernel EBPF program:

https://github.com/xdp-project/bpf-next/blob/master/tools/testing/selftests/bpf/xdping.c

Below are some notes on a few parts of this C program.

The Linux kernel must be configured with XDP in order to use this
program, and then this EBPF program must be loaded into the kernel.

One of the entry points into this EBPF program is here:
https://github.com/xdp-project/bpf-next/blob/master/tools/testing/selftests/bpf/progs/xdping_kern.c#L89-L90

The `SEC("xdpclient")` is a C preprocessor macro that becomes an
annotation used by the C->EBPF compiler to indicate that the following
function should be placed into a "section" of the resulting ELF format
binary.  The macro is defined here:
https://github.com/xdp-project/bpf-next/blob/master/tools/lib/bpf/bpf_helpers.h#L18-L23

The argument to function `xdping_client` is `struct xdp_md *ctx`,
where struct `xdp_md` is defined here:

https://github.com/xdp-project/bpf-next/blob/master/tools/include/uapi/linux/bpf.h#L3234-L3244

From how some of these fields are used inside of `xdping_kern.c`, it
appears that the fields mean the following:

+ `data` - a pointer to the beginning of the packet's Ethernet header.
  TBD: It is defined as type `__u32`, and then cast to a `void *`
  pointer, which I would have guessed was a 64-bit size quantity,
  unless perhaps the kernel is running in some kind of 32-bit
  addressing mode.  Why is it this way, and how does it work?
+ `data_end` - a pointer to the end of the packet, probably either to
  the last byte, or maybe one past the last byte.  From one of the XDP
  tutorial exercises I ran, it appears that (data_end - data) contains
  Ethernet + IPv6 + ICMP headers and ICMP payload, but no Ethernet
  FCS.  That is a minor detail for now.
+ `data_meta` - not used in xdping_kern.c so I do not have a guess yet
+ `ingress_ifindex` - comment after definition says
  `rxq->dev->ifindex`.  Looks like some kind of identifier for the
  interface on which this packet was received.  Not used in xdping_kern.c
+ `rx_queue_index` - comment after definition says `rxq->queue_index`.
  Some kind of queue id.  Not used in xdping_kern.c

The function `icmp_check` is nearly the first thing done inside of
function `xdping_client`:
https://github.com/xdp-project/bpf-next/blob/master/tools/testing/selftests/bpf/progs/xdping_kern.c#L104

Function
[`icmp_check`](https://github.com/xdp-project/bpf-next/blob/master/tools/testing/selftests/bpf/progs/xdping_kern.c#L59-L87)
basically uses normal load/store with C pointers and pointer
arithmetic, to determine whether the packet is Ethernet + IPv4 + ICMP,
and if so, whether the `type` field in the ICMP header is equal to the
value of the `type` parameter of function `icmp_check`, which in this
case is `ICMP_ECHOREPLY`.  If the packet is anything else, function
`xdping_client` returns a value of `XDP_PASS` to function
`xdping_client`, which returns that value to XDP, causing the packet
to continue with regular Linux network packet processing without
modification.

If it is an ICMP echo reply packet, then function `xdping_client`
continues.

TBD: Finish description of function `xdping_client`.

TBD: It is not yet clear to me why this program changes ICMP echo
requests to echo replies, and vice versa, and what the overall packet
flow is.


## References

TBD: Article to summarize:

https://qmonnet.github.io/whirl-offload/2016/09/01/dive-into-bpf/

The book "BPF Performance Tools" is 880 pages of examples of Linux
performance and behavior monitoring tools created using EBPF, and only
a fraction of them are related to the networking part of the Linux
kernel.  Of those, I doubt any of them involve EBPF programs that
process packets.

The entire focus of the book is on using EBPF to hook into various
trace points and hooks in the Linux kernel, such that when events of
interest occur, the EBPF program(s) configured will execute, typically
modifying some EBPF maps in the process.  User space programs
typically read the contents of these maps and present statistical or
other kinds of summary results to the user.

"BPF Performance Tools", 1st Ed., Brendan Gregg, 2019, Addison-Wesley
Professional,
https://www.amazon.com/gp/product/0136554822?pf_rd_r=8HZM1ZFCW9GG1Y376295&pf_rd_p=9d9090dd-8b99-4ac3-b4a9-90a1db2ef53b
