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

// Define names for different expire time profile id values.

const ExpireTimeProfileId_t EXPIRE_TIME_PROFILE_TCP_NOW    = (ExpireTimeProfileId_t) 0;
const ExpireTimeProfileId_t EXPIRE_TIME_PROFILE_TCP_NEW    = (ExpireTimeProfileId_t) 1;
const ExpireTimeProfileId_t EXPIRE_TIME_PROFILE_TCP_ESTABLISHED = (ExpireTimeProfileId_t) 2;
const ExpireTimeProfileId_t EXPIRE_TIME_PROFILE_TCP_NEVER  = (ExpireTimeProfileId_t) 3;

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct headers_t {
    ethernet_h   ethernet;
    ipv4_h       ipv4;
    tcp_h        tcp;
    udp_h        udp;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct metadata_t {
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

// As of 2023-Mar-14, p4c-dpdk implementation of PNA architecture
// still requires PreControl.

control PreControlImpl(
    in    headers_t hdr,
    inout metadata_t meta,
    in    pna_pre_input_metadata_t  istd,
    inout pna_pre_output_metadata_t ostd)
{
    apply {
    }
}

    /***************** M A T C H - A C T I O N  *********************/

struct ct_tcp_table_hit_params_t {
}

//////////////////////////////////////////////////////////////////////
// Note 1
//////////////////////////////////////////////////////////////////////

// These notes were tested with p4c-dpdk built from the version below
// of the source code in repository https://github.com/p4lang/p4c

// $ git log -n 1 | head -n 5
// commit ca1f3474d532aa5c8eea5db5adbd838bc8b52d07
// Author: Fabian Ruffy <5960321+fruffy@users.noreply.github.com>
// Date:   Thu Feb 23 10:40:19 2023 -0500
// 
//     Deprecate unified build in favor of unity build. (#3491)

// As of that version of p4c-dpdk and its support for the PNA
// architecture, these things appear to be true:

// Its support corresponds with what was published in PNA version 0.5,
// without several changes made in PNA version 0.7.

// In particular, for tables with 'add_on_miss = true', it is a
// compile time error if you attempt to assign to the table property
// pna_idle_timeout the new PNA v0.7 value of
// PNA_IdleTimeout_t.AUTO_DELETE.

// Instead, you may assign the following table property in a table
// that has add_on_miss true:

//        idle_timeout_with_auto_delete = true;

// If you do NOT assign true to table property
// idle_timeout_with_auto_delete, then it is a compile time error to
// attempt to call either of these extern functions in the table's hit
// action:

// + set_entry_expire_time
// + restart_expire_timer

// Either or both of those extern functions _are_ supported in an
// add-on-miss table's hit action as long as you do assign true to
// table property idle_timeout_with_auto_delete.

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
    bool add_status;
    
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
        // Comenting out the 'const entries' for now, since I am not
        // sure whether DPDK supports them.  I will add these entries
        // at init time from the control plane.
//        const entries = {
//            TCP_SYN_MASK &&& TCP_SYN_MASK: tcp_syn_packet;
//            TCP_FIN_MASK &&& TCP_FIN_MASK: tcp_fin_or_rst_packet;
//            TCP_RST_MASK &&& TCP_RST_MASK: tcp_fin_or_rst_packet;
//        }
        const default_action = tcp_other_packets;
    }
    
    action ct_tcp_table_hit () {
        // Make a change that is visible in the packet output by the
        // device, for debug purposes only.  I cannot imagine any
        // reason why someone would want to make a change like this to
        // a packet in a production P4 program.
        hdr.ethernet.src_addr[7:0] = 0xf1;
        if (update_aging_info) {
            if (update_expire_time) {
                // See Note 1
                set_entry_expire_time(new_expire_time_profile_id);
                // This is implicit and automatic part of the behavior
                // of set_entry_expire_time() call:
                //restart_expire_timer();
            } else {
                // See Note 1
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
        // Make a change to the packet that is visible in the packet
        // output by the device, for debug purposes only.  I cannot
        // imagine any reason why someone would want to make a change
        // like this to a packet in a production P4 program.
        hdr.ethernet.src_addr[7:0] = 0xa5;
        if (do_add_on_miss) {
            // This example does not need to use allocate_flow_id(),
            // because no later part of the P4 program uses its return
            // value for anything.
            add_status =
                add_entry(action_name = "ct_tcp_table_hit",  // name of action
                          action_params = (ct_tcp_table_hit_params_t) {},
                          expire_time_profile_id = new_expire_time_profile_id);
        } else {
            drop_packet();
        }
    }

    table ct_tcp_table {
        /* add_on_miss table is restricted to have all exact match fields */
        key = {
            // other key fields also possible, e.g. VRF
            SelectByDirection(istd.direction, hdr.ipv4.src_addr, hdr.ipv4.dst_addr):
                exact @name("ipv4_addr_0");
            SelectByDirection(istd.direction, hdr.ipv4.dst_addr, hdr.ipv4.src_addr):
                exact @name("ipv4_addr_1");
            hdr.ipv4.protocol : exact;
            SelectByDirection(istd.direction, hdr.tcp.src_port, hdr.tcp.dst_port):
                exact @name("tcp_port_0");
            SelectByDirection(istd.direction, hdr.tcp.dst_port, hdr.tcp.src_port):
                exact @name("tcp_port_1");
        }
        actions = {
            @tableonly   ct_tcp_table_hit;
            @defaultonly ct_tcp_table_miss;
        }

        // Table property 'add_on_miss = true' is new in the PNA
        // architecture.  It indicates that this table can use extern
        // function add_entry() in its default (i.e. miss) action to
        // add a new entry to the table from the data plane, without
        // any action required from the control plane software.
        add_on_miss = true;

        // Table property 'idle_timeout_with_auto_delete = true' was
        // the method documented in PNA version 0.5 to enable the
        // following feature:
        //
        // + The data plane auto-deletes entries when the table entry
        //   had never been matched in longer than a configured time
        //   interval.
        //
        // This table property is supported by p4c-dpdk and the DPDK
        // back end as of 2023-Mar-19.
        //
        // If p4c-dpdk and DPDK are updated to support PNA version
        // 0.7, the 'idle_timeout_with_auto_delete' table property
        // should be replaced with the following instead:
        //
        // pna_idle_timeout = PNA_IdleTimeout_t.AUTO_DELETE;
        idle_timeout_with_auto_delete = true;

        const default_action = ct_tcp_table_miss;
    }

    action send(PortId_t port) {
        // Make a change to the packet that is visible in the packet
        // output by the device, for debug purposes only.  I cannot
        // imagine any reason why someone would want to make a change
        // like this to a packet in a production P4 program.
        hdr.ethernet.src_addr[15:8] = (bit<8>) ((istd.direction == PNA_Direction_t.HOST_TO_NET) ? 0 : 1);
        send_to_port(port);
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
        // current entries installed in ct_tcp_table.

        do_add_on_miss = false;
        update_expire_time = false;
        if ((istd.direction == PNA_Direction_t.HOST_TO_NET) &&
            hdr.ipv4.isValid() && hdr.tcp.isValid())
        {
            set_ct_options.apply();
        }
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
    PreControlImpl(),
    MainControlImpl(),
    MainDeparserImpl()
    ) main;
