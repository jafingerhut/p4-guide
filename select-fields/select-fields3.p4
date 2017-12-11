control Select8BitFields_4_to_2_select_one_field(
    in bit<32> data_in,
    in bit<2> sel,
    out bit<8> one_out_field)
{
    apply {
        if (sel == 3) {
            one_out_field = data_in[31:24];
        } else if (sel == 2) {
            one_out_field = data_in[23:16];
        } else if (sel == 1) {
            one_out_field = data_in[15:8];
        } else  {
            one_out_field = data_in[7:0];
        }
    }
}


control Select8BitFields_4_to_2_pure_function(
    in bit<32> data_in,
    in bit<4> select_control,
    out bit<16> data_out)
{
    bit<8> out1;
    bit<8> out0;
    Select8BitFields_4_to_2_select_one_field() sof;
    apply {
        sof.apply(data_in, select_control[3:2], out1);
        sof.apply(data_in, select_control[1:0], out0);
        data_out = (
            out1 ++
            out0
            );
    }
}


control Select8BitFields_4_to_2(
    in bit<32> data_in,
    out bit<16> data_out)
{
    Select8BitFields_4_to_2_pure_function() sf;
    bit<4> select_control;

    action get_sc(bit<4> sc) {
        select_control = sc;
    }
    table get_select_control {
        key = { }
        actions = { get_sc; }
        default_action = get_sc(0);
    }

    apply {
        get_select_control.apply();
        sf.apply(data_in, select_control, data_out);
    }
}
control Select8BitFields_4_to_3_select_one_field(
    in bit<32> data_in,
    in bit<2> sel,
    out bit<8> one_out_field)
{
    apply {
        if (sel == 3) {
            one_out_field = data_in[31:24];
        } else if (sel == 2) {
            one_out_field = data_in[23:16];
        } else if (sel == 1) {
            one_out_field = data_in[15:8];
        } else  {
            one_out_field = data_in[7:0];
        }
    }
}


control Select8BitFields_4_to_3_pure_function(
    in bit<32> data_in,
    in bit<6> select_control,
    out bit<24> data_out)
{
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;
    Select8BitFields_4_to_3_select_one_field() sof;
    apply {
        sof.apply(data_in, select_control[5:4], out2);
        sof.apply(data_in, select_control[3:2], out1);
        sof.apply(data_in, select_control[1:0], out0);
        data_out = (
            out2 ++
            out1 ++
            out0
            );
    }
}


control Select8BitFields_4_to_3(
    in bit<32> data_in,
    out bit<24> data_out)
{
    Select8BitFields_4_to_3_pure_function() sf;
    bit<6> select_control;

    action get_sc(bit<6> sc) {
        select_control = sc;
    }
    table get_select_control {
        key = { }
        actions = { get_sc; }
        default_action = get_sc(0);
    }

    apply {
        get_select_control.apply();
        sf.apply(data_in, select_control, data_out);
    }
}
control Select8BitFields_8_to_4_select_one_field(
    in bit<64> data_in,
    in bit<3> sel,
    out bit<8> one_out_field)
{
    apply {
        if (sel == 7) {
            one_out_field = data_in[63:56];
        } else if (sel == 6) {
            one_out_field = data_in[55:48];
        } else if (sel == 5) {
            one_out_field = data_in[47:40];
        } else if (sel == 4) {
            one_out_field = data_in[39:32];
        } else if (sel == 3) {
            one_out_field = data_in[31:24];
        } else if (sel == 2) {
            one_out_field = data_in[23:16];
        } else if (sel == 1) {
            one_out_field = data_in[15:8];
        } else  {
            one_out_field = data_in[7:0];
        }
    }
}


