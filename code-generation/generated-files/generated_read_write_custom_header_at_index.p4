
control read_custom_header_at_index (in my_custom_hdr_t my_custom_hdr,
                                     in bit<8> index,
				     out bit<16> result,
                                     out bool index_in_range)
{

    action read_offset_0 () {
        result = my_custom_hdr.f0 ++ my_custom_hdr.f1;
    }

    action read_offset_1 () {
        result = my_custom_hdr.f1 ++ my_custom_hdr.f2;
    }

    action read_offset_2 () {
        result = my_custom_hdr.f2 ++ my_custom_hdr.f3;
    }

    action read_offset_3 () {
        result = my_custom_hdr.f3 ++ my_custom_hdr.f4;
    }

    action read_offset_4 () {
        result = my_custom_hdr.f4 ++ my_custom_hdr.f5;
    }

    action read_offset_5 () {
        result = my_custom_hdr.f5 ++ my_custom_hdr.f6;
    }

    action read_offset_6 () {
        result = my_custom_hdr.f6 ++ my_custom_hdr.f7;
    }

    action read_offset_7 () {
        result = my_custom_hdr.f7 ++ my_custom_hdr.f8;
    }

    action read_offset_8 () {
        result = my_custom_hdr.f8 ++ my_custom_hdr.f9;
    }

    action read_offset_9 () {
        result = my_custom_hdr.f9 ++ my_custom_hdr.f10;
    }

    action read_offset_10 () {
        result = my_custom_hdr.f10 ++ my_custom_hdr.f11;
    }

    action read_offset_11 () {
        result = my_custom_hdr.f11 ++ my_custom_hdr.f12;
    }

    action read_offset_12 () {
        result = my_custom_hdr.f12 ++ my_custom_hdr.f13;
    }

    action read_offset_13 () {
        result = my_custom_hdr.f13 ++ my_custom_hdr.f14;
    }

    action read_offset_14 () {
        result = my_custom_hdr.f14 ++ my_custom_hdr.f15;
    }

    action read_offset_15 () {
        result = my_custom_hdr.f15 ++ my_custom_hdr.f16;
    }

    action read_offset_16 () {
        result = my_custom_hdr.f16 ++ my_custom_hdr.f17;
    }

    action read_offset_17 () {
        result = my_custom_hdr.f17 ++ my_custom_hdr.f18;
    }

    action read_offset_18 () {
        result = my_custom_hdr.f18 ++ my_custom_hdr.f19;
    }

    action read_offset_19 () {
        result = my_custom_hdr.f19 ++ my_custom_hdr.f20;
    }

    action read_offset_20 () {
        result = my_custom_hdr.f20 ++ my_custom_hdr.f21;
    }

    action read_offset_21 () {
        result = my_custom_hdr.f21 ++ my_custom_hdr.f22;
    }

    action read_offset_22 () {
        result = my_custom_hdr.f22 ++ my_custom_hdr.f23;
    }

    action read_offset_23 () {
        result = my_custom_hdr.f23 ++ my_custom_hdr.f24;
    }

    action read_offset_24 () {
        result = my_custom_hdr.f24 ++ my_custom_hdr.f25;
    }

    action read_offset_25 () {
        result = my_custom_hdr.f25 ++ my_custom_hdr.f26;
    }

    action read_offset_26 () {
        result = my_custom_hdr.f26 ++ my_custom_hdr.f27;
    }

    action read_offset_27 () {
        result = my_custom_hdr.f27 ++ my_custom_hdr.f28;
    }

    action read_offset_28 () {
        result = my_custom_hdr.f28 ++ my_custom_hdr.f29;
    }

    action read_offset_29 () {
        result = my_custom_hdr.f29 ++ my_custom_hdr.f30;
    }

    action read_offset_30 () {
        result = my_custom_hdr.f30 ++ my_custom_hdr.f31;
    }

    action index_out_of_range () {
        index_in_range = false;
        result = 0;
    }

    table read_from_index {
        key = {
            index : exact;
        }
        actions = {
            read_offset_0;
            read_offset_1;
            read_offset_2;
            read_offset_3;
            read_offset_4;
            read_offset_5;
            read_offset_6;
            read_offset_7;
            read_offset_8;
            read_offset_9;
            read_offset_10;
            read_offset_11;
            read_offset_12;
            read_offset_13;
            read_offset_14;
            read_offset_15;
            read_offset_16;
            read_offset_17;
            read_offset_18;
            read_offset_19;
            read_offset_20;
            read_offset_21;
            read_offset_22;
            read_offset_23;
            read_offset_24;
            read_offset_25;
            read_offset_26;
            read_offset_27;
            read_offset_28;
            read_offset_29;
            read_offset_30;
            @defaultonly index_out_of_range;
        }
        const entries = {
            0 : read_offset_0();
            1 : read_offset_1();
            2 : read_offset_2();
            3 : read_offset_3();
            4 : read_offset_4();
            5 : read_offset_5();
            6 : read_offset_6();
            7 : read_offset_7();
            8 : read_offset_8();
            9 : read_offset_9();
            10 : read_offset_10();
            11 : read_offset_11();
            12 : read_offset_12();
            13 : read_offset_13();
            14 : read_offset_14();
            15 : read_offset_15();
            16 : read_offset_16();
            17 : read_offset_17();
            18 : read_offset_18();
            19 : read_offset_19();
            20 : read_offset_20();
            21 : read_offset_21();
            22 : read_offset_22();
            23 : read_offset_23();
            24 : read_offset_24();
            25 : read_offset_25();
            26 : read_offset_26();
            27 : read_offset_27();
            28 : read_offset_28();
            29 : read_offset_29();
            30 : read_offset_30();
        }
        const default_action = index_out_of_range;
    }

    apply {
        index_in_range = true;
        read_from_index.apply();
    }
}

