// A sketch of at least part of a layer 4 firewall implemented in P4.

// NIC network ports are considered "outside" the firewall, host VMs
// are all "inside" the firewall.  The firewall is intended to drop
// packets from outside, i.e. from network ports, that are not
// explicitly allowed through by the firewall.  All flows explicitly
// allowed through are specified via 5-tuple table entries in the
// allowed_flows table.

// New entries can be added to allowed_flows by the control plane, of
// course, but this program also demonstrates a new proposed feature
// for adding new entries in the data plane, via the add_entry()
// function.

// New entries are added for the first TCP, UDP, or ICMP packet coming
// from inside, going outside.

// New entries can also be added for other reasons, e.g. an FTP
// control connection (indicated by TCP port number 21) has its
// packets copied to a control plane CPU on the NIC for scanning its
// payload contents, looking for strings in the TCP stream data such
// as "port 59112", where 59112 is an sequence of 5 ASCII characters
// representing a TCP port number in decimal of a new FTP data
// connection to be created.  These control connections are typically
// very low packet and bit rates relative to other connections.

// The NIC control plane CPU can then add new entries to allowed_flows
// as needed.

enum bit<1> PNA_Direction_t {
    NET_TO_HOST = 0,
    HOST_TO_NET = 1
}

typedef bit<9>  PortId_t;
typedef bit<10> VMId_t;
typedef bit<2>  ExpireTimeSelection_t;
typedef bit<24> FlowId_t;

// Part of two work-in-progress standard metadata structs for PNA
struct pna_main_input_metadata_t {
    PNA_Direction_t direction;
    // input fields to main control that are only initialized if
    // direction == DIR_NET_TO_HOST
    PortId_t  input_port;
    // input fields to main control that are only initialized if
    // direction == DIR_HOST_TO_NET
    VMId_t    input_vm;
}

struct pna_main_output_metadata_t {
    bool   drop;
    bool   clone;            // false
    CloneSessionId_t         clone_session_id; // initial value is undefined

    // output fields from main control that are only used by PNA
    // device to decide what to do with the packet next if direction
    // == NET_TO_HOST
    VMId_t   dest_vm;

    // output fields from main control that are only used by PNA device
    // to decide what to do with the packet next if direction ==
    // HOST_TO_NET
    PortId_t dest_port;
}

enum bit<3> fw_action_t {
    DENY = 0,
    ALLOW = 1,
    ALLOW_AND_COPY_TO_CPU = 2
}

struct firewall_forwarding_decision_t {
    fw_action_t action;
    VMId_t      dest_vm;
}

