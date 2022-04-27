
control MyIngressDeparser(
    packet_out pkt,
    inout my_ingress_headers_t  ig_hdr,
    in    my_ingress_metadata_t ig_md,
    in    ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    apply {
        pkt.emit(ig_hdr.bridge_md);
        pkt.emit(ig_hdr.ethernet);
        pkt.emit(ig_hdr.ipv4);
    }
}

parser MyEgressParser(
    packet_in pkt,
    out my_egress_headers_t  eg_hdr,
    out my_egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md)
{
    state start {
        pkt.extract(eg_intr_md);
        transition parse_bridge_metadata;
    }

    state parse_bridge_metadata {
        pkt.extract(eg_hdr.bridge_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(eg_hdr.ethernet);
        transition accept;
    }
}

control MyEgress(
    inout my_egress_headers_t  eg_hdr,
    inout my_egress_metadata_t eg_md,
    in    egress_intrinsic_metadata_t                 eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t     eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t    eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{
    apply {
    }
}

control MyEgressDeparser(
    packet_out pkt,
    inout my_egress_headers_t  eg_hdr,
    in    my_egress_metadata_t eg_md,
    in    egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
    apply {
        pkt.emit(eg_hdr.ethernet);
    }
}

Pipeline(MyIngressParser(),
         MyIngress(),
         MyIngressDeparser(),
         MyEgressParser(),
         MyEgress(),
         MyEgressDeparser()) pipe;

Switch(pipe) main;
