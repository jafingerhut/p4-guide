/* -*- P4_16 -*- */

#include <core.p4>
#include <psa.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_h {
    bit<48>   dst_addr;
    bit<48>   src_addr;
    bit<16>   ether_type;
}

header vlan_tag_h {
    bit<16> pcp_cfi_vid;
    bit<16>  ether_type;
}

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

const int IPV4_HOST_SIZE = 65536;

typedef bit<48> ethernet_addr_t;

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
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
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_TPID:  parse_vlan_tag;
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
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
    InternetChecksum() ck;

    action send(PortId_t port) {
        send_to_port(ostd, port);
        hdr.ipv4.ttl = 42;
        // recalculate the IPv4 header checksum

        ck.clear();
        // The following version did not work correctly, probably
        // because of known issues with DPDK IPv4 checksum
        // implementation:
//        ck.add({
//            /* 16-bit word  0   */ hdr.ipv4.version_ihl, hdr.ipv4.diffserv,
//            /* 16-bit word  1   */ hdr.ipv4.total_len,
//            /* 16-bit word  2   */ hdr.ipv4.identification,
//            /* 16-bit word  3   */ hdr.ipv4.flags_frag_offset,
//            /* 16-bit word  4   */ hdr.ipv4.ttl, hdr.ipv4.protocol,
//            /* 16-bit word  5 skip hdr.ipv4.hdr_checksum, */
//            /* 16-bit words 6-7 */ hdr.ipv4.src_addr,
//            /* 16-bit words 8-9 */ hdr.ipv4.dst_addr
//            });

        bit<16> word0 = hdr.ipv4.version_ihl ++ hdr.ipv4.diffserv;
        bit<16> word4 = hdr.ipv4.ttl ++ hdr.ipv4.protocol;
        ck.add({
            /* 16-bit word  0   */ word0,
            /* 16-bit word  1   */ hdr.ipv4.total_len,
            /* 16-bit word  2   */ hdr.ipv4.identification,
            /* 16-bit word  3   */ hdr.ipv4.flags_frag_offset,
            /* 16-bit word  4   */ word4,
            /* 16-bit word  5 skip hdr.ipv4.hdr_checksum, */
            /* 16-bit words 6-7 */ hdr.ipv4.src_addr,
            /* 16-bit words 8-9 */ hdr.ipv4.dst_addr
            });

        hdr.ipv4.hdr_checksum = ck.get();
    }

    action drop() {
        ingress_drop(ostd);
    }
    
    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send;drop;
            @defaultonly NoAction;
        }

        const default_action = drop();

        size = IPV4_HOST_SIZE;
    }


    apply {
                ipv4_host.apply();
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