control Select8BitFields_8_to_4_pure_function(
    in bit<64> data_in,
    in bit<12> select_control,
    out bit<32> data_out)
{
    bit<8> out3;
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;
    Select8BitFields_8_to_4_select_one_field() sof;
    apply {
        sof.apply(data_in, select_control[11:9], out3);
        sof.apply(data_in, select_control[8:6], out2);
        sof.apply(data_in, select_control[5:3], out1);
        sof.apply(data_in, select_control[2:0], out0);
        data_out = (
            out3 ++
            out2 ++
            out1 ++
            out0
            );
    }
}


control Select8BitFields_8_to_4(
    in bit<64> data_in,
    out bit<32> data_out)
{
    Select8BitFields_8_to_4_pure_function() sf;
    bit<12> select_control;

    action get_sc(bit<12> sc) {
        select_control = sc;
    }
    table get_select_control {
        key = { }
        actions = { get_sc; }
        default_action = get_sc(0);
    }

    apply {
        get_select_control.apply();
        sf.apply(data_in, select_control, data_out);
    }
}
control Select8BitFields_8_to_6_select_one_field(
    in bit<64> data_in,
    in bit<3> sel,
    out bit<8> one_out_field)
{
    apply {
        if (sel == 7) {
            one_out_field = data_in[63:56];
        } else if (sel == 6) {
            one_out_field = data_in[55:48];
        } else if (sel == 5) {
            one_out_field = data_in[47:40];
        } else if (sel == 4) {
            one_out_field = data_in[39:32];
        } else if (sel == 3) {
            one_out_field = data_in[31:24];
        } else if (sel == 2) {
            one_out_field = data_in[23:16];
        } else if (sel == 1) {
            one_out_field = data_in[15:8];
        } else  {
            one_out_field = data_in[7:0];
        }
    }
}


control Select8BitFields_8_to_6_pure_function(
    in bit<64> data_in,
    in bit<18> select_control,
    out bit<48> data_out)
{
    bit<8> out5;
    bit<8> out4;
    bit<8> out3;
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;
    Select8BitFields_8_to_6_select_one_field() sof;
    apply {
        sof.apply(data_in, select_control[17:15], out5);
        sof.apply(data_in, select_control[14:12], out4);
        sof.apply(data_in, select_control[11:9], out3);
        sof.apply(data_in, select_control[8:6], out2);
        sof.apply(data_in, select_control[5:3], out1);
        sof.apply(data_in, select_control[2:0], out0);
        data_out = (
            out5 ++
            out4 ++
            out3 ++
            out2 ++
            out1 ++
            out0
            );
    }
}


control Select8BitFields_8_to_6(
    in bit<64> data_in,
    out bit<48> data_out)
{
    Select8BitFields_8_to_6_pure_function() sf;
    bit<18> select_control;

    action get_sc(bit<18> sc) {
        select_control = sc;
    }
    table get_select_control {
        key = { }
        actions = { get_sc; }
        default_action = get_sc(0);
    }

    apply {
        get_select_control.apply();
        sf.apply(data_in, select_control, data_out);
    }
}
control Select8BitFields_16_to_8_select_one_field(
    in bit<128> data_in,
    in bit<4> sel,
    out bit<8> one_out_field)
{
    apply {
        if (sel == 15) {
            one_out_field = data_in[127:120];
        } else if (sel == 14) {
            one_out_field = data_in[119:112];
        } else if (sel == 13) {
            one_out_field = data_in[111:104];
        } else if (sel == 12) {
            one_out_field = data_in[103:96];
        } else if (sel == 11) {
            one_out_field = data_in[95:88];
        } else if (sel == 10) {
            one_out_field = data_in[87:80];
        } else if (sel == 9) {
            one_out_field = data_in[79:72];
        } else if (sel == 8) {
            one_out_field = data_in[71:64];
        } else if (sel == 7) {
            one_out_field = data_in[63:56];
        } else if (sel == 6) {
            one_out_field = data_in[55:48];
        } else if (sel == 5) {
            one_out_field = data_in[47:40];
        } else if (sel == 4) {
            one_out_field = data_in[39:32];
        } else if (sel == 3) {
            one_out_field = data_in[31:24];
        } else if (sel == 2) {
            one_out_field = data_in[23:16];
        } else if (sel == 1) {
            one_out_field = data_in[15:8];
        } else  {
            one_out_field = data_in[7:0];
        }
    }
}


