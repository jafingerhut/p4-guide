
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
extern int get_parser_offset_bits();

// Send a packet to a port of the device.  port must be in the set
// PortIdSet, and must not be equal to PSA_PORT_RECIRCULATE.
extern void transmit_packet(packet p, PortId_t port);

// Represents a sequence of bits with a packet's contents
extern packet {
    packet();  // constructor

    // Return a packet_in object that has the same packet contents as
    // this packet.
    packet_in to_packet_in();

    // Replace any contents of this packet with the contents of the
    // packet in p
    void from_packet_out(packet_out p);

    // Append to this packet the contents of another packet p,
    // starting at the specified bit offset within p (0 for the
    // beginning of p, 32 if you want to skip the first 32 bits of p
    // and append only the data of p after the first 32 bits).
    void append_with_offset(packet p, in int offset);

    // Return the length of the 
    int length_bits();
}

struct newq_packet_t {
    PortId_t ingress_port;
    packet p;
}

list<newq_packet_t> newq;

struct resubq_packet_t {
    PortId_t ingress_port;
    RESUBM user_resubm;   // RESUBM is the type from the P4 program's instantiation of the PSA_Switch package
    packet p;
}

list<resubq_packet_t> resubq;

struct recircq_packet_t {
    // To implement PSA as written, the ingress_port will _always_ be
    // PSA_PORT_RECIRCULATE.  The main reason for having this
    // ingress_port field here is that it makes it easy to generalize
    // PSA somewhat by having _multiple_ recirculation ports, not
    // merely one.
    PortId_t ingress_port;
    RECIRCM user_recircm;   // RECIRCM is the type from the P4 program's instantiation of the PSA_Switch package
    packet p;
}

list<recircq_packet_t> recircq;

struct tmq_packet_t {
    // egress_port can be inferred from which tmq the packet is in,
    // and thus need not have a separate field to record it.
    // Similarly for class_of_service.

    // For packets in a tmq, packet_path must be one of these values:
    // NORMAL_UNICAST, NORMAL_MULTICAST, CLONE_I2E, CLONE_E2E
    PSA_PacketPath_t packet_path;

    // instance is always 0 for NORMAL_UNICAST packets.
    EgressInstance_t instance;

    // Note that at most one of user_nm, user_ci2em, and user_ce2em
    // below is initialized for any particular packet.  Which one
    // depends upon the value of packet_path.  We could explicitly
    // define this as a union if one wished to do so, and if a syntax
    // and semantics are defined for unions.

    // NM, CI2EM, and CE2EM are the types from the P4 program's
    // instantiation of the PSA_Switch package.
    NM user_nm;
    CI2EM user_ci2em;
    CE2EM user_ce2em;

    packet p;
}

// TODO: What is a good syntax to declare something like a
// two-dimensional array/dictionary of queues?

// The intent is that for each pair (x, y) where x is in PortIdSet,
// and y is in ClassOfServiceIdSet, there is a separate object
// tmq[x][y]

list<tmq_packet_t> tmq[PortIdSet][ClassOfServiceIdSet];

//////////////////////////////////////////////////////////////////////
// New methods introduced for operating on values with type list in
// this code:
//
// bool empty() - return true if the list contains 0 elements,
// otherwise false.
//
// T dequeue() - return the first element of the list, and modify the
// list so it no longer contains this element.  T is the type of
// element contained in the list.
//
// void maybe_enqueue(T e) - nondeterministically choose to either (a)
// do nothing, or (b) modify the list so it contains all elements it
// did before, plus the value e at the end.
//
// Another possible set of parameters one might want for a
// specification like this is the maximum number of elements that a
// queue is allowed to contain.
//////////////////////////////////////////////////////////////////////


// This process takes in new packets from outside, either from a front
// panel port or the CPU port, when such a packet is available.
process receive_new_packet {
    guard {
        // TODO: I do not know a good way to write this, but basically
        // "whenever the environment has a new packet ready to send to
        // this device".
        true
    }
    apply {
        // TODO: Need some way to get these values describing the new
        // received packet: p (with type packet) and input_port, which
        // can be any port in PortIdSet except PSA_PORT_RECIRCULATE.
        packet p = TODO;
        PortId_t input_port = TODO;
        newq_packet_t newp = {ingress_port = input_port, packet = p};
        // Method maybe_enqueue() might _not_ append the packet,
        // causing the packet to be dropped, for
        // implementation-specific reasons that are difficult to
        // predict.  From the point of view of the specification, this
        // is like a nondeterministic choice to drop or keep the
        // packet.  The parameter value is passed by copy-in, so the
        // caller is free to modify newp after maybe_enqueue()
        // returns, and this will never affect the earlier enqueued
        // packet+metadata contents.
        newq.maybe_enqueue(newp);
    }
}

