#include <core.p4>
#include "very_simple_switch_model.p4"

//////////////////////////////////////////////////////////////////////
// Types, parser, and control definitions from a user's P4 program
// written for VSS
//////////////////////////////////////////////////////////////////////

// Types from the user's P4 program written for VSS, from the
// instantiation of the VSS package.

// H

// These are placeholder definitions to make p4test happy.  They
// should be replaced with the user program's definition of these
// types.
struct H {
}

// Parsers and controls from the user's P4 program written for VSS,
// for which the names below are used when calling them from this
// specification.  These are the names used when defining the
// parameter list of these objects within the
// very_simple_switch_model.p4 include file:

// Parser Pipe Deparser

// These are placeholder definitions to make p4test happy.  They
// should be replaced with the user program's definition of these
// parsers and controls.
parser parserImpl(
    packet_in b,
    out H parsedHeaders)
{
    state start { transition accept; }
}

control pipeImpl(
    inout H headers,
    in error parseError,
    in InControl inCtrl,
    out OutControl outCtrl)
{
    apply { }
}

control deparserImpl(
    inout H outputHeaders,
    packet_out b)
{
    apply { }
}


//////////////////////////////////////////////////////////////////////
// Extern functions that we rely upon to implement this specification,
// and that seem generally useful for many other P4 architecture
// specifications, too.
//////////////////////////////////////////////////////////////////////

typedef bit<20> PacketLength_t;

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
extern void get_new_packet(out packet pkt, out PortId port);

// transmit_packet sends a packet to a port of the device.  port must
// be in the set PortIdSet, and must not be equal to
// PSA_PORT_RECIRCULATE.
extern void transmit_packet(in packet pkt, in PortId port);

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

// Return the final error value reached by the last invocation of the
// parser, or error.NoError if no parsing error occurred.
extern error get_parser_error();

// Return the offset, in units of bits, of the first bit of the packet
// that the last invocation of the parser did not extract or advance
// past.
extern PacketLength_t get_parser_offset_bits();

//////////////////////////////////////////////////////////////////////
// New methods introduced for operating on values with type `list`
// used in this specification
//////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////
// Packet queues
//////////////////////////////////////////////////////////////////////

struct newq_packet_t {
    PortId inputPort;
    packet p;
}

Queue<newq_packet_t>() newq;

struct recircq_packet_t {
    PortId inputPort;
    packet p;
}

Queue<recircq_packet_t>() recircq;

struct demuxq_packet_t {
    PortId outputPort;
    packet p;
}

Queue<demuxq_packet_t>() demuxq;


#ifdef PROCESS_SUPPORTED
#define PROCESS process
#else
#define PROCESS control
#endif


// Process receive_new_packet takes in new packets from outside, when
// such a packet is available.  These can come either from one of the
// Ethernet pots numbered 0 through 7, or the CPU port.
PROCESS receive_new_packet
#ifdef PROCESS_SUPPORTED
    guard {
        new_packet_available();
    }
#else
    ()  // empty list of parameters to control as workaround
#endif
{
    packet p;
    apply {
        PortId inputPort;
        get_new_packet(p, inputPort);
        newq_packet_t newp = {
            inputPort = inputPort,
            p = p
        };
        // Note: Method maybe_enqueue() might _not_ append the packet
        // to the list newq.  If it does not, then effectively the
        // received packet p is dropped without ever being processed
        // by the device.  The description of VSS says explicitly that
        // this might occur if the Arbiter block is busy processing a
        // previous packet.
        newq.maybe_enqueue(newp);
    }
}

// pipe_processing is a control, written so that is useful to be
// called from several processes defined below.  It is _not_ a
// process.  In this kind of specification, the only way that any
// control or parser will ever be called is from a process, either
// directly, or indirectly via calls to intermediate controls or
// parsers.
control pipe_processing (
    in InControl inCtrl,
    in packet p)
{
    packet modp;
    apply {
        // Even though hdr is uninitialized here, because it is an
        // 'out' parameter to the parser, the parser will initialize
        // all headers to invalid, then copy-out those values back to
        // this code's value of hdr when the call to
        // parserImpl.apply() completes.
        H hdr;
        packet_in buffer = to_packet_in(p);
        parserImpl.apply(buffer, hdr);

        error parser_error = get_parser_error();
        PacketLength_t first_unparsed_bit_offset = get_parser_offset_bits();

        OutControl outCtrl;
        // The VSS specification makes outCtrl a direction 'out'
        // parameter of the Pipe control.  Thus there is no way for
        // the architecture to provide an initial default value.
        pipeImpl.apply(hdr, parser_error, inCtrl, outCtrl);

        packet_out buffer2;
        deparserImpl.apply(hdr, buffer2);

        // Take the packet data output by the deparser (in buffer2),
        // and append any portion of the packet that was not parsed by
        // the parser.
        from_packet_out(modp, buffer2);
        append_with_offset(modp, p, first_unparsed_bit_offset);

        // Like the PSA definition, the VSS definition is silent on
        // what happens if the modified packet is too short or too
        // long.

        // Refer to section 5.2.3 "Demux block" of the P4_16 language
        // specification for an English description of the behavior
        // below.
        if (outCtrl.outputPort == DROP_PORT) {
            // By not enqueueing the packet anywhere, nor calling
            // transmit_packet, the packet is dropped.
        } else if ((0 <= outCtrl.outputPort) && (outCtrl.outputPort <= 7)) {
            // Send modified packet modp to the specified Ethernet
            // output port
            demuxq_packet_t demux_pkt = {
                outputPort = outCtrl.outputPort,
                p = modp
            };
            demuxq.maybe_enqueue(demux_pkt);
        } else if (outCtrl.outputPort == CPU_OUT_PORT) {
            // Send original packet p (not modified packet modp) to
            // the CPU port.
            demuxq_packet_t demux_pkt = {
                outputPort = outCtrl.outputPort,
                p = p
            };
            demuxq.maybe_enqueue(demux_pkt);
        } else if (outCtrl.outputPort == RECIRCULATE_OUT_PORT) {
            recircq_packet_t recirc_pkt = {
                inputPort = RECIRCULATE_OUT_PORT,
                p = modp
            };
            recircq.maybe_enqueue(recirc_pkt);
        } else {
            // Illegal value of outCtrl.outputPort -- silently drop
            // the packet
        }
    }
}

// This process performs pipe processing on one new packet.
PROCESS pipe_processing_newq
#ifdef PROCESS_SUPPORTED
    guard {
        !newq.empty()
    }
#else
    ()  // empty list of parameters to control as workaround
#endif
{
    apply {
        newq_packet_t newp = newq.dequeue();
        InControl inCtrl = {inputPort = newp.inputPort};
        pipe_processing.apply(inCtrl, newp.p);
    }
}

// This process performs pipe processing on one recirculated packet.
PROCESS pipe_processing_recircq
#ifdef PROCESS_SUPPORTED
    guard {
        !recircq.empty()
    }
#else
    ()  // empty list of parameters to control as workaround
#endif
{
    apply {
        recircq_packet_t recircp = recircq.dequeue();
        InControl inCtrl = {inputPort = recircp.inputPort};
        pipe_processing.apply(inCtrl, recircp.p);
    }
}

// This process transmits packets to Ethernet ports 0 through 7, and
// the CPU port.
PROCESS transmit_packets
#ifdef PROCESS_SUPPORTED
    guard {
        !demuxq.empty()
    }
#else
    ()  // empty list of parameters to control as workaround
#endif
{
    apply {
        demuxq_packet_t demuxp = demuxq.dequeue();
        transmit_packet(demuxp.p, demuxp.outputPort);
    }
}
