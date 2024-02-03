/* -*- P4_16 -*- */

#include <core.p4>
#include <psa.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
 *************************************************************************/
const int IPV4_HOST_SIZE = 65536;

typedef bit<48> ethernet_addr_t;

const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_h {
    ethernet_addr_t  dst_addr;
    ethernet_addr_t  src_addr;
    bit<16>   ether_type;
}

const bit<8> IPPROTO_IPIP = 4;      /* IP in IP encapsulation */

header ipv4_h {
    bit<8>       version_ihl;
    bit<8>       diffserv;
    bit<16>      total_len;
    bit<16>      identification;
    bit<16>      flags_frag_offset;
    bit<8>       ttl;
    bit<8>       protocol;
    bit<16>      hdr_checksum;
    bit<32>      src_addr;
    bit<32>      dst_addr;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    ipv4_h       ipv4;
    ipv4_h       inner_ipv4;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
}

struct empty_metadata_t {
}

    /***********************  P A R S E R  **************************/
parser Ingress_Parser(
    packet_in pkt,
    out my_ingress_headers_t hdr,
    inout my_ingress_metadata_t meta,
    in psa_ingress_parser_input_metadata_t ig_intr_md,
    in empty_metadata_t resub_meta, 
    in empty_metadata_t recirc_meta)
{
     state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select (hdr.ipv4.protocol) {
            IPPROTO_IPIP: parse_inner_ipv4;
            default: accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control ingress(
    inout my_ingress_headers_t hdr,
    inout my_ingress_metadata_t meta,
    in psa_ingress_input_metadata_t ig_intr_md,
    inout psa_ingress_output_metadata_t ostd
)
{
    action send(PortId_t port) {
        send_to_port(ostd, port);
    }

    action decap() {
        hdr.ipv4 = hdr.inner_ipv4;
    }

    action decap_and_send(PortId_t port) {
        decap();
        send(port);
    }

    action drop() {
        ingress_drop(ostd);
    }
    
    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send;
            decap_and_send;
            drop;
            @defaultonly NoAction;
        }
        const default_action = drop();
        size = IPV4_HOST_SIZE;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_host.apply();
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control Ingress_Deparser(packet_out pkt,
    out empty_metadata_t clone_i2e_meta, 
    out empty_metadata_t resubmit_meta, 
    out empty_metadata_t normal_meta,
    inout my_ingress_headers_t hdr,
    in    my_ingress_metadata_t meta,
    in psa_ingress_output_metadata_t istd)
{
    apply {
        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_egress_headers_t {
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
}

    /***********************  P A R S E R  **************************/

parser Egress_Parser(
    packet_in pkt,
    out my_egress_headers_t hdr,
    inout my_ingress_metadata_t meta,
    in psa_egress_parser_input_metadata_t istd, 
    in empty_metadata_t normal_meta, 
    in empty_metadata_t clone_i2e_meta, 
    in empty_metadata_t clone_e2e_meta)
{
    state start {
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control egress(
    inout my_egress_headers_t hdr,
    inout my_ingress_metadata_t meta,
    in psa_egress_input_metadata_t istd, 
    inout psa_egress_output_metadata_t ostd)
{
    apply {
    }
}

    /*********************  D E P A R S E R  ************************/

control Egress_Deparser(packet_out pkt,
    out empty_metadata_t clone_e2e_meta, 
    out empty_metadata_t recirculate_meta,
    inout my_egress_headers_t hdr,
    in my_ingress_metadata_t meta,
    in psa_egress_output_metadata_t istd, 
    in psa_egress_deparser_input_metadata_t edstd)
{
    apply {
        pkt.emit(hdr);
    }
}

#if __p4c__
bit<32> test_version = __p4c_version__;
#endif

/************ F I N A L   P A C K A G E ******************************/

IngressPipeline(Ingress_Parser(), ingress(), Ingress_Deparser()) pipe;

EgressPipeline(Egress_Parser(), egress(), Egress_Deparser()) ep;

PSA_Switch(pipe, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
