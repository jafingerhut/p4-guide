#include <core.p4>
#include <psa.p4>
#include "ExactMap.p4"

//////////////////////////////////////////////////////////////////////
// Parameter values that must be chosen as part of creating a
// particular instantiation of this specification:
//////////////////////////////////////////////////////////////////////

// Bit widths for these types:

// PortId_t
// MulticastGroup_t
// CloneSessionId_t
// ClassOfService_t
// PacketLength_t
// EgressInstance_t
// Timestamp_t

// Sets of valid values for several types:

// PortIdSet
// PSA_PORT_CPU - not currently used in this specification
// PSA_PORT_RECIRCULATE
// MulticastGroupIdSet - not currently used in this specification
// CloneSessionIdSet
// PSA_CLONE_SESSION_TO_CPU - not currently used in this specification
// ClassOfServiceIdSet
// MinPacketLengthBytes
// MaxPacketLengthBytes
// EgressInstanceSet - not currently used in this specification

extern Set<T> {
    Set();

    // Return true if x is an element of the set, otherwise false
    bool member(in T x);
}

Set<PortId_t>() PortIdSet;
Set<CloneSessionId_t>() CloneSessionIdSet;
Set<ClassOfService_t>() ClassOfServiceIdSet;

const int NUM_MULTICAST_GROUPS = 1024;
const int NUM_CLONE_SESSIONS = 1024;
const PacketLength_t MinPacketLengthBytes = (PacketLength_t) 64;
const PacketLength_t MaxPacketLengthBytes = (PacketLength_t) (9 * 1024);

// Just a tiny utility function to keep the casts in one place
PacketLengthUint_t bytes_to_bits(PacketLength_t length_bytes) {
    return (8 * (PacketLengthUint_t) length_bytes);
}

//////////////////////////////////////////////////////////////////////
// Definitions from the psa.p4 include file
//////////////////////////////////////////////////////////////////////

// Assume that anything defined within the psa.p4 include file can be
// used in this specification, e.g. at least these definitions are
// used:

// enum PSA_PacketPath_t
// struct psa_ingress_parser_input_metadata_t
// struct psa_ingress_input_metadata_t
// struct psa_ingress_output_metadata_t
// struct psa_egress_parser_input_metadata_t
// struct psa_egress_input_metadata_t
// struct psa_egress_output_metadata_t
// struct psa_egress_deparser_input_metadata_t

//////////////////////////////////////////////////////////////////////
// Types, parser, and control definitions from a user's P4 program
// written for PSA
//////////////////////////////////////////////////////////////////////

// Types from the user's P4 program written for PSA, from the
// instantiation of the PSA_Switch package.

// IH IM EH EM NM CI2EM CE2EM RESUBM RECIRCM

// These are placeholder definitions to make p4test happy.  They
// should be replaced with the user program's definition of these
// types.
struct IH {
}
struct IM {
}
struct EH {
}
struct EM {
}
struct NM {
}
struct CI2EM {
}
struct CE2EM {
}
struct RESUBM {
}
struct RECIRCM {
}

// Parsers and controls from the user's P4 program written for PSA,
// for which the names below are used when calling them from this
// specification.  These are the names used when defining the
// parameter list of these objects within the psa.p4 include file:

// IngressParser Ingress IngressDeparser
// EgressParser  Egress  EgressDeparser

// These are placeholder definitions to make p4test happy.  They
// should be replaced with the user program's definition of these
// parsers and controls.
parser ingressParserImpl(
    packet_in pkt,
    out IH hdr,
    inout IM meta,
    in psa_ingress_parser_input_metadata_t istd,
    in RESUBM resubmit_meta,
    in RECIRCM recirculate_meta)
{
    state start { transition accept; }
}

control ingressImpl(
    inout IH hdr,
    inout IM meta,
    in    psa_ingress_input_metadata_t  istd,
    inout psa_ingress_output_metadata_t ostd)
{
    apply { }
}

