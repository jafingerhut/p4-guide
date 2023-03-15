/* -*- P4_16 -*- */

#include <core.p4>
#include <pna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
 *************************************************************************/
const int IPV4_HOST_SIZE = 65536;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

typedef bit<48>  EthernetAddress;
typedef bit<32>  IPv4Address;
typedef bit<128> IPv6Address;

typedef bit<16> etype_t;
const etype_t ETYPE_IPV4      = 0x0800; /* IPv4 */

typedef bit<8> ipproto_t;
const ipproto_t IPPROTO_TCP = 6;       /* Transmission Control Protocol */
const ipproto_t IPPROTO_UDP = 17;      /* User Datagram Protocol */

// https://en.wikipedia.org/wiki/Ethernet_frame
header ethernet_h {
    EthernetAddress dst_addr;
    EthernetAddress src_addr;
    etype_t ether_type;
}

const bit<8> IPPROTO_TCP = 6;
const bit<8> IPPROTO_UDP = 17;

// RFC 791
// https://en.wikipedia.org/wiki/IPv4
// https://tools.ietf.org/html/rfc791
header ipv4_h {
    bit<8>  version_ihl;        // version always 4 for IPv4, ihl=header length
    bit<8>  diffserv;           // 6 bits of DSCP followed by 2-bit ECN
    bit<16> total_len;          // in bytes, including IPv4 header
    bit<16> identification;
    bit<16> flags_frag_offset;
    bit<8>  ttl;                // time to live
    ipproto_t protocol;
    bit<16> hdr_checksum;
    IPv4Address src_addr;
    IPv4Address dst_addr;
}

// RFC 793 and several later RFCs that update it
// https://en.wikipedia.org/wiki/Transmission_Control_Protocol
// https://tools.ietf.org/html/rfc793
header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

// Masks of the bit positions of some bit flags within the TCP flags
// field.
const bit<8> TCP_URG_MASK = 0x20;
const bit<8> TCP_ACK_MASK = 0x10;
const bit<8> TCP_PSH_MASK = 0x08;
const bit<8> TCP_RST_MASK = 0x04;
const bit<8> TCP_SYN_MASK = 0x02;
const bit<8> TCP_FIN_MASK = 0x01;

// RFC 768
// https://en.wikipedia.org/wiki/User_Datagram_Protocol
// https://tools.ietf.org/html/rfc768
header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    ipv4_h       ipv4;
    tcp_h        tcp;
    udp_h        udp;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
}

struct empty_metadata_t {
}

    /***********************  P A R S E R  **************************/
