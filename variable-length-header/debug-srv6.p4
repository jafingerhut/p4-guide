control debug_srv6_fixedpart (in srv6_fixedpart_t srv6_fixedpart)
{
    bit<8> num_srv6_addresses;

    table debug {
        key = {
            num_srv6_addresses : exact;
            srv6_fixedpart.next_header : exact;
            srv6_fixedpart.hdr_ext_len : exact;
            srv6_fixedpart.routing_type : exact;
            srv6_fixedpart.segments_left : exact;
            srv6_fixedpart.last_entry : exact;
            srv6_fixedpart.flags : exact;
            srv6_fixedpart.tag : exact;
        }
        actions = { NoAction; }
        const default_action = NoAction;
    }
    apply {
        num_srv6_addresses = srv6_fixedpart.hdr_ext_len >> 1;
        debug.apply();
    }
}