control ingressDeparserImpl(
    packet_out pkt,
    out CI2EM clone_i2e_meta,
    out RESUBM resubmit_meta,
    out NM normal_meta,
    inout IH hdr,
    in IM meta,
    in psa_ingress_output_metadata_t istd)
{
    apply { }
}

parser egressParserImpl(
    packet_in pkt,
    out EH hdr,
    inout EM meta,
    in psa_egress_parser_input_metadata_t istd,
    in NM normal_meta,
    in CI2EM clone_i2e_meta,
    in CE2EM clone_e2e_meta)
{
    state start { transition accept; }
}

control egressImpl(
    inout EH hdr,
    inout EM meta,
    in    psa_egress_input_metadata_t  istd,
    inout psa_egress_output_metadata_t ostd)
{
    apply { }
}

control egressDeparserImpl(
    packet_out pkt,
    out CE2EM clone_e2e_meta,
    out RECIRCM recirculate_meta,
    inout EH hdr,
    in EM meta,
    in psa_egress_output_metadata_t istd,
    in psa_egress_deparser_input_metadata_t edstd)
{
    apply { }
}


//////////////////////////////////////////////////////////////////////
// Extern functions that we rely upon to implement this specification,
// and that seem generally useful for many other P4 architecture
// specifications, too.
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
extern void get_new_packet(out packet pkt, out PortId_t port);

// transmit_packet sends a packet to a port of the device.  port must
// be in the set PortIdSet, and must not be equal to
// PSA_PORT_RECIRCULATE.
extern void transmit_packet(in packet pkt, in PortId_t port);

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

bool supported_packet_length(in packet p) {
    if (((PacketLengthUint_t) length_bits(p) < bytes_to_bits(MinPacketLengthBytes)) ||
        ((PacketLengthUint_t) length_bits(p) > bytes_to_bits(MaxPacketLengthBytes)))
    {
        return false;
    } else {
        return true;
    }
}

// new_packet_available() returns true when there is a packet ready to
// be received from a port.  This includes any port in PortIdSet,
// including PSA_PORT_CPU, but not PSA_PORT_RECIRCULATE.
extern bool new_packet_available();

// time_now() is an extern function supplied by the PSA
// implementation.
extern Timestamp_t time_now();

// Return the final error value reached by the last invocation of
// IngressParser or EgressParser, or error.NoError if no parsing error
// occurred.
extern error get_parser_error();

// Return the offset, in units of bits, of the first bit of the packet
// that the last invocation of IngressParser or EgressParser did not
// extract or advance past.
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

    // Return the first element of the list, and modify the list so it
    // no longer contains this element.  T is the type of element
    // contained in the list.
    T dequeue();

    // Nondeterministically choose to either (a) do nothing, or (b)
    // modify the list so it contains all elements it did before, plus
    // the value e appended at the end.  The value of `e` is handled
    // by P4_16 copy-in behavior, meaning that if e is a left value,
    // the caller can modify e's value after maybe_enqueue() returns,
    // and be guaranteed that such modifications will never change the
    // value appended to the list.
    void maybe_enqueue(in T e);
}

//////////////////////////////////////////////////////////////////////
// Configuration state for the traffic manager (aka packet buffer)
//////////////////////////////////////////////////////////////////////

// Configuration state for multicast packet replication lists,
// modifiable only via control plane API.
struct replication_list_entry_t {
    PortId_t         egress_port;
    EgressInstance_t instance;
}

// Note that there is an assumption here that the control plane API
// for configuring multicast group replication lists checks that all
// port and instance values in the replication list are supported.

struct mcast_group_key_t {
    MulticastGroup_t mcast_group;
}

ExactMap<mcast_group_key_t, list<replication_list_entry_t>>(size=NUM_MULTICAST_GROUPS)
    mcast_group_replication_list;

// clone_session_entry is configuration state for clone sessions,
// modifiable only via control plane API.