control Select8BitFields_16_to_8_pure_function(
    in bit<128> data_in,
    in bit<32> select_control,
    out bit<64> data_out)
{
    bit<8> out7;
    bit<8> out6;
    bit<8> out5;
    bit<8> out4;
    bit<8> out3;
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;
    Select8BitFields_16_to_8_select_one_field() sof;
    apply {
        sof.apply(data_in, select_control[31:28], out7);
        sof.apply(data_in, select_control[27:24], out6);
        sof.apply(data_in, select_control[23:20], out5);
        sof.apply(data_in, select_control[19:16], out4);
        sof.apply(data_in, select_control[15:12], out3);
        sof.apply(data_in, select_control[11:8], out2);
        sof.apply(data_in, select_control[7:4], out1);
        sof.apply(data_in, select_control[3:0], out0);
        data_out = (
            out7 ++
            out6 ++
            out5 ++
            out4 ++
            out3 ++
            out2 ++
            out1 ++
            out0
            );
    }
}


control Select8BitFields_16_to_8(
    in bit<128> data_in,
    out bit<64> data_out)
{
    Select8BitFields_16_to_8_pure_function() sf;
    bit<32> select_control;

    action get_sc(bit<32> sc) {
        select_control = sc;
    }
    table get_select_control {
        key = { }
        actions = { get_sc; }
        default_action = get_sc(0);
    }

    apply {
        get_select_control.apply();
        sf.apply(data_in, select_control, data_out);
    }
}
control Select8BitFields_16_to_12_select_one_field(
    in bit<128> data_in,
    in bit<4> sel,
    out bit<8> one_out_field)
{
    apply {
        if (sel == 15) {
            one_out_field = data_in[127:120];
        } else if (sel == 14) {
            one_out_field = data_in[119:112];
        } else if (sel == 13) {
            one_out_field = data_in[111:104];
        } else if (sel == 12) {
            one_out_field = data_in[103:96];
        } else if (sel == 11) {
            one_out_field = data_in[95:88];
        } else if (sel == 10) {
            one_out_field = data_in[87:80];
        } else if (sel == 9) {
            one_out_field = data_in[79:72];
        } else if (sel == 8) {
            one_out_field = data_in[71:64];
        } else if (sel == 7) {
            one_out_field = data_in[63:56];
        } else if (sel == 6) {
            one_out_field = data_in[55:48];
        } else if (sel == 5) {
            one_out_field = data_in[47:40];
        } else if (sel == 4) {
            one_out_field = data_in[39:32];
        } else if (sel == 3) {
            one_out_field = data_in[31:24];
        } else if (sel == 2) {
            one_out_field = data_in[23:16];
        } else if (sel == 1) {
            one_out_field = data_in[15:8];
        } else  {
            one_out_field = data_in[7:0];
        }
    }
}


control Select8BitFields_16_to_12_pure_function(
    in bit<128> data_in,
    in bit<48> select_control,
    out bit<96> data_out)
{
    bit<8> out11;
    bit<8> out10;
    bit<8> out9;
    bit<8> out8;
    bit<8> out7;
    bit<8> out6;
    bit<8> out5;
    bit<8> out4;
    bit<8> out3;
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;
    Select8BitFields_16_to_12_select_one_field() sof;
    apply {
        sof.apply(data_in, select_control[47:44], out11);
        sof.apply(data_in, select_control[43:40], out10);
        sof.apply(data_in, select_control[39:36], out9);
        sof.apply(data_in, select_control[35:32], out8);
        sof.apply(data_in, select_control[31:28], out7);
        sof.apply(data_in, select_control[27:24], out6);
        sof.apply(data_in, select_control[23:20], out5);
        sof.apply(data_in, select_control[19:16], out4);
        sof.apply(data_in, select_control[15:12], out3);
        sof.apply(data_in, select_control[11:8], out2);
        sof.apply(data_in, select_control[7:4], out1);
        sof.apply(data_in, select_control[3:0], out0);
        data_out = (
            out11 ++
            out10 ++
            out9 ++
            out8 ++
            out7 ++
            out6 ++
            out5 ++
            out4 ++
            out3 ++
            out2 ++
            out1 ++
            out0
            );
    }
}


