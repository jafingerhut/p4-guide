#include <core.p4>
#include "very_simple_switch_model.p4"
typedef bit<20> PacketLength_t;
typedef bit<32> Timestamp_t;
#include "spec-defns.p4"

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
