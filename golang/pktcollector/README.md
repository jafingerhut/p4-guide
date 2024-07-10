# Introduction

The program `pktcollector` can get packets from reading a pcap file,
or from sniffing packets on a live network interface (with appropriate
privileges, as required by the operating system and network
interface).

For each one, it stores it in a ring buffer.  This is an example --
certainly more complex processing of each packet could be performed,
but this is a straightforward thing to understand, write, and test, as
an example.

It also listens for incoming TCP connections that can accept commands
from the client process, e.g. to read-and-clear the current ring
buffer.


# Future work

This is my first serious attempt at writing a small but useful program
in the Go programming language, so it may violate some things that are
considered good or safe practices for writing production-quality Go
programs.

Examples of things that could stand more investigation, and perhaps
lead to modifications to the program:

+ The `go feedDelayedChannel()` call in package `pktsource` can, I
  believe, leak that goroutine, if the code reading from the channel
  stops doing so before packets have all been read.  See section
  "Always Clean Up Your Goroutines" in Chapter 12 "Concurrency in Go"
  in the book "Learning Go" by Jon Bodner.
+ The use of a `Mutex` in package `pktwatcher` could be replaced with
  using a separate channel to send commands to the goroutine executing
  function `capturePackets`, and having a `select` statement inside of
  `capturePackets` to choose between processing the next packet, or a
  command.  In this case, the mutex use is limited to exactly two
  functions in a single package, so it is fairly well contained and
  understandable, but it does seem nice to avoid its use completely.
