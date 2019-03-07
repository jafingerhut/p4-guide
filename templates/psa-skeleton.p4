#include <core.p4>
#include <psa.p4>

struct headers_t {
}

struct empty_metadata_t {
}

struct metadata_t {
}

parser ingressParserImpl(packet_in packet,
                         out headers_t hdr,
                         inout metadata_t meta,
                         in psa_ingress_parser_input_metadata_t istd,
                         in empty_metadata_t resubmit_meta,
                         in empty_metadata_t recirculate_meta)
{
    state start {
        transition accept;
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    in    psa_ingress_input_metadata_t  istd,
                    inout psa_ingress_output_metadata_t ostd)
{
    apply {
    }
}

parser egressParserImpl(packet_in packet,
                        out headers_t hdr,
                        inout metadata_t meta,
                        in psa_egress_parser_input_metadata_t istd,
                        in empty_metadata_t normal_meta,
                        in empty_metadata_t clone_i2e_meta,
                        in empty_metadata_t clone_e2e_meta)
{
    state start {
        transition accept;
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   in    psa_egress_input_metadata_t  istd,
                   inout psa_egress_output_metadata_t ostd)
{
    apply { }
}

control CommonDeparserImpl(packet_out packet,
                           inout headers_t hdr)
{
    apply {
    }
}

control IngressDeparserImpl(packet_out packet,
                            out empty_metadata_t clone_i2e_meta,
                            out empty_metadata_t resubmit_meta,
                            out empty_metadata_t normal_meta,
                            inout headers_t hdr,
                            in metadata_t meta,
                            in psa_ingress_output_metadata_t istd)
{
    CommonDeparserImpl() cp;
    apply {
        cp.apply(packet, hdr);
    }
}

control EgressDeparserImpl(packet_out packet,
                           out empty_metadata_t clone_e2e_meta,
                           out empty_metadata_t recirculate_meta,
                           inout headers_t hdr,
                           in metadata_t meta,
                           in psa_egress_output_metadata_t istd,
                           in psa_egress_deparser_input_metadata_t edstd)
{
    CommonDeparserImpl() cp;
    apply {
        cp.apply(packet, hdr);
    }
}

IngressPipeline(ingressParserImpl(),
                ingressImpl(),
                IngressDeparserImpl()) ip;

EgressPipeline(egressParserImpl(),
               egressImpl(),
               EgressDeparserImpl()) ep;

PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
