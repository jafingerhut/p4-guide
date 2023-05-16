//////////////////////////////////////////////////////////////////////
// Extern functions that we rely upon to write multiple
// specifications, and that seem generally useful for many other P4
// architecture specifications, too.
//////////////////////////////////////////////////////////////////////

#ifdef P4C_SUPPORTS_LONGER_BIT_VECTORS
const bit<20> MAX_PACKET_LENGTH_BITS = 8 * (9 * 1024);
#else
const bit<20> MAX_PACKET_LENGTH_BITS = 8 * 256;
#endif

struct packet {
    bit<(MAX_PACKET_LENGTH_BITS)> data;
    bit<20> len_bits;
}

// get_new_packet should only be called when new_packet_available()
// returns true.  It modifies this instance of packet so that it holds
// the contents of the new packet, and return the port on which it
// arrived as an 'out' parameter.
extern void get_new_packet<PORTIDTYPE>(out packet pkt, out PORTIDTYPE port);

// transmit_packet sends a packet to a port of the device.  port must
// be in the set PortIdSet, and must not be equal to
// PSA_PORT_RECIRCULATE.
extern void transmit_packet<PORTIDTYPE>(in packet pkt, in PORTIDTYPE port);

// Return a packet_in object that has the same packet contents as
// source_pkt.
extern packet_in to_packet_in(in packet source_pkt);

// Replace any contents of dest_pkt with the contents of the
// packet_out object source_pkt
extern void from_packet_out(out packet dest_pkt, packet_out source_pkt);

// Append to dest_pkt the contents of another packet source_pkt,
// starting at the specified bit offset within source_pkt (0 for the
// beginning of source_pkt, 32 if you want to skip the first 32 bits
// of source_pkt and append only the data of source_pkt after the
// first 32 bits).
extern void append_with_offset(inout packet dest_pkt, in packet source_pkt, in PacketLength_t offset);

// Return the length of p, in bits
extern PacketLength_t length_bits(in packet p);

// Remove any part of pkt at the end such that the resulting packet is
// at most packet_length_bytes bytes long.
extern void truncate_to_length_bytes(inout packet pkt, in PacketLength_t packet_length_bytes);

// new_packet_available() returns true when there is a packet ready to
// be received from a port.  This includes any port in PortIdSet,
// including PSA_PORT_CPU, but not PSA_PORT_RECIRCULATE.
extern bool new_packet_available();

// time_now() is an extern function supplied by the PSA
// implementation.
extern Timestamp_t time_now();

// Return the final error value reached by the last invocation of the
// a parser, or error.NoError if no parsing error occurred.
// TODO: In a specification where we want to explicitly support
// parallelism, we should instead have a way to associate the parser
// error with a specific invocation of a parser, and have the parser
// output that.  One way would be to have the parser error be a field
// of the extern type packet_in.
extern error get_parser_error();

// Return the offset, in units of bits, of the first bit of the packet
// that the last invocation of a parserdid not extract or advance
// past.
// TODO: Same as for get_parser_error().
extern PacketLength_t get_parser_offset_bits();


// My intent is that Queue represents a FIFO (first-in, first-out)
// queue of elements of type T.  Some people who buy network devices
// _really_ care about packets in a single application flow leaving
// the device in the same relative order that they arrived to the
// device, at least in the common case when no table updates are being
// performed (and often they want this behavior even when most kinds
// of table updates are performed).  The performance of several
// reliable transport protocols such as some versions of TCP, and some
// versions of Infiniband RDMA, are heavily reliant upon this (they do
// not behave incorrectly if packets are reordered, but they can have
// much lower average throughput the more that packets are reordered).

// If someone wants to make a variant of these specifications where
// they explicitly want to allow behaviors where one or more of these
// "queues" can arbitrarily reorder values within them, I would
// recommend creating a different extern name for such things,
// e.g. perhaps named something like UnorderedQueue.

// Another possible set of parameters one might want for a
// specification like this is the maximum number of elements that a
// queue is allowed to contain.
extern Queue<T> {
    Queue();

    // Return true if the queue is empty, otherwise false.
    bool empty();

    // Return the first element of the queue, and modify the queue so
    // it no longer contains this element.
    T dequeue();

    // Nondeterministically choose to either (a) do nothing, or (b)
    // modify the queue so it contains all elements it did before,
    // plus the value e appended at the end.  The value of `e` is
    // handled by P4_16 copy-in behavior, meaning that if e is a left
    // value, the caller can modify e's value after maybe_enqueue()
    // returns, and be guaranteed that such modifications will never
    // change the value appended to the queue.
    void maybe_enqueue(in T e);
}
