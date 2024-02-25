
control dash_verify_checksum(inout headers_t hdr,
                         inout metadata_t meta)
{
    apply { }
}

control dash_compute_checksum(inout headers_t hdr,
                          inout metadata_t meta)
{
    apply { }
}

control dash_egress(inout headers_t hdr,
                 inout metadata_t meta,
                 inout standard_metadata_t standard_metadata)
{
    apply { }
}

V1Switch(dash_parser(),
         dash_verify_checksum(),
         dash_ingress(),
         dash_egress(),
         dash_compute_checksum(),
         dash_deparser()) main;