// Note that there is an assumption here that the control plane API
// for configuring clone sessions only permits values of
// class_of_service in ClassOfServiceIdSet.  Similarly that all port
// and instance values in replication_list are supported, and
// packet_length_bytes is a value supported by the implementation.
struct clone_session_entry_t {
    ClassOfService_t class_of_service;
#ifdef LIST_SUPPORTED_INSIDE_STRUCT
    list<replication_list_entry_t> replication_list;
#endif
    bool truncate;
    PacketLength_t packet_length_bytes;
}

struct clone_session_id_key_t {
    CloneSessionId_t clone_session_id;
}

ExactMap<clone_session_id_key_t, clone_session_entry_t>(size=NUM_CLONE_SESSIONS)
    clone_session_entry;

//////////////////////////////////////////////////////////////////////
// Packet queues
//////////////////////////////////////////////////////////////////////

struct newq_packet_t {
    PortId_t ingress_port;
    packet p;
}

Queue<newq_packet_t>() newq;

struct resubq_packet_t {
    PortId_t ingress_port;
    // Type RESUBM is from the P4 program's instantiation of the
    // PSA_Switch package
    RESUBM user_resubm;
    packet p;
}

Queue<resubq_packet_t>() resubq;

struct recircq_packet_t {
    // To implement PSA as written, the ingress_port will _always_ be
    // PSA_PORT_RECIRCULATE.  The main reason for having this
    // ingress_port field here is that it makes it easy to generalize
    // PSA somewhat by having _multiple_ recirculation ports, not
    // merely one.
    PortId_t ingress_port;
    // Type RECIRCM is from the P4 program's instantiation of the
    // PSA_Switch package
    RECIRCM user_recircm;
    packet p;
}

Queue<recircq_packet_t>() recircq;

struct tmq_packet_t {
    // egress_port can be inferred from which tmq the packet is in,
    // and thus need not have a separate field to record it.
    // Similarly for class_of_service.

    // For packets in a tmq, packet_path must be one of these values:
    // NORMAL_UNICAST, NORMAL_MULTICAST, CLONE_I2E, CLONE_E2E
    PSA_PacketPath_t packet_path;

    // instance is always 0 for NORMAL_UNICAST packets.
    EgressInstance_t instance;

    // Note: Exactly one of user_nm, user_ci2em, and user_ce2em below
    // is used for any particular packet.  Which one depends upon the
    // value of packet_path.  We could explicitly define this as a
    // union, if a syntax and semantics are defined for unions.

    // The types NM, CI2EM, and CE2EM are from the P4 program's
    // instantiation of the PSA_Switch package.
    NM user_nm;
    CI2EM user_ci2em;
    CE2EM user_ce2em;

    packet p;
}

// TODO: What is a good syntax to declare something like a
// two-dimensional array of queues (or nested dictionary, in Python's
// sense of the term dictionary)?

// We could make tmq an instance of the ExactMap extern with port and
// class_of_service as keys, but that has the implication that the
// keys and values can be configured via a control plane API, which
// for tmq it likely would not be.

// The intent is that for each pair (x, y) where x is in PortIdSet,
// and y is in ClassOfServiceIdSet, there is a separate list object
// tmq[x][y]

#ifdef ARRAY_OF_QUEUES_SUPPORTED
Queue<tmq_packet_t>() tmq[PortIdSet][ClassOfServiceIdSet];
#else
// As a workaround, put all packets into a single tmq.  This
// significantly restricts the possible orders that packets can be
// processed in a PSA device, though.
Queue<tmq_packet_t>() tmq;
#endif


#ifdef PROCESS_SUPPORTED
#define PROCESS process
#else
#define PROCESS control
#endif