control Select8BitFields_16_to_12(
    in bit<128> data_in,
    out bit<96> data_out)
{
    Select8BitFields_16_to_12_pure_function() sf;
    bit<48> select_control;

    action get_sc(bit<48> sc) {
        select_control = sc;
    }
    table get_select_control {
        key = { }
        actions = { get_sc; }
        default_action = get_sc(0);
    }

    apply {
        get_select_control.apply();
        sf.apply(data_in, select_control, data_out);
    }
}
control Select8BitFields_24_to_12_select_one_field(
    in bit<192> data_in,
    in bit<5> sel,
    out bit<8> one_out_field)
{
    apply {
        if (sel == 23) {
            one_out_field = data_in[191:184];
        } else if (sel == 22) {
            one_out_field = data_in[183:176];
        } else if (sel == 21) {
            one_out_field = data_in[175:168];
        } else if (sel == 20) {
            one_out_field = data_in[167:160];
        } else if (sel == 19) {
            one_out_field = data_in[159:152];
        } else if (sel == 18) {
            one_out_field = data_in[151:144];
        } else if (sel == 17) {
            one_out_field = data_in[143:136];
        } else if (sel == 16) {
            one_out_field = data_in[135:128];
        } else if (sel == 15) {
            one_out_field = data_in[127:120];
        } else if (sel == 14) {
            one_out_field = data_in[119:112];
        } else if (sel == 13) {
            one_out_field = data_in[111:104];
        } else if (sel == 12) {
            one_out_field = data_in[103:96];
        } else if (sel == 11) {
            one_out_field = data_in[95:88];
        } else if (sel == 10) {
            one_out_field = data_in[87:80];
        } else if (sel == 9) {
            one_out_field = data_in[79:72];
        } else if (sel == 8) {
            one_out_field = data_in[71:64];
        } else if (sel == 7) {
            one_out_field = data_in[63:56];
        } else if (sel == 6) {
            one_out_field = data_in[55:48];
        } else if (sel == 5) {
            one_out_field = data_in[47:40];
        } else if (sel == 4) {
            one_out_field = data_in[39:32];
        } else if (sel == 3) {
            one_out_field = data_in[31:24];
        } else if (sel == 2) {
            one_out_field = data_in[23:16];
        } else if (sel == 1) {
            one_out_field = data_in[15:8];
        } else  {
            one_out_field = data_in[7:0];
        }
    }
}


control Select8BitFields_24_to_12_pure_function(
    in bit<192> data_in,
    in bit<60> select_control,
    out bit<96> data_out)
{
    bit<8> out11;
    bit<8> out10;
    bit<8> out9;
    bit<8> out8;
    bit<8> out7;
    bit<8> out6;
    bit<8> out5;
    bit<8> out4;
    bit<8> out3;
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;
    Select8BitFields_24_to_12_select_one_field() sof;
    apply {
        sof.apply(data_in, select_control[59:55], out11);
        sof.apply(data_in, select_control[54:50], out10);
        sof.apply(data_in, select_control[49:45], out9);
        sof.apply(data_in, select_control[44:40], out8);
        sof.apply(data_in, select_control[39:35], out7);
        sof.apply(data_in, select_control[34:30], out6);
        sof.apply(data_in, select_control[29:25], out5);
        sof.apply(data_in, select_control[24:20], out4);
        sof.apply(data_in, select_control[19:15], out3);
        sof.apply(data_in, select_control[14:10], out2);
        sof.apply(data_in, select_control[9:5], out1);
        sof.apply(data_in, select_control[4:0], out0);
        data_out = (
            out11 ++
            out10 ++
            out9 ++
            out8 ++
            out7 ++
            out6 ++
            out5 ++
            out4 ++
            out3 ++
            out2 ++
            out1 ++
            out0
            );
    }
}