parser MainParserImpl(
    packet_in pkt,
    out   headers_t  hdr,
    inout metadata_t meta,
    in    pna_main_parser_input_metadata_t istd)
{
     state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select (hdr.ipv4.protocol) {
            IPPROTO_TCP: parse_tcp;
            IPPROTO_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control MainControlImpl(
    inout headers_t  hdr,
    inout metadata_t meta,
    in    pna_main_input_metadata_t  istd,
    inout pna_main_output_metadata_t ostd)
{

    action drop () {
        drop_packet();
    }

    // Inputs from previous tables (or actions, or in general other P4
    // code) that can modify the behavior of actions of ct_tcp_table.
    bool do_add_on_miss;
    bool update_aging_info;
    bool update_expire_time;
    ExpireTimeProfileId_t new_expire_time_profile_id;

    // Outputs from actions of ct_tcp_table
    AddEntryErrorStatus_t add_status;
    
    action tcp_syn_packet () {
        do_add_on_miss = true;
        update_aging_info = true;
        update_expire_time = true;
        new_expire_time_profile_id = EXPIRE_TIME_PROFILE_TCP_NEW;
    }
    action tcp_fin_or_rst_packet () {
        do_add_on_miss = false;
        update_aging_info = true;
        update_expire_time = true;
        new_expire_time_profile_id = EXPIRE_TIME_PROFILE_TCP_NOW;
    }
    action tcp_other_packets () {
        do_add_on_miss = false;
        update_aging_info = true;
        update_expire_time = true;
        new_expire_time_profile_id = EXPIRE_TIME_PROFILE_TCP_ESTABLISHED;
    }

    table set_ct_options {
        key = {
            hdr.tcp.flags: ternary;
        }
        actions = {
            tcp_syn_packet;
            tcp_fin_or_rst_packet;
            tcp_other_packets;
        }
        const entries = {
            TCP_SYN_MASK &&& TCP_SYN_MASK: tcp_syn_packet;
            TCP_FIN_MASK &&& TCP_FIN_MASK: tcp_fin_or_rst_packet;
            TCP_RST_MASK &&& TCP_RST_MASK: tcp_fin_or_rst_packet;
        }
        const default_action = tcp_other_packets;
    }
    
    action ct_tcp_table_hit () {
        if (update_aging_info) {
            if (update_expire_time) {
                set_entry_expire_time(new_expire_time_profile_id);
                // This is implicit and automatic part of the behavior
                // of set_entry_expire_time() call:
                //restart_expire_timer();
            } else {
                restart_expire_timer();
            }
            // a target might also support additional statements here
        } else {
            // Do nothing here.  In particular, DO NOT
            // restart_expire_time().  Whatever state the target
            // device uses per-entry to represent the last time this
            // entry was matched is left UNCHANGED.  This can be
            // useful in some connection tracking scenarios,
            // e.g. where one wishes to "star the timer" when a FIN
            // packet arrives, but it should KEEP RUNNING as later
            // packets arrive, without being restarted.

            // a target might also support additional statements here
        }
    }

    action ct_tcp_table_miss() {
        if (do_add_on_miss) {
            // This example does not need to use allocate_flow_id(),
            // because no later part of the P4 program uses its return
            // value for anything.
            add_status =
                add_entry(action_name = "ct_tcp_table_hit",  // name of action
                          action_params = (ct_tcp_table_hit_params_t)
                                          {},
                          expire_time_profile_id = new_expire_time_profile_id);
        } else {
            drop_packet();
        }
    }

    table ct_tcp_table {
        /* add_on_miss table is restricted to have all exact match fields */
        key = {
            // other key fields also possible, e.g. VRF
            SelectByDirection(is_net_port(istd.input_port), hdr.ipv4.srcAddr, hdr.ipv4.dstAddr):
                exact @name("ipv4_addr_0");
            SelectByDirection(is_net_port(istd.input_port), hdr.ipv4.dstAddr, hdr.ipv4.srcAddr):
                exact @name("ipv4_addr_1");
            hdr.ipv4.protocol : exact;
            SelectByDirection(is_net_port(istd.input_port), hdr.tcp.srcPort, hdr.tcp.dstPort):
                exact @name("tcp_port_0");
            SelectByDirection(is_net_port(istd.input_port), hdr.tcp.dstPort, hdr.tcp.srcPort):
                exact @name("tcp_port_1");
        }
        actions = {
            @tableonly   ct_tcp_table_hit;
            @defaultonly ct_tcp_table_miss;
        }

        // New PNA table property 'add_on_miss = true' indicates that
        // this table can use extern function add_entry() in its
        // default (i.e. miss) action to add a new entry to the table
        // from the data plane.
        add_on_miss = true;

        // TODO: Andy Fingerhut added the next line to the example on
        // 2022-Apr-26, but this table property is not yet documented
        // anywhere.
        // default_idle_timeout_for_data_plane_added_entries = 1;

        // Value AUTO_DELETE of table property pna_idle_timeout is new
        // in PNA relative to PSA.  It is similar to the value
        // NOTIFY_CONTROL in the PSA architecture, except that entries
        // that have not been matched for their idle time interval
        // will be deleted, without the control plane having to delete
        // the entry.  Also, no notification messages will be sent to
        // the control plane when this happens.
        pna_idle_timeout = PNA_IdleTimeout_t.AUTO_DELETE;
        const default_action = ct_tcp_table_miss;
    }

    action send(PortId_t port) {
        send_to_port(ostd, port);
    }

    table ipv4_host {
        key = {
            hdr.ipv4.dst_addr : exact;
        }
        actions = {
            send;
            drop;
            @defaultonly NoAction;
        }
        const default_action = drop();
        size = IPV4_HOST_SIZE;
    }

    apply {
        // The following code is here to give an _example_ similar to
        // the desired behavior, but is likely to be implemented in a
        // variety of ways, e.g. one or more P4 table lookups.  It is
        // also likely NOT to be identical to what someone experienced
        // at writing TCP connection tracking code actually wants.

        // The important point is that all of these variables:

        // + do_add_on_miss
        // + update_expire_time
        // + new_expire_time_profile_id

        // are assigned the values we want them to have _before_
        // calling ct_tcp_table.apply() below.  The conditions under
        // which they are assigned different values depends upon the
        // contents of the packet header fields and the direction of
        // the packet, and perhaps some earlier P4 table entries
        // populated by control plane software, but _not_ upon the
        // current entries installed in the ct_tcp_table.

        do_add_on_miss = false;
        update_expire_time = false;
        if (is_host_port(istd.input_port) &&
            hdr.ipv4.isValid() && hdr.tcp.isValid())
        {
            set_ct_options.apply();
        }

        // ct_tcp_table is a bidirectional table
        if (hdr.ipv4.isValid() && hdr.tcp.isValid()) {
            ct_tcp_table.apply();
        }

        if (hdr.ipv4.isValid()) {
            ipv4_host.apply();
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control MainDeparserImpl(
    packet_out pkt,
    in    headers_t hdr,
    in    metadata_t meta,
    in    pna_main_output_metadata_t ostd)
{
    apply {
        pkt.emit(hdr);
    }
}

/************ F I N A L   P A C K A G E ******************************/

PNA_NIC(
    MainParserImpl(),
    MainControlImpl(),
    MainDeparserImpl()
    ) main;