// Process receive_new_packet takes in new packets from outside, when
// such a packet is available.  These can come either from a front
// panel port, or the CPU port.
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
        PortId_t input_port;
        get_new_packet(p, input_port);
        newq_packet_t newp = {
            ingress_port = input_port,
            p = p
        };
        // Note: Method maybe_enqueue() might _not_ append the packet
        // to the list newq.  If it does not, then effectively the
        // received packet p is dropped without ever being processed
        // by the device.
        //
        // Pretty much every real network device has this possible
        // behavior, but implementations often differ on exactly what
        // conditions they use to determine whether to drop or keep
        // the packet.  This specification does not attempt to
        // enumerate such cases, but simply make it a possible
        // behavior.
        //
        // If someone wants to avoid this dropping behavior, they use
        // flow control and/or congestion control mechanisms to
        // prevent the sender from sending packets when the receiver
        // does not have a place to store the received packet,
        // e.g. Ethernet pause frames.
        // https://en.wikipedia.org/wiki/Ethernet_flow_control
        newq.maybe_enqueue(newp);
    }
}

// replicate_packet is a control, not a process.  It is only called
// when invoked explicitly from a process (perhaps indirectly via one
// or more other controls in the call stack).  It is common code used
// for multicast packet replication and packet clone operations, which
// in PSA can make multiple clones of a packet.
control replicate_packet (
    in packet p,
    in PSA_PacketPath_t packet_path,
    in ClassOfService_t class_of_service,
    in list<replication_list_entry_t> replication_list,
    in NM user_nm,
    in CI2EM user_ci2em,
    in CE2EM user_ce2em)
{
    replication_list_entry_t e;
    tmq_packet_t tm_pkt;
    apply {
        tm_pkt = {
            packet_path = packet_path,
            instance = (EgressInstance_t) 0,  // this value is overwritten below
            user_nm = user_nm,
            user_ci2em = user_ci2em,
            user_ce2em = user_ce2em,
            p = p
        };
        // See discussion of capability C12 in
        // specifying-p4-architectures/README.md describing some
        // options for guaranteeing finiteness of this loop.
#ifdef FOR_LOOP_SUPPORTED
        for (e in replication_list) {
            tm_pkt.instance = e.instance;
            tmq[e.egress_port][class_of_service].maybe_enqueue(tm_pkt);
        }
#endif
    }
}