control Select8BitFields_24_to_12(
    in bit<192> data_in,
    out bit<96> data_out)
{
    Select8BitFields_24_to_12_pure_function() sf;
    bit<60> select_control;

    action get_sc(bit<60> sc) {
        select_control = sc;
    }
    table get_select_control {
        key = { }
        actions = { get_sc; }
        default_action = get_sc(0);
    }

    apply {
        get_select_control.apply();
        sf.apply(data_in, select_control, data_out);
    }
}
control Select8BitFields_24_to_18_select_one_field(
    in bit<192> data_in,
    in bit<5> sel,
    out bit<8> one_out_field)
{
    apply {
        if (sel == 23) {
            one_out_field = data_in[191:184];
        } else if (sel == 22) {
            one_out_field = data_in[183:176];
        } else if (sel == 21) {
            one_out_field = data_in[175:168];
        } else if (sel == 20) {
            one_out_field = data_in[167:160];
        } else if (sel == 19) {
            one_out_field = data_in[159:152];
        } else if (sel == 18) {
            one_out_field = data_in[151:144];
        } else if (sel == 17) {
            one_out_field = data_in[143:136];
        } else if (sel == 16) {
            one_out_field = data_in[135:128];
        } else if (sel == 15) {
            one_out_field = data_in[127:120];
        } else if (sel == 14) {
            one_out_field = data_in[119:112];
        } else if (sel == 13) {
            one_out_field = data_in[111:104];
        } else if (sel == 12) {
            one_out_field = data_in[103:96];
        } else if (sel == 11) {
            one_out_field = data_in[95:88];
        } else if (sel == 10) {
            one_out_field = data_in[87:80];
        } else if (sel == 9) {
            one_out_field = data_in[79:72];
        } else if (sel == 8) {
            one_out_field = data_in[71:64];
        } else if (sel == 7) {
            one_out_field = data_in[63:56];
        } else if (sel == 6) {
            one_out_field = data_in[55:48];
        } else if (sel == 5) {
            one_out_field = data_in[47:40];
        } else if (sel == 4) {
            one_out_field = data_in[39:32];
        } else if (sel == 3) {
            one_out_field = data_in[31:24];
        } else if (sel == 2) {
            one_out_field = data_in[23:16];
        } else if (sel == 1) {
            one_out_field = data_in[15:8];
        } else  {
            one_out_field = data_in[7:0];
        }
    }
}


control Select8BitFields_24_to_18_pure_function(
    in bit<192> data_in,
    in bit<90> select_control,
    out bit<144> data_out)
{
    bit<8> out17;
    bit<8> out16;
    bit<8> out15;
    bit<8> out14;
    bit<8> out13;
    bit<8> out12;
    bit<8> out11;
    bit<8> out10;
    bit<8> out9;
    bit<8> out8;
    bit<8> out7;
    bit<8> out6;
    bit<8> out5;
    bit<8> out4;
    bit<8> out3;
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;
    Select8BitFields_24_to_18_select_one_field() sof;
    apply {
        sof.apply(data_in, select_control[89:85], out17);
        sof.apply(data_in, select_control[84:80], out16);
        sof.apply(data_in, select_control[79:75], out15);
        sof.apply(data_in, select_control[74:70], out14);
        sof.apply(data_in, select_control[69:65], out13);
        sof.apply(data_in, select_control[64:60], out12);
        sof.apply(data_in, select_control[59:55], out11);
        sof.apply(data_in, select_control[54:50], out10);
        sof.apply(data_in, select_control[49:45], out9);
        sof.apply(data_in, select_control[44:40], out8);
        sof.apply(data_in, select_control[39:35], out7);
        sof.apply(data_in, select_control[34:30], out6);
        sof.apply(data_in, select_control[29:25], out5);
        sof.apply(data_in, select_control[24:20], out4);
        sof.apply(data_in, select_control[19:15], out3);
        sof.apply(data_in, select_control[14:10], out2);
        sof.apply(data_in, select_control[9:5], out1);
        sof.apply(data_in, select_control[4:0], out0);
        data_out = (
            out17 ++
            out16 ++
            out15 ++
            out14 ++
            out13 ++
            out12 ++
            out11 ++
            out10 ++
            out9 ++
            out8 ++
            out7 ++
            out6 ++
            out5 ++
            out4 ++
            out3 ++
            out2 ++
            out1 ++
            out0
            );
    }
}


