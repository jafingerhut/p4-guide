
control dash_precontrol(
    in    headers_t pre_hdr,
    inout metadata_t pre_user_meta,
    in    pna_pre_input_metadata_t  istd,
    inout pna_pre_output_metadata_t ostd)
{
    apply {
    }
}

PNA_NIC(
    dash_parser(),
    dash_precontrol(),
    dash_ingress(),
    dash_deparser()) main;
