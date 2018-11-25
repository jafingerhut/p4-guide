control convert_error_to_int (in error parser_error,
                              out bit<8> err_code)
{
    apply {
        if (parser_error == error.NoError) {
            err_code = 0;
        } else if (parser_error == error.PacketTooShort) {
            err_code = 1;
        } else if (parser_error == error.NoMatch) {
            err_code = 2;
        } else if (parser_error == error.StackOutOfBounds) {
            err_code = 3;
        } else if (parser_error == error.HeaderTooShort) {
            err_code = 4;
        } else if (parser_error == error.ParserTimeout) {
            err_code = 5;
        } else if (parser_error == error.BadSRv6HdrExtLen) {
            err_code = 6;
        } else {
            err_code = 0xff;
        }
    }
}

control debug_srv6_fixedpart (in srv6_fixedpart_t srv6_fixedpart,
                              in error parser_error)
{
    bit<8> num_srv6_addresses;
    bit<8> int_parser_error;

    table debug {
        key = {
            int_parser_error : exact;
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
        convert_error_to_int.apply(parser_error, int_parser_error);
        debug.apply();
    }
}