control mainCtrl (in bit<1> direction,
                  inout headers_t hdr,    // includes ethernet, ipv4, etc.
                  inout metadata_t meta,  // user-defined metadata
                  in    pna_main_input_metadata_t  in_md,  // standard metadata in
                  inout pna_main_output_metadata_t out_md)
{
    bool add_on_miss = false;
    bool update_expire_time = false;
    FlowId_t my_flow_id = 0;
    bool add_succeeded = false;
    bool allowed_flow_hit;
    bool new_allowed_flow_entry = false;

    // Used to identify packets in control connections, e.g. TCP
    // source port 21, or TCP dest port 21, for FTP control connection
    // packets.  The addreses will likely be wildcarded for most
    // entries.  Entries are added to this table only by the control
    // plane software.  Ex
    action set_firewall_control_packet (bit<1> fw_ctrl_packet) {
        meta.fw_ctrl_packet = fw_ctrl_packet;
    }

    table firewall_control_flows {
        key = {
            meta.flowkey.addr1 : ternary;  // same key fields as allowed_flows
            meta.flowkey.addr2 : ternary;
            meta.ipv4.protocol : ternary;
            meta.flowkey.port1 : ternary;
            meta.flowkey.port2 : ternary;
        }
        actions = { set_firewall_control_packet; }
        size = 64;
        const default_action = set_firewall_control_packet(0);
    }
    
    action set_flow_id (FlowId_t flow_id,
                        @per_entry_state inout ExpireTimeSelection_t expire_time)
    {
        my_flow_id = flow_id;
        if (update_expire_time) {
            expire_time = new_expire_time_selection;
        }
    }

    action maybe_add_new_flow () {
        if (add_on_miss) {
            my_flow_id = allocate_flow_id();
            add_succeeded =
                add_entry("set_flow_id",  // name of action
                          (aom_table_hit_params_t)
                          {flow_id = my_flow_id,
		           expire_time = new_expire_time_selection});
        }
    }
    
    // This table is common to, and looked up, for both
    // host-to-network and network-to-host packets.
    table allowed_flows {
        key = {
            meta.flowkey.addr1 : exact;  // SA for host->net, DA for net->host
            meta.flowkey.addr2 : exact;  // opposite of addr1
            meta.ipv4.protocol : exact;
            meta.flowkey.port1 : exact;  // src port for host->net, dest port for net->host
            meta.flowkey.port2 : exact;  // opposite of port1
        }
        actions = {
            @tableonly   set_flow_id;
            @defaultonly maybe_add_new_flow;
        }
        add_on_miss = true;
        size = 10000000;   // 10 million
        const default_action = maybe_add_new_flow;
    }

    apply {
        if (in_md.direction == PNA_Direction_t.HOST_TO_NET) {
            meta.flowkey.addr1 = hdr.ipv4.srcAddr;
            meta.flowkey.addr2 = hdr.ipv4.dstAddr;
            meta.flowkey.port1 = hdr.l4.srcPort;
            meta.flowkey.port2 = hdr.l4.dstPort;
        } else {
            // swap order of SA/DA and src/dst port for
            // network-to-host packets in table lookup key
            meta.flowkey.addr1 = hdr.ipv4.dstAddr;
            meta.flowkey.addr2 = hdr.ipv4.srcAddr;
            meta.flowkey.port1 = hdr.l4.dstPort;
            meta.flowkey.port2 = hdr.l4.srcPort;
        }

        // For UDP, ICMP, or TCP SYN packets from the host to the
        // network, the first packet out should trigger the addition
        // of a new table entry that allows packets in the reverse
        // direction to come in.
        if ((in_md.direction == PNA_Direction_t.HOST_TO_NET) &&
            ((hdr.tcp.isValid() && hdr.tcp.syn == 1) ||
             hdr.udp.isValid() || hdr.icmp.isValid()))
        {
            add_on_miss = true;
        }
        if (allowed_flows.apply().hit) {
        } else {
            new_allowed_flow_entry = add_on_miss && add_succeeded && (my_flow_id != 0);
            // anything from outside the firewall (i.e. the network ports)
            // that got a miss should be denied by the firewall.
            if (in_md.direction == PNA_Direction_t.HOST_TO_NET) {
            }
        }

        if (new_allowed_flow_entry) {
            // New entry added in data plane is always for
            // host-to-network packet.  Future net-to-host packets
            // matching this new entry should always be sent to the VM
            // from which the original packet came, in_md.input_vm
            fw_decision.action = fw_action_t.ALLOW;
            fw_decision.dest_vm = in_md.input_vm;
            allowed_flow_action.write(my_flow_id, fw_decision);
        } else {
            // Read the previously written fw_decision from the P4 register.
            allowed_flow_action.read(my_flow_id, fw_decision);
            // Corner cases: my_flow_id will be 0 here in several
            // cases, e.g. a miss in the allowed_flows table where we
            // did not add a new entry, or we tried to add a new entry
            // but failed (e.g. table is full).  Control plane
            // software inits entry 0 of the array with a DENY
            // decision, and data plane never changes it.
        }

        if ((fw_decision.action == fw_action_t.ALLOW_AND_COPY_TO_CPU) ||
            (meta.fw_ctrl_packet == 1))
        {
            // Clone a copy of the packet to control CPU
            out_md.clone = true;
            out_md.clone_session_id = CPU_SESSION_ID;
        }
        if (fw_decision.action == fw_action_t.DENY) {
            out_md.drop = true;
            exit;
        }
        out_md.drop = false;
        if (in_md.direction == PNA_Direction_t.NET_TO_HOST) {
            // Force dest VM to be the one that created the
            // allowed_flows entry.
            out_md.dest_vm = fw_decision.dest_vm;
        }

        // Forwarding decision code here for host-to-net packets to
        // decide which Ethernet port packet should be sent out.
    }
}