control write_custom_header_at_index (inout my_custom_hdr_t my_custom_hdr,
                                      in bit<8> index,
				      in bit<16> write_val,
                                      out bool index_in_range)
{

    action write_offset_0 () {
        my_custom_hdr.f0 = write_val[15:8];
        my_custom_hdr.f1 = write_val[7:0];
    }

    action write_offset_1 () {
        my_custom_hdr.f1 = write_val[15:8];
        my_custom_hdr.f2 = write_val[7:0];
    }

    action write_offset_2 () {
        my_custom_hdr.f2 = write_val[15:8];
        my_custom_hdr.f3 = write_val[7:0];
    }

    action write_offset_3 () {
        my_custom_hdr.f3 = write_val[15:8];
        my_custom_hdr.f4 = write_val[7:0];
    }

    action write_offset_4 () {
        my_custom_hdr.f4 = write_val[15:8];
        my_custom_hdr.f5 = write_val[7:0];
    }

    action write_offset_5 () {
        my_custom_hdr.f5 = write_val[15:8];
        my_custom_hdr.f6 = write_val[7:0];
    }

    action write_offset_6 () {
        my_custom_hdr.f6 = write_val[15:8];
        my_custom_hdr.f7 = write_val[7:0];
    }

    action write_offset_7 () {
        my_custom_hdr.f7 = write_val[15:8];
        my_custom_hdr.f8 = write_val[7:0];
    }

    action write_offset_8 () {
        my_custom_hdr.f8 = write_val[15:8];
        my_custom_hdr.f9 = write_val[7:0];
    }

    action write_offset_9 () {
        my_custom_hdr.f9 = write_val[15:8];
        my_custom_hdr.f10 = write_val[7:0];
    }

    action write_offset_10 () {
        my_custom_hdr.f10 = write_val[15:8];
        my_custom_hdr.f11 = write_val[7:0];
    }

    action write_offset_11 () {
        my_custom_hdr.f11 = write_val[15:8];
        my_custom_hdr.f12 = write_val[7:0];
    }

    action write_offset_12 () {
        my_custom_hdr.f12 = write_val[15:8];
        my_custom_hdr.f13 = write_val[7:0];
    }

    action write_offset_13 () {
        my_custom_hdr.f13 = write_val[15:8];
        my_custom_hdr.f14 = write_val[7:0];
    }

    action write_offset_14 () {
        my_custom_hdr.f14 = write_val[15:8];
        my_custom_hdr.f15 = write_val[7:0];
    }

    action write_offset_15 () {
        my_custom_hdr.f15 = write_val[15:8];
        my_custom_hdr.f16 = write_val[7:0];
    }

    action write_offset_16 () {
        my_custom_hdr.f16 = write_val[15:8];
        my_custom_hdr.f17 = write_val[7:0];
    }

    action write_offset_17 () {
        my_custom_hdr.f17 = write_val[15:8];
        my_custom_hdr.f18 = write_val[7:0];
    }

    action write_offset_18 () {
        my_custom_hdr.f18 = write_val[15:8];
        my_custom_hdr.f19 = write_val[7:0];
    }

    action write_offset_19 () {
        my_custom_hdr.f19 = write_val[15:8];
        my_custom_hdr.f20 = write_val[7:0];
    }

    action write_offset_20 () {
        my_custom_hdr.f20 = write_val[15:8];
        my_custom_hdr.f21 = write_val[7:0];
    }

    action write_offset_21 () {
        my_custom_hdr.f21 = write_val[15:8];
        my_custom_hdr.f22 = write_val[7:0];
    }

    action write_offset_22 () {
        my_custom_hdr.f22 = write_val[15:8];
        my_custom_hdr.f23 = write_val[7:0];
    }

    action write_offset_23 () {
        my_custom_hdr.f23 = write_val[15:8];
        my_custom_hdr.f24 = write_val[7:0];
    }

    action write_offset_24 () {
        my_custom_hdr.f24 = write_val[15:8];
        my_custom_hdr.f25 = write_val[7:0];
    }

    action write_offset_25 () {
        my_custom_hdr.f25 = write_val[15:8];
        my_custom_hdr.f26 = write_val[7:0];
    }

    action write_offset_26 () {
        my_custom_hdr.f26 = write_val[15:8];
        my_custom_hdr.f27 = write_val[7:0];
    }

    action write_offset_27 () {
        my_custom_hdr.f27 = write_val[15:8];
        my_custom_hdr.f28 = write_val[7:0];
    }

    action write_offset_28 () {
        my_custom_hdr.f28 = write_val[15:8];
        my_custom_hdr.f29 = write_val[7:0];
    }

    action write_offset_29 () {
        my_custom_hdr.f29 = write_val[15:8];
        my_custom_hdr.f30 = write_val[7:0];
    }

    action write_offset_30 () {
        my_custom_hdr.f30 = write_val[15:8];
        my_custom_hdr.f31 = write_val[7:0];
    }

    action index_out_of_range () {
        index_in_range = false;
    }

    table write_to_index {
        key = {
            index : exact;
        }
        actions = {
            write_offset_0;
            write_offset_1;
            write_offset_2;
            write_offset_3;
            write_offset_4;
            write_offset_5;
            write_offset_6;
            write_offset_7;
            write_offset_8;
            write_offset_9;
            write_offset_10;
            write_offset_11;
            write_offset_12;
            write_offset_13;
            write_offset_14;
            write_offset_15;
            write_offset_16;
            write_offset_17;
            write_offset_18;
            write_offset_19;
            write_offset_20;
            write_offset_21;
            write_offset_22;
            write_offset_23;
            write_offset_24;
            write_offset_25;
            write_offset_26;
            write_offset_27;
            write_offset_28;
            write_offset_29;
            write_offset_30;
            @defaultonly index_out_of_range;
        }
        const entries = {
            0 : write_offset_0();
            1 : write_offset_1();
            2 : write_offset_2();
            3 : write_offset_3();
            4 : write_offset_4();
            5 : write_offset_5();
            6 : write_offset_6();
            7 : write_offset_7();
            8 : write_offset_8();
            9 : write_offset_9();
            10 : write_offset_10();
            11 : write_offset_11();
            12 : write_offset_12();
            13 : write_offset_13();
            14 : write_offset_14();
            15 : write_offset_15();
            16 : write_offset_16();
            17 : write_offset_17();
            18 : write_offset_18();
            19 : write_offset_19();
            20 : write_offset_20();
            21 : write_offset_21();
            22 : write_offset_22();
            23 : write_offset_23();
            24 : write_offset_24();
            25 : write_offset_25();
            26 : write_offset_26();
            27 : write_offset_27();
            28 : write_offset_28();
            29 : write_offset_29();
            30 : write_offset_30();
        }
        const default_action = index_out_of_range;
    }

    apply {
        index_in_range = true;
        write_to_index.apply();
    }
}