// ingress_processing is a control, written so that is useful to be
// called from several processes defined below.  It is _not_ a
// process.  In this kind of specification, the only way that any
// control or parser will ever be called is from a process, either
// directly, or indirectly via calls to intermediate controls or
// parsers.
control ingress_processing (
    in psa_ingress_parser_input_metadata_t istd,
    in packet p,
    in RESUBM user_resubm,
    in RECIRCM user_recircm)
{
    packet modp;
    packet cloned_pkt;
    apply {
        // Even though hdr is uninitialized here, because it is an
        // 'out' parameter to the parser IngressParser, IngressParser
        // will initialize all headers to invalid, then copy-out those
        // values back to this code's value of hdr when the call to
        // IngressParser.apply() completes.
        IH hdr;
        IM user_meta;
        packet_in buffer = to_packet_in(p);
        Timestamp_t ingress_timestamp = time_now();
        ingressParserImpl.apply(buffer, hdr, user_meta, istd,
            user_resubm, user_recircm);

        error parser_error = get_parser_error();
        PacketLength_t first_unparsed_bit_offset = get_parser_offset_bits();
        psa_ingress_input_metadata_t istd2 = {
            ingress_port = istd.ingress_port,
            packet_path = istd.packet_path,
            ingress_timestamp = ingress_timestamp,
            parser_error = parser_error};

        psa_ingress_output_metadata_t ostd;
        // See Section 6.2 of PSA spec for initial values of some
        // fields of ostd that PSA promises are initialized.
        ostd.class_of_service = (ClassOfService_t) 0;
        ostd.clone = false;
        //ostd.clone_session_id; // initial value is undefined
        ostd.drop = true;
        ostd.resubmit = false;
        ostd.multicast_group = (MulticastGroup_t) 0;
        //ostd.egress_port;      // initial value is undefined
        ingressImpl.apply(hdr, user_meta, istd2, ostd);

        packet_out buffer2;
        CI2EM clone_i2e_meta;
        RESUBM resubmit_meta_out;
        NM normal_meta;
        ingressDeparserImpl.apply(buffer2, clone_i2e_meta, resubmit_meta_out,
            normal_meta, hdr, user_meta, ostd);

        // Take the packet data output by the deparser (in buffer2),
        // and append any portion of the packet that was not parsed by
        // the ingress parser.
        from_packet_out(modp, buffer2);
        append_with_offset(modp, p, first_unparsed_bit_offset);

        // Refer to section 6.2 "Behavior of packets after ingress
        // processing is complete" of PSA spec.  The code below is
        // _very_ similar to that.
        if (ostd.clone) {
            if (CloneSessionIdSet.member(ostd.clone_session_id)) {
                clone_session_entry_t e =
                    clone_session_entry.lookup({ostd.clone_session_id});
                cloned_pkt = modp;
                if (e.truncate) {
                    truncate_to_length_bytes(cloned_pkt, e.packet_length_bytes);
                }
                // TODO: If e.truncate is false, should probably make
                // a check to see if the packet has a supported length
                // here, and if not, skip the call to replicate_packet
                // below and increment an error count instead.
                NM garbage_nm;  // See Note 1
                CE2EM garbage_ce2em;
                replicate_packet.apply(cloned_pkt, PSA_PacketPath_t.CLONE_I2E,
                    e.class_of_service,
#ifdef LIST_SUPPORTED_INSIDE_STRUCT
                    e.replication_list,
#else
                    (list<replication_list_entry_t>) {},
#endif
                    garbage_nm, clone_i2e_meta, garbage_ce2em);
            } else {
                // Do not create any cloned packets.  TODO: Increment
                // an error counter that can be read by control plane
                // API.
            }
        }
        // Continue below, regardless of whether a clone was created.
        // Any clone created above is unaffected by the code below.
        if (ostd.drop) {
            // Rather than making an explicit call to drop the packet,
            // we drop the packet simply by _not_ storing the packet
            // in any queues.
            return;  // This is the standard P4_16 return statement
        }
        if (ClassOfServiceIdSet.member(ostd.class_of_service)) {
            ostd.class_of_service = (ClassOfService_t) 0;  // use default class 0 instead
            // Recommended to log error about unsupported
            // ostd.class_of_service value.
        }
        if (!supported_packet_length(modp)) {
            // TODO: Increment control-plane readable error count
            // specific to this reason for dropping the packet.
            return;
        }
        if (ostd.resubmit) {
            resubq_packet_t resubp = {
                ingress_port = istd.ingress_port,
                user_resubm = resubmit_meta_out,
                p = modp
            };
            resubq.maybe_enqueue(resubp);
            return;
        }
        if ((MulticastGroupUint_t) ostd.multicast_group != 0) {
            // Make 0 or more copies of the packet according to the
            // control plane configuration of multicast group
            // ostd.multicast_group.  Every copy will have the same
            // value of ostd.class_of_service
            CI2EM garbage_ci2em;  // See Note 1
            CE2EM garbage_ce2em;
            replicate_packet.apply(modp, PSA_PacketPath_t.NORMAL_MULTICAST,
                ostd.class_of_service,
                mcast_group_replication_list.lookup({ostd.multicast_group}),
                normal_meta, garbage_ci2em, garbage_ce2em);
            // TODO: Figure out what to do if ostd.multicast_group is
            // not in the set MulticastGroupIdSet.  One simple
            // approach is to define that for such values,
            // mcast_group_replication_list.lookup() always returns an
            // empty list.  It would be nice for debugging purposes if
            // there was a counter incremented when this situation
            // occurs.
            return;   // Do not continue below.
        }
        if (PortIdSet.member(ostd.egress_port)) {
            // Enqueue one packet for output port ostd.egress_port
            // with class of service ostd.class_of_service.
            CI2EM garbage_ci2em;  // See Note 1
            CE2EM garbage_ce2em;
            tmq_packet_t normalp = {
                packet_path = PSA_PacketPath_t.NORMAL_UNICAST,
                instance = (EgressInstance_t) 0,
                user_nm = normal_meta,
                user_ci2em = garbage_ci2em,
                user_ce2em = garbage_ce2em,
                p = modp
            };
#ifdef ARRAY_OF_QUEUES_SUPPORTED
            tmq[ostd.egress_port][ostd.class_of_service].maybe_enqueue(normalp);
#else
            tmq.maybe_enqueue(normalp);
#endif
        } else {
            // Drop the packet, by _not_ putting the packet into any
            // queues.  TODO: Recommended to log error about
            // unsupported ostd.egress_port value.
        }

    }
}