control Select8BitFields_24_to_18(
    in bit<192> data_in,
    out bit<144> data_out)
{
    Select8BitFields_24_to_18_pure_function() sf;
    bit<90> select_control;

    action get_sc(bit<90> sc) {
        select_control = sc;
    }
    table get_select_control {
        key = { }
        actions = { get_sc; }
        default_action = get_sc(0);
    }

    apply {
        get_select_control.apply();
        sf.apply(data_in, select_control, data_out);
    }
}
control Select8BitFields_32_to_16_select_one_field(
    in bit<256> data_in,
    in bit<5> sel,
    out bit<8> one_out_field)
{
    apply {
        if (sel == 31) {
            one_out_field = data_in[255:248];
        } else if (sel == 30) {
            one_out_field = data_in[247:240];
        } else if (sel == 29) {
            one_out_field = data_in[239:232];
        } else if (sel == 28) {
            one_out_field = data_in[231:224];
        } else if (sel == 27) {
            one_out_field = data_in[223:216];
        } else if (sel == 26) {
            one_out_field = data_in[215:208];
        } else if (sel == 25) {
            one_out_field = data_in[207:200];
        } else if (sel == 24) {
            one_out_field = data_in[199:192];
        } else if (sel == 23) {
            one_out_field = data_in[191:184];
        } else if (sel == 22) {
            one_out_field = data_in[183:176];
        } else if (sel == 21) {
            one_out_field = data_in[175:168];
        } else if (sel == 20) {
            one_out_field = data_in[167:160];
        } else if (sel == 19) {
            one_out_field = data_in[159:152];
        } else if (sel == 18) {
            one_out_field = data_in[151:144];
        } else if (sel == 17) {
            one_out_field = data_in[143:136];
        } else if (sel == 16) {
            one_out_field = data_in[135:128];
        } else if (sel == 15) {
            one_out_field = data_in[127:120];
        } else if (sel == 14) {
            one_out_field = data_in[119:112];
        } else if (sel == 13) {
            one_out_field = data_in[111:104];
        } else if (sel == 12) {
            one_out_field = data_in[103:96];
        } else if (sel == 11) {
            one_out_field = data_in[95:88];
        } else if (sel == 10) {
            one_out_field = data_in[87:80];
        } else if (sel == 9) {
            one_out_field = data_in[79:72];
        } else if (sel == 8) {
            one_out_field = data_in[71:64];
        } else if (sel == 7) {
            one_out_field = data_in[63:56];
        } else if (sel == 6) {
            one_out_field = data_in[55:48];
        } else if (sel == 5) {
            one_out_field = data_in[47:40];
        } else if (sel == 4) {
            one_out_field = data_in[39:32];
        } else if (sel == 3) {
            one_out_field = data_in[31:24];
        } else if (sel == 2) {
            one_out_field = data_in[23:16];
        } else if (sel == 1) {
            one_out_field = data_in[15:8];
        } else  {
            one_out_field = data_in[7:0];
        }
    }
}


