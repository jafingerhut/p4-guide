/* -*- P4_16 -*- */

#include <core.p4>
#include <pna.p4>

typedef bit<48>  EthernetAddress;

typedef bit<16> etype_t;

// https://en.wikipedia.org/wiki/Ethernet_frame
header ethernet_h {
    EthernetAddress dst_addr;
    EthernetAddress src_addr;
    etype_t ether_type;
}

struct headers_t {
    ethernet_h   ethernet;
}

struct metadata_t {
}

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

control MainControlImpl(
    inout headers_t  hdr,
    inout metadata_t meta,
    in    pna_main_input_metadata_t  istd,
    inout pna_main_output_metadata_t ostd)
{
    action drop() {
        drop_packet();
    }

    table mac_da {
        key = { hdr.ethernet.dst_addr : exact; }
        actions = {
            drop;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = 1024;
    }

    apply {
        if (hdr.ethernet.isValid()) {
            mac_da.apply();
            hdr.ethernet.src_addr = (bit<48>) ((TimestampUint_t) istd.timestamp);
            send_to_port((PortId_t) 0);
        }
    }
}

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

PNA_NIC(
    MainParserImpl(),
    PreControlImpl(),
    MainControlImpl(),
    MainDeparserImpl()
    ) main;