// This process performs ingress processing on one new packet.
PROCESS ingress_processing_newq
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
        psa_ingress_parser_input_metadata_t istd = {
            ingress_port = newp.ingress_port,
            packet_path = PSA_PacketPath_t.NORMAL};
        RESUBM garbage_resubm;  // See Note 1
        RECIRCM garbage_recircm;
        ingress_processing.apply(istd, newp.p,
            garbage_resubm, garbage_recircm);
    }
}

// This process performs ingress processing on one resubmitted packet.
PROCESS ingress_processing_resubq
#ifdef PROCESS_SUPPORTED
    guard {
        !resubq.empty()
    }
#else
    ()  // empty list of parameters to control as workaround
#endif
{
    apply {
        resubq_packet_t resubp = resubq.dequeue();
        psa_ingress_parser_input_metadata_t istd = {
            ingress_port = resubp.ingress_port,
            packet_path = PSA_PacketPath_t.RESUBMIT};
        RECIRCM garbage_recircm;
        ingress_processing.apply(istd, resubp.p,
            resubp.user_resubm, garbage_recircm);
    }
}

// This process performs ingress processing on one recirculated packet.
PROCESS ingress_processing_recircq
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
        psa_ingress_parser_input_metadata_t istd = {
            ingress_port = recircp.ingress_port,
            packet_path = PSA_PacketPath_t.RECIRCULATE};
        RESUBM garbage_resubm;
        ingress_processing.apply(istd,
            recircp.p,
            garbage_resubm, recircp.user_recircm);
    }
}

// This process performs egress processing on one packet currently in
// the traffic manager.
PROCESS egress_processing
#ifdef PROCESS_SUPPORTED
    guard {
        // TODO: Need some syntax to represent "at least one of the
        // tmq queues is non-empty"
    }
#else
    ()  // empty list of parameters to control as workaround