control Select8BitFields_32_to_16_pure_function(
    in bit<256> data_in,
    in bit<80> select_control,
    out bit<128> data_out)
{
    bit<8> out15;
    bit<8> out14;
    bit<8> out13;
    bit<8> out12;
    bit<8> out11;
    bit<8> out10;
    bit<8> out9;
    bit<8> out8;
    bit<8> out7;
    bit<8> out6;
    bit<8> out5;
    bit<8> out4;
    bit<8> out3;
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;
    Select8BitFields_32_to_16_select_one_field() sof;
    apply {
        sof.apply(data_in, select_control[79:75], out15);
        sof.apply(data_in, select_control[74:70], out14);
        sof.apply(data_in, select_control[69:65], out13);
        sof.apply(data_in, select_control[64:60], out12);
        sof.apply(data_in, select_control[59:55], out11);
        sof.apply(data_in, select_control[54:50], out10);
        sof.apply(data_in, select_control[49:45], out9);
        sof.apply(data_in, select_control[44:40], out8);
        sof.apply(data_in, select_control[39:35], out7);
        sof.apply(data_in, select_control[34:30], out6);
        sof.apply(data_in, select_control[29:25], out5);
        sof.apply(data_in, select_control[24:20], out4);
        sof.apply(data_in, select_control[19:15], out3);
        sof.apply(data_in, select_control[14:10], out2);
        sof.apply(data_in, select_control[9:5], out1);
        sof.apply(data_in, select_control[4:0], out0);
        data_out = (
            out15 ++
            out14 ++
            out13 ++
            out12 ++
            out11 ++
            out10 ++
            out9 ++
            out8 ++
            out7 ++
            out6 ++
            out5 ++
            out4 ++
            out3 ++
            out2 ++
            out1 ++
            out0
            );
    }
}


control Select8BitFields_32_to_16(
    in bit<256> data_in,
    out bit<128> data_out)
{
    Select8BitFields_32_to_16_pure_function() sf;
    bit<80> select_control;

    action get_sc(bit<80> sc) {
        select_control = sc;
    }
    table get_select_control {
        key = { }
        actions = { get_sc; }
        default_action = get_sc(0);
    }

    apply {
        get_select_control.apply();
        sf.apply(data_in, select_control, data_out);
    }
}
control Select8BitFields_32_to_24_select_one_field(
    in bit<256> data_in,
    in bit<5> sel,
    out bit<8> one_out_field)
{
    apply {
        if (sel == 31) {
            one_out_field = data_in[255:248];
        } else if (sel == 30) {
            one_out_field = data_in[247:240];
        } else if (sel == 29) {
            one_out_field = data_in[239:232];
        } else if (sel == 28) {
            one_out_field = data_in[231:224];
        } else if (sel == 27) {
            one_out_field = data_in[223:216];
        } else if (sel == 26) {
            one_out_field = data_in[215:208];
        } else if (sel == 25) {
            one_out_field = data_in[207:200];
        } else if (sel == 24) {
            one_out_field = data_in[199:192];
        } else if (sel == 23) {
            one_out_field = data_in[191:184];
        } else if (sel == 22) {
            one_out_field = data_in[183:176];
        } else if (sel == 21) {
            one_out_field = data_in[175:168];
        } else if (sel == 20) {
            one_out_field = data_in[167:160];
        } else if (sel == 19) {
            one_out_field = data_in[159:152];
        } else if (sel == 18) {
            one_out_field = data_in[151:144];
        } else if (sel == 17) {
            one_out_field = data_in[143:136];
        } else if (sel == 16) {
            one_out_field = data_in[135:128];
        } else if (sel == 15) {
            one_out_field = data_in[127:120];
        } else if (sel == 14) {
            one_out_field = data_in[119:112];
        } else if (sel == 13) {
            one_out_field = data_in[111:104];
        } else if (sel == 12) {
            one_out_field = data_in[103:96];
        } else if (sel == 11) {
            one_out_field = data_in[95:88];
        } else if (sel == 10) {
            one_out_field = data_in[87:80];
        } else if (sel == 9) {
            one_out_field = data_in[79:72];
        } else if (sel == 8) {
            one_out_field = data_in[71:64];
        } else if (sel == 7) {
            one_out_field = data_in[63:56];
        } else if (sel == 6) {
            one_out_field = data_in[55:48];
        } else if (sel == 5) {
            one_out_field = data_in[47:40];
        } else if (sel == 4) {
            one_out_field = data_in[39:32];
        } else if (sel == 3) {
            one_out_field = data_in[31:24];
        } else if (sel == 2) {
            one_out_field = data_in[23:16];
        } else if (sel == 1) {
            one_out_field = data_in[15:8];
        } else  {
            one_out_field = data_in[7:0];
        }
    }
}