// This is a control that can be invoked from several processes.  It
// is _not_ a process.
control ingress_processing (
    psa_ingress_parser_input_metadata_t istd,
    packet p,
    RESUBM user_resubm,
    RECIRCM user_recircm)
{
    apply {
        // Even though hdr is uninitialized here, because it is an
        // 'out' parameter to the parser IngressParser, IngressParser
        // will initialize all headers to invalid, then copy-out those
        // values back to this code's value of hdr when the call to
        // IngressParser.apply() completes.
        IH hdr;
        IM user_meta;
        packet_in buffer = p.to_packet_in();
        Timestamp_t ingress_timestamp = time_now();
        IngressParser.apply(buffer, hdr, user_meta, istd,
            user_resubm, user_recircm);

        error parser_error = get_parser_error();
        int first_unparsed_bit_offset = get_parser_offset_bits();
        psa_ingress_input_metadata_t istd2 = {
            ingress_port = istd.ingress_port,
            packet_path = istd.packet_path,
            ingress_timestamp = ingress_timestamp,
            parser_error = parser_error};

        psa_ingress_output_metadata_t ostd;
        // See Section 6.2 of PSA spec for initial values of some
        // fields of ostd that P4 developers writing Ingress code can
        // assume have been initialized.
        ostd.class_of_service = 0;
        ostd.clone = false;
        //ostd.clone_session_id; // initial value is undefined
        ostd.drop = true;
        ostd.resubmit = false;
        ostd.multicast_group = 0;
        //ostd.egress_port;      // initial value is undefined
        Ingress.apply(hdr, user_meta, istd2, ostd);

        packet_out buffer2;
        CI2EM clone_i2e_meta;
        RESUBM resubmit_meta;
        NM normal_meta;
        IngressDeparser.apply(buffer2, clone_i2e_meta, resubmit_meta,
            normal_meta, hdr, user_meta, ostd);

        // Take the packet data output by the deparser (in buffer2),
        // and append any portion of the packet that was not parsed by
        // the ingress parser.
        packet() modp;
        modp.from_packet_out(buffer2);
        modp.append_with_offset(p, first_unparsed_bit_offset);

        // Refer to section 6.2 "Behavior of packets after ingress
        // processing is complete" of PSA spec.  The code below is
        // _very_ similar to that.
        if (ostd.clone) {
            // TODO: Make the sets like CloneSessionIdSet an extern
            // object that has a method called 'member' returning a
            // boolean.
            if (CloneSessionIdSet.member(ostd.clone_session_id)) {
                // TODO: implement clone behavior.  Since this can
                // perform multicast replication on packets, which is
                // very similar to normal multicast, it would be nice
                // to have a sub-control that implements multicast
                // replication in a way that can be used both here and
                // also below.
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

        //////////////////////////////////////////////////////////////////////
        if (ClassOfServiceIdSet.member(ostd.class_of_service)) {
            ostd.class_of_service = 0;    // use default class 0 instead
            // Recommended to log error about unsupported
            // ostd.class_of_service value.
        }

        // TODO: Check whether the resulting packet is in the range of
        // lengths supported by the implementation, and drop it if its
        // length is outside of that range.

        // Note: Some implementations might support a different range
        // of packet lengths as stored in the traffic manager queues,
        // than they do when sent and received on ports connected to
        // other devices.  This is useful for supporting internal
        // headers added to maximum-length packets while the packet is
        // on its way from ingress to egress, but egress always
        // removes those internal-only headers.  If you want to write
        // a specification that includes that feature, a
        // straightforward way is to define another parameter that is
        // a different maximum packet length supported internally.

        if (ostd.resubmit) {
            resubq_packet_t resubp = {
                ingress_port = istd.ingress_port,
                user_resubm = resubmit_meta,
                p = modp};
            resubq.maybe_enqueue(resubp);
            return;
        }
        if (ostd.multicast_group != 0) {
            // Make 0 or more copies of the packet according to the
            // control plane configuration of multicast group
            // ostd.multicast_group.  Every copy will have the same
            // value of ostd.class_of_service
            TODO: implement this
            return;   // Do not continue below.
        }
        if (PortIdSet.member(ostd.egress_port)) {
            // enqueue one packet for output port ostd.egress_port
            // with class of service ostd.class_of_service
            // Note: The values that are given as ... should never be
            // used later, so the particular value does not matter.
            tmq_packet_t normalp = {
                packet_path = PSA_PacketPath_t.NORMAL_UNICAST,
                instance = 0,
                user_nm = normal_meta,
                user_ci2em = (CI2EM) ...,
                user_ce2em = (CE2EM) ...,
                packet = modp};
            tmq[ostd.egress_port][ostd.class_of_service].maybe_enqueue(normalp);
        } else {
            // Drop the packet, by _not_ putting the packet into any
            // queues.  TODO: Recommended to log error about
            // unsupported ostd.egress_port value.
        }

    }
}

// This process performs ingress processing on one new packet.
process ingress_processing_newq {
    guard {
        !newq.empty()
    }
    apply {
        newq_packet_t newp = newq.dequeue();
        psa_ingress_parser_input_metadata_t istd = {
            ingress_port = newp.ingress_port,
            packet_path = PSA_PacketPath_t.NORMAL};
        ingress_processing.apply(istd, newp.p, (RESUBM) ...,
            (RECIRCM) ...);
    }
}

// This process performs ingress processing on one resubmitted packet.
process ingress_processing_resubq {
    guard {
        !resubq.empty()
    }
    apply {
        resubq_packet_t resubp = resubq.dequeue();
        psa_ingress_parser_input_metadata_t istd = {
            ingress_port = resubp.ingress_port,
            packet_path = PSA_PacketPath_t.RESUBMIT};
        ingress_processing.apply(istd, resubp.p, resubp.user_resubm,
            (RECIRCM) ...);
    }
}

// This process performs ingress processing on one recirculated packet.
process ingress_processing_recircq {
    guard {
        !recircq.empty()
    }
    apply {
        resubq_packet_t recircp = recircq.dequeue();
        psa_ingress_parser_input_metadata_t istd = {
            ingress_port = recircp.ingress_port,
            packet_path = PSA_PacketPath_t.RECIRCULATE};
        ingress_processing.apply(istd, recircp.p, (RESUBM) ...,
            recircp.user_recircm);
    }
}

// This process performs egress processing on one packet currently in
// the traffic manager.
process egress_processing {
    guard {
        // TODO: Need some syntax to represent "at least one of the
        // tmq queues is non-empty"
    }
    apply {
        // TODO: Need some way to get the values egress_port and
        // class_of_service of the non-empty tmq that we are going to
        // dequeue a packet from.
        PortId_t egress_port = TODO;
        ClassOfService_t class_of_service = TODO;
        
        tmq_packet_t pkt = tmq[egress_port][class_of_service].dequeue();

        psa_egress_parser_input_metadata_t istd = {
            egress_port = egress_port,
            packet_path = pkt.packet_path};

        IH hdr;
        IM user_meta;
        packet_in buffer = pkt.to_packet_in();
        Timestamp_t egress_timestamp = time_now();

        EgressParser.apply(buffer, hdr, user_meta, istd, pkt.user_nm,
            pkt.user_ci2em, pkt.user_ce2em);
        error parser_error = get_parser_error();
        int first_unparsed_bit_offset = get_parser_offset_bits();

        psa_egress_input_metadata_t istd2 = {
            class_of_service = class_of_service,
            egress_port = egress_port,
            packet_path = pkt.packet_path,
            instance = pkt.instance,
            egress_timestamp = egress_timestamp,
            parser_error = parser_error};

        psa_egress_output_metadata_t ostd;
        // See Section 6.5 of PSA spec for initial values of some
        // fields of ostd that P4 developers writing Egress code can
        // assume have been initialized.
        ostd.clone = false;
        // ostd.clone_session_id; // initial value is undefined
        ostd.drop = false;
        Egress.apply(hdr, user_meta, istd2, ostd);

        packet_out buffer2;
        CE2EM clone_e2e_meta;
        RECIRCM recirculate_meta;
        psa_egress_deparser_input_metadata_t edstd = {
            egress_port = egress_port};
        EgressDeparser.apply(buffer2, clone_e2e_meta, recirculate_meta,
            hdr, user_meta, istd2, edstd);

        // Take the packet data output by the deparser (in buffer2),
        // and append any portion of the packet that was not parsed by
        // the egress parser.
        packet() modp;
        modp.from_packet_out(buffer2);
        modp.append_with_offset(pkt, first_unparsed_bit_offset);

        // TODO: Check whether the resulting packet is in the range of
        // lengths supported by the implementation, and drop it if its
        // length is outside of that range.

        // Refer to section 6.5 "Behavior of packets after egress
        // processing is complete" of PSA spec.  The code below is
        // _very_ similar to that.
        if (ostd.clone) {
            if (CloneSessionIdSet.member(ostd.clone_session_id)) {
                // TODO: Make this as similar to the ingress-to-egress
                // clone specification code above, ideally calling the
                // same sub-control with one different input parameter
                // value.
                ClassOfService_t cos = TODO;
                if (ClassOfServiceIdSet.member(cos)) {
                    cos = 0;    // use default class 0 instead
                    // TODO: Recommended to log error about
                    // unsupported ostd.class_of_service value.
                }
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
        if (istd.egress_port == PSA_PORT_RECIRCULATE) {
            recircq_packet_t recircp = {
                ingress_port = istd.egress_port,
                user_recircm = recirculate_meta,
                p = modp};
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