#endif
{
    packet modp;
    packet cloned_pkt;
    apply {
        // TODO: Need some way to get the values egress_port and
        // class_of_service of the non-empty tmq that we are going to
        // dequeue a packet from.
        PortId_t egress_port;  // TODO initialize this
        ClassOfService_t class_of_service;  // TODO initialize this

        tmq_packet_t pkt;
#ifdef ARRAY_OF_QUEUES_SUPPORTED
        pkt = tmq[egress_port][class_of_service].dequeue();
#else
        pkt = tmq.dequeue();
#endif

        psa_egress_parser_input_metadata_t istd = {
            egress_port = egress_port,
            packet_path = pkt.packet_path};

        EH hdr;
        EM user_meta;
        packet_in buffer = to_packet_in(pkt.p);
        Timestamp_t egress_timestamp = time_now();

        egressParserImpl.apply(buffer, hdr, user_meta, istd, pkt.user_nm,
            pkt.user_ci2em, pkt.user_ce2em);
        error parser_error = get_parser_error();
        PacketLength_t first_unparsed_bit_offset = get_parser_offset_bits();

        psa_egress_input_metadata_t istd2 = {
            class_of_service = class_of_service,
            egress_port = egress_port,
            packet_path = pkt.packet_path,
            instance = pkt.instance,
            egress_timestamp = egress_timestamp,
            parser_error = parser_error};

        psa_egress_output_metadata_t ostd;
        // See Section 6.5 of PSA spec for initial values of some
        // fields of ostd that PSA promises are initialized.
        ostd.clone = false;
        // ostd.clone_session_id; // initial value is undefined
        ostd.drop = false;
        egressImpl.apply(hdr, user_meta, istd2, ostd);

        packet_out buffer2;
        CE2EM clone_e2e_meta;
        RECIRCM recirculate_meta;
        psa_egress_deparser_input_metadata_t edstd = {
            egress_port = egress_port};
        egressDeparserImpl.apply(buffer2, clone_e2e_meta, recirculate_meta,
            hdr, user_meta, istd2, edstd);

        // Take the packet data output by the deparser (in buffer2),
        // and append any portion of the packet that was not parsed by
        // the egress parser.
        from_packet_out(modp, buffer2);
        append_with_offset(modp, pkt.p, first_unparsed_bit_offset);

        // Refer to section 6.5 "Behavior of packets after egress
        // processing is complete" of PSA spec.  The code below is
        // _very_ similar to that.
        if (ostd.clone) {
            if (CloneSessionIdSet.member(ostd.clone_session_id)) {
                clone_session_entry_t e =
                    clone_session_entry.lookup({ostd.clone_session_id});
                cloned_pkt = modp;
                if (e.truncate) {
                    truncate_to_length_bytes(cloned_pkt, e.packet_length_bytes);
                }
                // TODO: If e.truncate is false, should probably make
                // a check to see if the packet has a supported length
                // here, and if not, skip the call to replicate_packet
                // below and increment an error count instead.
                NM garbage_nm;  // See Note 1
                CI2EM garbage_ci2em;
                replicate_packet.apply(cloned_pkt, PSA_PacketPath_t.CLONE_E2E,
                    e.class_of_service,
#ifdef LIST_SUPPORTED_INSIDE_STRUCT
                    e.replication_list,
#else
                    (list<replication_list_entry_t>) {},
#endif
                    garbage_nm, garbage_ci2em, clone_e2e_meta);
            } else {
                // Do not create a clone.  TODO: Recommended to log
                // error about unsupported ostd.clone_session_id
                // value.
            }
        }

        // Continue below, regardless of whether a clone was created.
        // Any clone created above is unaffected by the code below.
        if (ostd.drop) {
            // Drop the packet by _not_ enqueueing it anywhere.
            return;   // Do not continue below.
        }
        if (!supported_packet_length(modp)) {
            // TODO: Increment control-plane readable error count
            // specific to this reason for dropping the packet.
            return;
        }
        if (istd.egress_port == PSA_PORT_RECIRCULATE) {
            recircq_packet_t recircp = {
                ingress_port = istd.egress_port,
                user_recircm = recirculate_meta,
                p = modp
            };
            recircq.maybe_enqueue(recircp);
            return;
        }
        // send one packet modp to output port istd.egress_port
        // Note: In this version of specification, if it is an
        // Ethernet port, the implementation of transmit_packet is
        // responsible for calculating and appending Ethernet FCS at
        // the end.
        transmit_packet(modp, istd.egress_port);
    }
}

// TODO: If you want to model the behavior of P4Runtime API PacketIn
// and PacketOut messages, then the CPU port numbered PSA_PORT_CPU
// packets should have additional special case code for handling them
// that is not written yet.

// Note 1:

// The variables with names beginning with `garbage` are explicitly
// uninitialized.  Thus this specification allows _any_ possible
// values for these variables.  A correct PSA program will never use
// these values in a way that affects the packet processing behavior.
// By making these values uninitialized in this specification, formal
// analysis tools can explicitly represent this fact, and possibly
// find bugs in P4 programs that use these values incorrectly.