control Select8BitFields_32_to_24_pure_function(
    in bit<256> data_in,
    in bit<120> select_control,
    out bit<192> data_out)
{
    bit<8> out23;
    bit<8> out22;
    bit<8> out21;
    bit<8> out20;
    bit<8> out19;
    bit<8> out18;
    bit<8> out17;
    bit<8> out16;
    bit<8> out15;
    bit<8> out14;
    bit<8> out13;
    bit<8> out12;
    bit<8> out11;
    bit<8> out10;
    bit<8> out9;
    bit<8> out8;
    bit<8> out7;
    bit<8> out6;
    bit<8> out5;
    bit<8> out4;
    bit<8> out3;
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;
    Select8BitFields_32_to_24_select_one_field() sof;
    apply {
        sof.apply(data_in, select_control[119:115], out23);
        sof.apply(data_in, select_control[114:110], out22);
        sof.apply(data_in, select_control[109:105], out21);
        sof.apply(data_in, select_control[104:100], out20);
        sof.apply(data_in, select_control[99:95], out19);
        sof.apply(data_in, select_control[94:90], out18);
        sof.apply(data_in, select_control[89:85], out17);
        sof.apply(data_in, select_control[84:80], out16);
        sof.apply(data_in, select_control[79:75], out15);
        sof.apply(data_in, select_control[74:70], out14);
        sof.apply(data_in, select_control[69:65], out13);
        sof.apply(data_in, select_control[64:60], out12);
        sof.apply(data_in, select_control[59:55], out11);
        sof.apply(data_in, select_control[54:50], out10);
        sof.apply(data_in, select_control[49:45], out9);
        sof.apply(data_in, select_control[44:40], out8);
        sof.apply(data_in, select_control[39:35], out7);
        sof.apply(data_in, select_control[34:30], out6);
        sof.apply(data_in, select_control[29:25], out5);
        sof.apply(data_in, select_control[24:20], out4);
        sof.apply(data_in, select_control[19:15], out3);
        sof.apply(data_in, select_control[14:10], out2);
        sof.apply(data_in, select_control[9:5], out1);
        sof.apply(data_in, select_control[4:0], out0);
        data_out = (
            out23 ++
            out22 ++
            out21 ++
            out20 ++
            out19 ++
            out18 ++
            out17 ++
            out16 ++
            out15 ++
            out14 ++
            out13 ++
            out12 ++
            out11 ++
            out10 ++
            out9 ++
            out8 ++
            out7 ++
            out6 ++
            out5 ++
            out4 ++
            out3 ++
            out2 ++
            out1 ++
            out0
            );
    }
}


control Select8BitFields_32_to_24(
    in bit<256> data_in,
    out bit<192> data_out)
{
    Select8BitFields_32_to_24_pure_function() sf;
    bit<120> select_control;

    action get_sc(bit<120> sc) {
        select_control = sc;
    }
    table get_select_control {
        key = { }
        actions = { get_sc; }
        default_action = get_sc(0);
    }

    apply {
        get_select_control.apply();
        sf.apply(data_in, select_control, data_out);
    }
}
