control Select8BitFields_4_to_2_pure_function(
    in bit<32> data_in,
    in bit<4> select_control,
    out bit<16> data_out)
{
    bit<8> out1;
    bit<8> out0;

    apply {
        if (select_control[3:2] == 3) {
            out1 = data_in[31:24];
        } else if (select_control[3:2] == 2) {
            out1 = data_in[23:16];
        } else if (select_control[3:2] == 1) {
            out1 = data_in[15:8];
        } else  {
            out1 = data_in[7:0];
        }
        if (select_control[1:0] == 3) {
            out0 = data_in[31:24];
        } else if (select_control[1:0] == 2) {
            out0 = data_in[23:16];
        } else if (select_control[1:0] == 1) {
            out0 = data_in[15:8];
        } else  {
            out0 = data_in[7:0];
        }

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
control Select8BitFields_4_to_3_pure_function(
    in bit<32> data_in,
    in bit<6> select_control,
    out bit<24> data_out)
{
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;

    apply {
        if (select_control[5:4] == 3) {
            out2 = data_in[31:24];
        } else if (select_control[5:4] == 2) {
            out2 = data_in[23:16];
        } else if (select_control[5:4] == 1) {
            out2 = data_in[15:8];
        } else  {
            out2 = data_in[7:0];
        }
        if (select_control[3:2] == 3) {
            out1 = data_in[31:24];
        } else if (select_control[3:2] == 2) {
            out1 = data_in[23:16];
        } else if (select_control[3:2] == 1) {
            out1 = data_in[15:8];
        } else  {
            out1 = data_in[7:0];
        }
        if (select_control[1:0] == 3) {
            out0 = data_in[31:24];
        } else if (select_control[1:0] == 2) {
            out0 = data_in[23:16];
        } else if (select_control[1:0] == 1) {
            out0 = data_in[15:8];
        } else  {
            out0 = data_in[7:0];
        }

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
control Select8BitFields_8_to_4_pure_function(
    in bit<64> data_in,
    in bit<12> select_control,
    out bit<32> data_out)
{
    bit<8> out3;
    bit<8> out2;
    bit<8> out1;
    bit<8> out0;

    apply {
        if (select_control[11:9] == 7) {
            out3 = data_in[63:56];
        } else if (select_control[11:9] == 6) {
            out3 = data_in[55:48];
        } else if (select_control[11:9] == 5) {
            out3 = data_in[47:40];
        } else if (select_control[11:9] == 4) {
            out3 = data_in[39:32];
        } else if (select_control[11:9] == 3) {
            out3 = data_in[31:24];
        } else if (select_control[11:9] == 2) {
            out3 = data_in[23:16];
        } else if (select_control[11:9] == 1) {
            out3 = data_in[15:8];
        } else  {
            out3 = data_in[7:0];
        }
        if (select_control[8:6] == 7) {
            out2 = data_in[63:56];
        } else if (select_control[8:6] == 6) {
            out2 = data_in[55:48];
        } else if (select_control[8:6] == 5) {
            out2 = data_in[47:40];
        } else if (select_control[8:6] == 4) {
            out2 = data_in[39:32];
        } else if (select_control[8:6] == 3) {
            out2 = data_in[31:24];
        } else if (select_control[8:6] == 2) {
            out2 = data_in[23:16];
        } else if (select_control[8:6] == 1) {
            out2 = data_in[15:8];
        } else  {
            out2 = data_in[7:0];
        }
        if (select_control[5:3] == 7) {
            out1 = data_in[63:56];
        } else if (select_control[5:3] == 6) {
            out1 = data_in[55:48];
        } else if (select_control[5:3] == 5) {
            out1 = data_in[47:40];
        } else if (select_control[5:3] == 4) {
            out1 = data_in[39:32];
        } else if (select_control[5:3] == 3) {
            out1 = data_in[31:24];
        } else if (select_control[5:3] == 2) {
            out1 = data_in[23:16];
        } else if (select_control[5:3] == 1) {
            out1 = data_in[15:8];
        } else  {
            out1 = data_in[7:0];
        }
        if (select_control[2:0] == 7) {
            out0 = data_in[63:56];
        } else if (select_control[2:0] == 6) {
            out0 = data_in[55:48];
        } else if (select_control[2:0] == 5) {
            out0 = data_in[47:40];
        } else if (select_control[2:0] == 4) {
            out0 = data_in[39:32];
        } else if (select_control[2:0] == 3) {
            out0 = data_in[31:24];
        } else if (select_control[2:0] == 2) {
            out0 = data_in[23:16];
        } else if (select_control[2:0] == 1) {
            out0 = data_in[15:8];
        } else  {
            out0 = data_in[7:0];
        }

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

    apply {
        if (select_control[17:15] == 7) {
            out5 = data_in[63:56];
        } else if (select_control[17:15] == 6) {
            out5 = data_in[55:48];
        } else if (select_control[17:15] == 5) {
            out5 = data_in[47:40];
        } else if (select_control[17:15] == 4) {
            out5 = data_in[39:32];
        } else if (select_control[17:15] == 3) {
            out5 = data_in[31:24];
        } else if (select_control[17:15] == 2) {
            out5 = data_in[23:16];
        } else if (select_control[17:15] == 1) {
            out5 = data_in[15:8];
        } else  {
            out5 = data_in[7:0];
        }
        if (select_control[14:12] == 7) {
            out4 = data_in[63:56];
        } else if (select_control[14:12] == 6) {
            out4 = data_in[55:48];
        } else if (select_control[14:12] == 5) {
            out4 = data_in[47:40];
        } else if (select_control[14:12] == 4) {
            out4 = data_in[39:32];
        } else if (select_control[14:12] == 3) {
            out4 = data_in[31:24];
        } else if (select_control[14:12] == 2) {
            out4 = data_in[23:16];
        } else if (select_control[14:12] == 1) {
            out4 = data_in[15:8];
        } else  {
            out4 = data_in[7:0];
        }
        if (select_control[11:9] == 7) {
            out3 = data_in[63:56];
        } else if (select_control[11:9] == 6) {
            out3 = data_in[55:48];
        } else if (select_control[11:9] == 5) {
            out3 = data_in[47:40];
        } else if (select_control[11:9] == 4) {
            out3 = data_in[39:32];
        } else if (select_control[11:9] == 3) {
            out3 = data_in[31:24];
        } else if (select_control[11:9] == 2) {
            out3 = data_in[23:16];
        } else if (select_control[11:9] == 1) {
            out3 = data_in[15:8];
        } else  {
            out3 = data_in[7:0];
        }
        if (select_control[8:6] == 7) {
            out2 = data_in[63:56];
        } else if (select_control[8:6] == 6) {
            out2 = data_in[55:48];
        } else if (select_control[8:6] == 5) {
            out2 = data_in[47:40];
        } else if (select_control[8:6] == 4) {
            out2 = data_in[39:32];
        } else if (select_control[8:6] == 3) {
            out2 = data_in[31:24];
        } else if (select_control[8:6] == 2) {
            out2 = data_in[23:16];
        } else if (select_control[8:6] == 1) {
            out2 = data_in[15:8];
        } else  {
            out2 = data_in[7:0];
        }
        if (select_control[5:3] == 7) {
            out1 = data_in[63:56];
        } else if (select_control[5:3] == 6) {
            out1 = data_in[55:48];
        } else if (select_control[5:3] == 5) {
            out1 = data_in[47:40];
        } else if (select_control[5:3] == 4) {
            out1 = data_in[39:32];
        } else if (select_control[5:3] == 3) {
            out1 = data_in[31:24];
        } else if (select_control[5:3] == 2) {
            out1 = data_in[23:16];
        } else if (select_control[5:3] == 1) {
            out1 = data_in[15:8];
        } else  {
            out1 = data_in[7:0];
        }
        if (select_control[2:0] == 7) {
            out0 = data_in[63:56];
        } else if (select_control[2:0] == 6) {
            out0 = data_in[55:48];
        } else if (select_control[2:0] == 5) {
            out0 = data_in[47:40];
        } else if (select_control[2:0] == 4) {
            out0 = data_in[39:32];
        } else if (select_control[2:0] == 3) {
            out0 = data_in[31:24];
        } else if (select_control[2:0] == 2) {
            out0 = data_in[23:16];
        } else if (select_control[2:0] == 1) {
            out0 = data_in[15:8];
        } else  {
            out0 = data_in[7:0];
        }

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

    apply {
        if (select_control[31:28] == 15) {
            out7 = data_in[127:120];
        } else if (select_control[31:28] == 14) {
            out7 = data_in[119:112];
        } else if (select_control[31:28] == 13) {
            out7 = data_in[111:104];
        } else if (select_control[31:28] == 12) {
            out7 = data_in[103:96];
        } else if (select_control[31:28] == 11) {
            out7 = data_in[95:88];
        } else if (select_control[31:28] == 10) {
            out7 = data_in[87:80];
        } else if (select_control[31:28] == 9) {
            out7 = data_in[79:72];
        } else if (select_control[31:28] == 8) {
            out7 = data_in[71:64];
        } else if (select_control[31:28] == 7) {
            out7 = data_in[63:56];
        } else if (select_control[31:28] == 6) {
            out7 = data_in[55:48];
        } else if (select_control[31:28] == 5) {
            out7 = data_in[47:40];
        } else if (select_control[31:28] == 4) {
            out7 = data_in[39:32];
        } else if (select_control[31:28] == 3) {
            out7 = data_in[31:24];
        } else if (select_control[31:28] == 2) {
            out7 = data_in[23:16];
        } else if (select_control[31:28] == 1) {
            out7 = data_in[15:8];
        } else  {
            out7 = data_in[7:0];
        }
        if (select_control[27:24] == 15) {
            out6 = data_in[127:120];
        } else if (select_control[27:24] == 14) {
            out6 = data_in[119:112];
        } else if (select_control[27:24] == 13) {
            out6 = data_in[111:104];
        } else if (select_control[27:24] == 12) {
            out6 = data_in[103:96];
        } else if (select_control[27:24] == 11) {
            out6 = data_in[95:88];
        } else if (select_control[27:24] == 10) {
            out6 = data_in[87:80];
        } else if (select_control[27:24] == 9) {
            out6 = data_in[79:72];
        } else if (select_control[27:24] == 8) {
            out6 = data_in[71:64];
        } else if (select_control[27:24] == 7) {
            out6 = data_in[63:56];
        } else if (select_control[27:24] == 6) {
            out6 = data_in[55:48];
        } else if (select_control[27:24] == 5) {
            out6 = data_in[47:40];
        } else if (select_control[27:24] == 4) {
            out6 = data_in[39:32];
        } else if (select_control[27:24] == 3) {
            out6 = data_in[31:24];
        } else if (select_control[27:24] == 2) {
            out6 = data_in[23:16];
        } else if (select_control[27:24] == 1) {
            out6 = data_in[15:8];
        } else  {
            out6 = data_in[7:0];
        }
        if (select_control[23:20] == 15) {
            out5 = data_in[127:120];
        } else if (select_control[23:20] == 14) {
            out5 = data_in[119:112];
        } else if (select_control[23:20] == 13) {
            out5 = data_in[111:104];
        } else if (select_control[23:20] == 12) {
            out5 = data_in[103:96];
        } else if (select_control[23:20] == 11) {
            out5 = data_in[95:88];
        } else if (select_control[23:20] == 10) {
            out5 = data_in[87:80];
        } else if (select_control[23:20] == 9) {
            out5 = data_in[79:72];
        } else if (select_control[23:20] == 8) {
            out5 = data_in[71:64];
        } else if (select_control[23:20] == 7) {
            out5 = data_in[63:56];
        } else if (select_control[23:20] == 6) {
            out5 = data_in[55:48];
        } else if (select_control[23:20] == 5) {
            out5 = data_in[47:40];
        } else if (select_control[23:20] == 4) {
            out5 = data_in[39:32];
        } else if (select_control[23:20] == 3) {
            out5 = data_in[31:24];
        } else if (select_control[23:20] == 2) {
            out5 = data_in[23:16];
        } else if (select_control[23:20] == 1) {
            out5 = data_in[15:8];
        } else  {
            out5 = data_in[7:0];
        }
        if (select_control[19:16] == 15) {
            out4 = data_in[127:120];
        } else if (select_control[19:16] == 14) {
            out4 = data_in[119:112];
        } else if (select_control[19:16] == 13) {
            out4 = data_in[111:104];
        } else if (select_control[19:16] == 12) {
            out4 = data_in[103:96];
        } else if (select_control[19:16] == 11) {
            out4 = data_in[95:88];
        } else if (select_control[19:16] == 10) {
            out4 = data_in[87:80];
        } else if (select_control[19:16] == 9) {
            out4 = data_in[79:72];
        } else if (select_control[19:16] == 8) {
            out4 = data_in[71:64];
        } else if (select_control[19:16] == 7) {
            out4 = data_in[63:56];
        } else if (select_control[19:16] == 6) {
            out4 = data_in[55:48];
        } else if (select_control[19:16] == 5) {
            out4 = data_in[47:40];
        } else if (select_control[19:16] == 4) {
            out4 = data_in[39:32];
        } else if (select_control[19:16] == 3) {
            out4 = data_in[31:24];
        } else if (select_control[19:16] == 2) {
            out4 = data_in[23:16];
        } else if (select_control[19:16] == 1) {
            out4 = data_in[15:8];
        } else  {
            out4 = data_in[7:0];
        }
        if (select_control[15:12] == 15) {
            out3 = data_in[127:120];
        } else if (select_control[15:12] == 14) {
            out3 = data_in[119:112];
        } else if (select_control[15:12] == 13) {
            out3 = data_in[111:104];
        } else if (select_control[15:12] == 12) {
            out3 = data_in[103:96];
        } else if (select_control[15:12] == 11) {
            out3 = data_in[95:88];
        } else if (select_control[15:12] == 10) {
            out3 = data_in[87:80];
        } else if (select_control[15:12] == 9) {
            out3 = data_in[79:72];
        } else if (select_control[15:12] == 8) {
            out3 = data_in[71:64];
        } else if (select_control[15:12] == 7) {
            out3 = data_in[63:56];
        } else if (select_control[15:12] == 6) {
            out3 = data_in[55:48];
        } else if (select_control[15:12] == 5) {
            out3 = data_in[47:40];
        } else if (select_control[15:12] == 4) {
            out3 = data_in[39:32];
        } else if (select_control[15:12] == 3) {
            out3 = data_in[31:24];
        } else if (select_control[15:12] == 2) {
            out3 = data_in[23:16];
        } else if (select_control[15:12] == 1) {
            out3 = data_in[15:8];
        } else  {
            out3 = data_in[7:0];
        }
        if (select_control[11:8] == 15) {
            out2 = data_in[127:120];
        } else if (select_control[11:8] == 14) {
            out2 = data_in[119:112];
        } else if (select_control[11:8] == 13) {
            out2 = data_in[111:104];
        } else if (select_control[11:8] == 12) {
            out2 = data_in[103:96];
        } else if (select_control[11:8] == 11) {
            out2 = data_in[95:88];
        } else if (select_control[11:8] == 10) {
            out2 = data_in[87:80];
        } else if (select_control[11:8] == 9) {
            out2 = data_in[79:72];
        } else if (select_control[11:8] == 8) {
            out2 = data_in[71:64];
        } else if (select_control[11:8] == 7) {
            out2 = data_in[63:56];
        } else if (select_control[11:8] == 6) {
            out2 = data_in[55:48];
        } else if (select_control[11:8] == 5) {
            out2 = data_in[47:40];
        } else if (select_control[11:8] == 4) {
            out2 = data_in[39:32];
        } else if (select_control[11:8] == 3) {
            out2 = data_in[31:24];
        } else if (select_control[11:8] == 2) {
            out2 = data_in[23:16];
        } else if (select_control[11:8] == 1) {
            out2 = data_in[15:8];
        } else  {
            out2 = data_in[7:0];
        }
        if (select_control[7:4] == 15) {
            out1 = data_in[127:120];
        } else if (select_control[7:4] == 14) {
            out1 = data_in[119:112];
        } else if (select_control[7:4] == 13) {
            out1 = data_in[111:104];
        } else if (select_control[7:4] == 12) {
            out1 = data_in[103:96];
        } else if (select_control[7:4] == 11) {
            out1 = data_in[95:88];
        } else if (select_control[7:4] == 10) {
            out1 = data_in[87:80];
        } else if (select_control[7:4] == 9) {
            out1 = data_in[79:72];
        } else if (select_control[7:4] == 8) {
            out1 = data_in[71:64];
        } else if (select_control[7:4] == 7) {
            out1 = data_in[63:56];
        } else if (select_control[7:4] == 6) {
            out1 = data_in[55:48];
        } else if (select_control[7:4] == 5) {
            out1 = data_in[47:40];
        } else if (select_control[7:4] == 4) {
            out1 = data_in[39:32];
        } else if (select_control[7:4] == 3) {
            out1 = data_in[31:24];
        } else if (select_control[7:4] == 2) {
            out1 = data_in[23:16];
        } else if (select_control[7:4] == 1) {
            out1 = data_in[15:8];
        } else  {
            out1 = data_in[7:0];
        }
        if (select_control[3:0] == 15) {
            out0 = data_in[127:120];
        } else if (select_control[3:0] == 14) {
            out0 = data_in[119:112];
        } else if (select_control[3:0] == 13) {
            out0 = data_in[111:104];
        } else if (select_control[3:0] == 12) {
            out0 = data_in[103:96];
        } else if (select_control[3:0] == 11) {
            out0 = data_in[95:88];
        } else if (select_control[3:0] == 10) {
            out0 = data_in[87:80];
        } else if (select_control[3:0] == 9) {
            out0 = data_in[79:72];
        } else if (select_control[3:0] == 8) {
            out0 = data_in[71:64];
        } else if (select_control[3:0] == 7) {
            out0 = data_in[63:56];
        } else if (select_control[3:0] == 6) {
            out0 = data_in[55:48];
        } else if (select_control[3:0] == 5) {
            out0 = data_in[47:40];
        } else if (select_control[3:0] == 4) {
            out0 = data_in[39:32];
        } else if (select_control[3:0] == 3) {
            out0 = data_in[31:24];
        } else if (select_control[3:0] == 2) {
            out0 = data_in[23:16];
        } else if (select_control[3:0] == 1) {
            out0 = data_in[15:8];
        } else  {
            out0 = data_in[7:0];
        }

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

    apply {
        if (select_control[47:44] == 15) {
            out11 = data_in[127:120];
        } else if (select_control[47:44] == 14) {
            out11 = data_in[119:112];
        } else if (select_control[47:44] == 13) {
            out11 = data_in[111:104];
        } else if (select_control[47:44] == 12) {
            out11 = data_in[103:96];
        } else if (select_control[47:44] == 11) {
            out11 = data_in[95:88];
        } else if (select_control[47:44] == 10) {
            out11 = data_in[87:80];
        } else if (select_control[47:44] == 9) {
            out11 = data_in[79:72];
        } else if (select_control[47:44] == 8) {
            out11 = data_in[71:64];
        } else if (select_control[47:44] == 7) {
            out11 = data_in[63:56];
        } else if (select_control[47:44] == 6) {
            out11 = data_in[55:48];
        } else if (select_control[47:44] == 5) {
            out11 = data_in[47:40];
        } else if (select_control[47:44] == 4) {
            out11 = data_in[39:32];
        } else if (select_control[47:44] == 3) {
            out11 = data_in[31:24];
        } else if (select_control[47:44] == 2) {
            out11 = data_in[23:16];
        } else if (select_control[47:44] == 1) {
            out11 = data_in[15:8];
        } else  {
            out11 = data_in[7:0];
        }
        if (select_control[43:40] == 15) {
            out10 = data_in[127:120];
        } else if (select_control[43:40] == 14) {
            out10 = data_in[119:112];
        } else if (select_control[43:40] == 13) {
            out10 = data_in[111:104];
        } else if (select_control[43:40] == 12) {
            out10 = data_in[103:96];
        } else if (select_control[43:40] == 11) {
            out10 = data_in[95:88];
        } else if (select_control[43:40] == 10) {
            out10 = data_in[87:80];
        } else if (select_control[43:40] == 9) {
            out10 = data_in[79:72];
        } else if (select_control[43:40] == 8) {
            out10 = data_in[71:64];
        } else if (select_control[43:40] == 7) {
            out10 = data_in[63:56];
        } else if (select_control[43:40] == 6) {
            out10 = data_in[55:48];
        } else if (select_control[43:40] == 5) {
            out10 = data_in[47:40];
        } else if (select_control[43:40] == 4) {
            out10 = data_in[39:32];
        } else if (select_control[43:40] == 3) {
            out10 = data_in[31:24];
        } else if (select_control[43:40] == 2) {
            out10 = data_in[23:16];
        } else if (select_control[43:40] == 1) {
            out10 = data_in[15:8];
        } else  {
            out10 = data_in[7:0];
        }
        if (select_control[39:36] == 15) {
            out9 = data_in[127:120];
        } else if (select_control[39:36] == 14) {
            out9 = data_in[119:112];
        } else if (select_control[39:36] == 13) {
            out9 = data_in[111:104];
        } else if (select_control[39:36] == 12) {
            out9 = data_in[103:96];
        } else if (select_control[39:36] == 11) {
            out9 = data_in[95:88];
        } else if (select_control[39:36] == 10) {
            out9 = data_in[87:80];
        } else if (select_control[39:36] == 9) {
            out9 = data_in[79:72];
        } else if (select_control[39:36] == 8) {
            out9 = data_in[71:64];
        } else if (select_control[39:36] == 7) {
            out9 = data_in[63:56];
        } else if (select_control[39:36] == 6) {
            out9 = data_in[55:48];
        } else if (select_control[39:36] == 5) {
            out9 = data_in[47:40];
        } else if (select_control[39:36] == 4) {
            out9 = data_in[39:32];
        } else if (select_control[39:36] == 3) {
            out9 = data_in[31:24];
        } else if (select_control[39:36] == 2) {
            out9 = data_in[23:16];
        } else if (select_control[39:36] == 1) {
            out9 = data_in[15:8];
        } else  {
            out9 = data_in[7:0];
        }
        if (select_control[35:32] == 15) {
            out8 = data_in[127:120];
        } else if (select_control[35:32] == 14) {
            out8 = data_in[119:112];
        } else if (select_control[35:32] == 13) {
            out8 = data_in[111:104];
        } else if (select_control[35:32] == 12) {
            out8 = data_in[103:96];
        } else if (select_control[35:32] == 11) {
            out8 = data_in[95:88];
        } else if (select_control[35:32] == 10) {
            out8 = data_in[87:80];
        } else if (select_control[35:32] == 9) {
            out8 = data_in[79:72];
        } else if (select_control[35:32] == 8) {
            out8 = data_in[71:64];
        } else if (select_control[35:32] == 7) {
            out8 = data_in[63:56];
        } else if (select_control[35:32] == 6) {
            out8 = data_in[55:48];
        } else if (select_control[35:32] == 5) {
            out8 = data_in[47:40];
        } else if (select_control[35:32] == 4) {
            out8 = data_in[39:32];
        } else if (select_control[35:32] == 3) {
            out8 = data_in[31:24];
        } else if (select_control[35:32] == 2) {
            out8 = data_in[23:16];
        } else if (select_control[35:32] == 1) {
            out8 = data_in[15:8];
        } else  {
            out8 = data_in[7:0];
        }
        if (select_control[31:28] == 15) {
            out7 = data_in[127:120];
        } else if (select_control[31:28] == 14) {
            out7 = data_in[119:112];
        } else if (select_control[31:28] == 13) {
            out7 = data_in[111:104];
        } else if (select_control[31:28] == 12) {
            out7 = data_in[103:96];
        } else if (select_control[31:28] == 11) {
            out7 = data_in[95:88];
        } else if (select_control[31:28] == 10) {
            out7 = data_in[87:80];
        } else if (select_control[31:28] == 9) {
            out7 = data_in[79:72];
        } else if (select_control[31:28] == 8) {
            out7 = data_in[71:64];
        } else if (select_control[31:28] == 7) {
            out7 = data_in[63:56];
        } else if (select_control[31:28] == 6) {
            out7 = data_in[55:48];
        } else if (select_control[31:28] == 5) {
            out7 = data_in[47:40];
        } else if (select_control[31:28] == 4) {
            out7 = data_in[39:32];
        } else if (select_control[31:28] == 3) {
            out7 = data_in[31:24];
        } else if (select_control[31:28] == 2) {
            out7 = data_in[23:16];
        } else if (select_control[31:28] == 1) {
            out7 = data_in[15:8];
        } else  {
            out7 = data_in[7:0];
        }
        if (select_control[27:24] == 15) {
            out6 = data_in[127:120];
        } else if (select_control[27:24] == 14) {
            out6 = data_in[119:112];
        } else if (select_control[27:24] == 13) {
            out6 = data_in[111:104];
        } else if (select_control[27:24] == 12) {
            out6 = data_in[103:96];
        } else if (select_control[27:24] == 11) {
            out6 = data_in[95:88];
        } else if (select_control[27:24] == 10) {
            out6 = data_in[87:80];
        } else if (select_control[27:24] == 9) {
            out6 = data_in[79:72];
        } else if (select_control[27:24] == 8) {
            out6 = data_in[71:64];
        } else if (select_control[27:24] == 7) {
            out6 = data_in[63:56];
        } else if (select_control[27:24] == 6) {
            out6 = data_in[55:48];
        } else if (select_control[27:24] == 5) {
            out6 = data_in[47:40];
        } else if (select_control[27:24] == 4) {
            out6 = data_in[39:32];
        } else if (select_control[27:24] == 3) {
            out6 = data_in[31:24];
        } else if (select_control[27:24] == 2) {
            out6 = data_in[23:16];
        } else if (select_control[27:24] == 1) {
            out6 = data_in[15:8];
        } else  {
            out6 = data_in[7:0];
        }
        if (select_control[23:20] == 15) {
            out5 = data_in[127:120];
        } else if (select_control[23:20] == 14) {
            out5 = data_in[119:112];
        } else if (select_control[23:20] == 13) {
            out5 = data_in[111:104];
        } else if (select_control[23:20] == 12) {
            out5 = data_in[103:96];
        } else if (select_control[23:20] == 11) {
            out5 = data_in[95:88];
        } else if (select_control[23:20] == 10) {
            out5 = data_in[87:80];
        } else if (select_control[23:20] == 9) {
            out5 = data_in[79:72];
        } else if (select_control[23:20] == 8) {
            out5 = data_in[71:64];
        } else if (select_control[23:20] == 7) {
            out5 = data_in[63:56];
        } else if (select_control[23:20] == 6) {
            out5 = data_in[55:48];
        } else if (select_control[23:20] == 5) {
            out5 = data_in[47:40];
        } else if (select_control[23:20] == 4) {
            out5 = data_in[39:32];
        } else if (select_control[23:20] == 3) {
            out5 = data_in[31:24];
        } else if (select_control[23:20] == 2) {
            out5 = data_in[23:16];
        } else if (select_control[23:20] == 1) {
            out5 = data_in[15:8];
        } else  {
            out5 = data_in[7:0];
        }
        if (select_control[19:16] == 15) {
            out4 = data_in[127:120];
        } else if (select_control[19:16] == 14) {
            out4 = data_in[119:112];
        } else if (select_control[19:16] == 13) {
            out4 = data_in[111:104];
        } else if (select_control[19:16] == 12) {
            out4 = data_in[103:96];
        } else if (select_control[19:16] == 11) {
            out4 = data_in[95:88];
        } else if (select_control[19:16] == 10) {
            out4 = data_in[87:80];
        } else if (select_control[19:16] == 9) {
            out4 = data_in[79:72];
        } else if (select_control[19:16] == 8) {
            out4 = data_in[71:64];
        } else if (select_control[19:16] == 7) {
            out4 = data_in[63:56];
        } else if (select_control[19:16] == 6) {
            out4 = data_in[55:48];
        } else if (select_control[19:16] == 5) {
            out4 = data_in[47:40];
        } else if (select_control[19:16] == 4) {
            out4 = data_in[39:32];
        } else if (select_control[19:16] == 3) {
            out4 = data_in[31:24];
        } else if (select_control[19:16] == 2) {
            out4 = data_in[23:16];
        } else if (select_control[19:16] == 1) {
            out4 = data_in[15:8];
        } else  {
            out4 = data_in[7:0];
        }
        if (select_control[15:12] == 15) {
            out3 = data_in[127:120];
        } else if (select_control[15:12] == 14) {
            out3 = data_in[119:112];
        } else if (select_control[15:12] == 13) {
            out3 = data_in[111:104];
        } else if (select_control[15:12] == 12) {
            out3 = data_in[103:96];
        } else if (select_control[15:12] == 11) {
            out3 = data_in[95:88];
        } else if (select_control[15:12] == 10) {
            out3 = data_in[87:80];
        } else if (select_control[15:12] == 9) {
            out3 = data_in[79:72];
        } else if (select_control[15:12] == 8) {
            out3 = data_in[71:64];
        } else if (select_control[15:12] == 7) {
            out3 = data_in[63:56];
        } else if (select_control[15:12] == 6) {
            out3 = data_in[55:48];
        } else if (select_control[15:12] == 5) {
            out3 = data_in[47:40];
        } else if (select_control[15:12] == 4) {
            out3 = data_in[39:32];
        } else if (select_control[15:12] == 3) {
            out3 = data_in[31:24];
        } else if (select_control[15:12] == 2) {
            out3 = data_in[23:16];
        } else if (select_control[15:12] == 1) {
            out3 = data_in[15:8];
        } else  {
            out3 = data_in[7:0];
        }
        if (select_control[11:8] == 15) {
            out2 = data_in[127:120];
        } else if (select_control[11:8] == 14) {
            out2 = data_in[119:112];
        } else if (select_control[11:8] == 13) {
            out2 = data_in[111:104];
        } else if (select_control[11:8] == 12) {
            out2 = data_in[103:96];
        } else if (select_control[11:8] == 11) {
            out2 = data_in[95:88];
        } else if (select_control[11:8] == 10) {
            out2 = data_in[87:80];
        } else if (select_control[11:8] == 9) {
            out2 = data_in[79:72];
        } else if (select_control[11:8] == 8) {
            out2 = data_in[71:64];
        } else if (select_control[11:8] == 7) {
            out2 = data_in[63:56];
        } else if (select_control[11:8] == 6) {
            out2 = data_in[55:48];
        } else if (select_control[11:8] == 5) {
            out2 = data_in[47:40];
        } else if (select_control[11:8] == 4) {
            out2 = data_in[39:32];
        } else if (select_control[11:8] == 3) {
            out2 = data_in[31:24];
        } else if (select_control[11:8] == 2) {
            out2 = data_in[23:16];
        } else if (select_control[11:8] == 1) {
            out2 = data_in[15:8];
        } else  {
            out2 = data_in[7:0];
        }
        if (select_control[7:4] == 15) {
            out1 = data_in[127:120];
        } else if (select_control[7:4] == 14) {
            out1 = data_in[119:112];
        } else if (select_control[7:4] == 13) {
            out1 = data_in[111:104];
        } else if (select_control[7:4] == 12) {
            out1 = data_in[103:96];
        } else if (select_control[7:4] == 11) {
            out1 = data_in[95:88];
        } else if (select_control[7:4] == 10) {
            out1 = data_in[87:80];
        } else if (select_control[7:4] == 9) {
            out1 = data_in[79:72];
        } else if (select_control[7:4] == 8) {
            out1 = data_in[71:64];
        } else if (select_control[7:4] == 7) {
            out1 = data_in[63:56];
        } else if (select_control[7:4] == 6) {
            out1 = data_in[55:48];
        } else if (select_control[7:4] == 5) {
            out1 = data_in[47:40];
        } else if (select_control[7:4] == 4) {
            out1 = data_in[39:32];
        } else if (select_control[7:4] == 3) {
            out1 = data_in[31:24];
        } else if (select_control[7:4] == 2) {
            out1 = data_in[23:16];
        } else if (select_control[7:4] == 1) {
            out1 = data_in[15:8];
        } else  {
            out1 = data_in[7:0];
        }
        if (select_control[3:0] == 15) {
            out0 = data_in[127:120];
        } else if (select_control[3:0] == 14) {
            out0 = data_in[119:112];
        } else if (select_control[3:0] == 13) {
            out0 = data_in[111:104];
        } else if (select_control[3:0] == 12) {
            out0 = data_in[103:96];
        } else if (select_control[3:0] == 11) {
            out0 = data_in[95:88];
        } else if (select_control[3:0] == 10) {
            out0 = data_in[87:80];
        } else if (select_control[3:0] == 9) {
            out0 = data_in[79:72];
        } else if (select_control[3:0] == 8) {
            out0 = data_in[71:64];
        } else if (select_control[3:0] == 7) {
            out0 = data_in[63:56];
        } else if (select_control[3:0] == 6) {
            out0 = data_in[55:48];
        } else if (select_control[3:0] == 5) {
            out0 = data_in[47:40];
        } else if (select_control[3:0] == 4) {
            out0 = data_in[39:32];
        } else if (select_control[3:0] == 3) {
            out0 = data_in[31:24];
        } else if (select_control[3:0] == 2) {
            out0 = data_in[23:16];
        } else if (select_control[3:0] == 1) {
            out0 = data_in[15:8];
        } else  {
            out0 = data_in[7:0];
        }

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

    apply {
        if (select_control[59:55] == 23) {
            out11 = data_in[191:184];
        } else if (select_control[59:55] == 22) {
            out11 = data_in[183:176];
        } else if (select_control[59:55] == 21) {
            out11 = data_in[175:168];
        } else if (select_control[59:55] == 20) {
            out11 = data_in[167:160];
        } else if (select_control[59:55] == 19) {
            out11 = data_in[159:152];
        } else if (select_control[59:55] == 18) {
            out11 = data_in[151:144];
        } else if (select_control[59:55] == 17) {
            out11 = data_in[143:136];
        } else if (select_control[59:55] == 16) {
            out11 = data_in[135:128];
        } else if (select_control[59:55] == 15) {
            out11 = data_in[127:120];
        } else if (select_control[59:55] == 14) {
            out11 = data_in[119:112];
        } else if (select_control[59:55] == 13) {
            out11 = data_in[111:104];
        } else if (select_control[59:55] == 12) {
            out11 = data_in[103:96];
        } else if (select_control[59:55] == 11) {
            out11 = data_in[95:88];
        } else if (select_control[59:55] == 10) {
            out11 = data_in[87:80];
        } else if (select_control[59:55] == 9) {
            out11 = data_in[79:72];
        } else if (select_control[59:55] == 8) {
            out11 = data_in[71:64];
        } else if (select_control[59:55] == 7) {
            out11 = data_in[63:56];
        } else if (select_control[59:55] == 6) {
            out11 = data_in[55:48];
        } else if (select_control[59:55] == 5) {
            out11 = data_in[47:40];
        } else if (select_control[59:55] == 4) {
            out11 = data_in[39:32];
        } else if (select_control[59:55] == 3) {
            out11 = data_in[31:24];
        } else if (select_control[59:55] == 2) {
            out11 = data_in[23:16];
        } else if (select_control[59:55] == 1) {
            out11 = data_in[15:8];
        } else  {
            out11 = data_in[7:0];
        }
        if (select_control[54:50] == 23) {
            out10 = data_in[191:184];
        } else if (select_control[54:50] == 22) {
            out10 = data_in[183:176];
        } else if (select_control[54:50] == 21) {
            out10 = data_in[175:168];
        } else if (select_control[54:50] == 20) {
            out10 = data_in[167:160];
        } else if (select_control[54:50] == 19) {
            out10 = data_in[159:152];
        } else if (select_control[54:50] == 18) {
            out10 = data_in[151:144];
        } else if (select_control[54:50] == 17) {
            out10 = data_in[143:136];
        } else if (select_control[54:50] == 16) {
            out10 = data_in[135:128];
        } else if (select_control[54:50] == 15) {
            out10 = data_in[127:120];
        } else if (select_control[54:50] == 14) {
            out10 = data_in[119:112];
        } else if (select_control[54:50] == 13) {
            out10 = data_in[111:104];
        } else if (select_control[54:50] == 12) {
            out10 = data_in[103:96];
        } else if (select_control[54:50] == 11) {
            out10 = data_in[95:88];
        } else if (select_control[54:50] == 10) {
            out10 = data_in[87:80];
        } else if (select_control[54:50] == 9) {
            out10 = data_in[79:72];
        } else if (select_control[54:50] == 8) {
            out10 = data_in[71:64];
        } else if (select_control[54:50] == 7) {
            out10 = data_in[63:56];
        } else if (select_control[54:50] == 6) {
            out10 = data_in[55:48];
        } else if (select_control[54:50] == 5) {
            out10 = data_in[47:40];
        } else if (select_control[54:50] == 4) {
            out10 = data_in[39:32];
        } else if (select_control[54:50] == 3) {
            out10 = data_in[31:24];
        } else if (select_control[54:50] == 2) {
            out10 = data_in[23:16];
        } else if (select_control[54:50] == 1) {
            out10 = data_in[15:8];
        } else  {
            out10 = data_in[7:0];
        }
        if (select_control[49:45] == 23) {
            out9 = data_in[191:184];
        } else if (select_control[49:45] == 22) {
            out9 = data_in[183:176];
        } else if (select_control[49:45] == 21) {
            out9 = data_in[175:168];
        } else if (select_control[49:45] == 20) {
            out9 = data_in[167:160];
        } else if (select_control[49:45] == 19) {
            out9 = data_in[159:152];
        } else if (select_control[49:45] == 18) {
            out9 = data_in[151:144];
        } else if (select_control[49:45] == 17) {
            out9 = data_in[143:136];
        } else if (select_control[49:45] == 16) {
            out9 = data_in[135:128];
        } else if (select_control[49:45] == 15) {
            out9 = data_in[127:120];
        } else if (select_control[49:45] == 14) {
            out9 = data_in[119:112];
        } else if (select_control[49:45] == 13) {
            out9 = data_in[111:104];
        } else if (select_control[49:45] == 12) {
            out9 = data_in[103:96];
        } else if (select_control[49:45] == 11) {
            out9 = data_in[95:88];
        } else if (select_control[49:45] == 10) {
            out9 = data_in[87:80];
        } else if (select_control[49:45] == 9) {
            out9 = data_in[79:72];
        } else if (select_control[49:45] == 8) {
            out9 = data_in[71:64];
        } else if (select_control[49:45] == 7) {
            out9 = data_in[63:56];
        } else if (select_control[49:45] == 6) {
            out9 = data_in[55:48];
        } else if (select_control[49:45] == 5) {
            out9 = data_in[47:40];
        } else if (select_control[49:45] == 4) {
            out9 = data_in[39:32];
        } else if (select_control[49:45] == 3) {
            out9 = data_in[31:24];
        } else if (select_control[49:45] == 2) {
            out9 = data_in[23:16];
        } else if (select_control[49:45] == 1) {
            out9 = data_in[15:8];
        } else  {
            out9 = data_in[7:0];
        }
        if (select_control[44:40] == 23) {
            out8 = data_in[191:184];
        } else if (select_control[44:40] == 22) {
            out8 = data_in[183:176];
        } else if (select_control[44:40] == 21) {
            out8 = data_in[175:168];
        } else if (select_control[44:40] == 20) {
            out8 = data_in[167:160];
        } else if (select_control[44:40] == 19) {
            out8 = data_in[159:152];
        } else if (select_control[44:40] == 18) {
            out8 = data_in[151:144];
        } else if (select_control[44:40] == 17) {
            out8 = data_in[143:136];
        } else if (select_control[44:40] == 16) {
            out8 = data_in[135:128];
        } else if (select_control[44:40] == 15) {
            out8 = data_in[127:120];
        } else if (select_control[44:40] == 14) {
            out8 = data_in[119:112];
        } else if (select_control[44:40] == 13) {
            out8 = data_in[111:104];
        } else if (select_control[44:40] == 12) {
            out8 = data_in[103:96];
        } else if (select_control[44:40] == 11) {
            out8 = data_in[95:88];
        } else if (select_control[44:40] == 10) {
            out8 = data_in[87:80];
        } else if (select_control[44:40] == 9) {
            out8 = data_in[79:72];
        } else if (select_control[44:40] == 8) {
            out8 = data_in[71:64];
        } else if (select_control[44:40] == 7) {
            out8 = data_in[63:56];
        } else if (select_control[44:40] == 6) {
            out8 = data_in[55:48];
        } else if (select_control[44:40] == 5) {
            out8 = data_in[47:40];
        } else if (select_control[44:40] == 4) {
            out8 = data_in[39:32];
        } else if (select_control[44:40] == 3) {
            out8 = data_in[31:24];
        } else if (select_control[44:40] == 2) {
            out8 = data_in[23:16];
        } else if (select_control[44:40] == 1) {
            out8 = data_in[15:8];
        } else  {
            out8 = data_in[7:0];
        }
        if (select_control[39:35] == 23) {
            out7 = data_in[191:184];
        } else if (select_control[39:35] == 22) {
            out7 = data_in[183:176];
        } else if (select_control[39:35] == 21) {
            out7 = data_in[175:168];
        } else if (select_control[39:35] == 20) {
            out7 = data_in[167:160];
        } else if (select_control[39:35] == 19) {
            out7 = data_in[159:152];
        } else if (select_control[39:35] == 18) {
            out7 = data_in[151:144];
        } else if (select_control[39:35] == 17) {
            out7 = data_in[143:136];
        } else if (select_control[39:35] == 16) {
            out7 = data_in[135:128];
        } else if (select_control[39:35] == 15) {
            out7 = data_in[127:120];
        } else if (select_control[39:35] == 14) {
            out7 = data_in[119:112];
        } else if (select_control[39:35] == 13) {
            out7 = data_in[111:104];
        } else if (select_control[39:35] == 12) {
            out7 = data_in[103:96];
        } else if (select_control[39:35] == 11) {
            out7 = data_in[95:88];
        } else if (select_control[39:35] == 10) {
            out7 = data_in[87:80];
        } else if (select_control[39:35] == 9) {
            out7 = data_in[79:72];
        } else if (select_control[39:35] == 8) {
            out7 = data_in[71:64];
        } else if (select_control[39:35] == 7) {
            out7 = data_in[63:56];
        } else if (select_control[39:35] == 6) {
            out7 = data_in[55:48];
        } else if (select_control[39:35] == 5) {
            out7 = data_in[47:40];
        } else if (select_control[39:35] == 4) {
            out7 = data_in[39:32];
        } else if (select_control[39:35] == 3) {
            out7 = data_in[31:24];
        } else if (select_control[39:35] == 2) {
            out7 = data_in[23:16];
        } else if (select_control[39:35] == 1) {
            out7 = data_in[15:8];
        } else  {
            out7 = data_in[7:0];
        }
        if (select_control[34:30] == 23) {
            out6 = data_in[191:184];
        } else if (select_control[34:30] == 22) {
            out6 = data_in[183:176];
        } else if (select_control[34:30] == 21) {
            out6 = data_in[175:168];
        } else if (select_control[34:30] == 20) {
            out6 = data_in[167:160];
        } else if (select_control[34:30] == 19) {
            out6 = data_in[159:152];
        } else if (select_control[34:30] == 18) {
            out6 = data_in[151:144];
        } else if (select_control[34:30] == 17) {
            out6 = data_in[143:136];
        } else if (select_control[34:30] == 16) {
            out6 = data_in[135:128];
        } else if (select_control[34:30] == 15) {
            out6 = data_in[127:120];
        } else if (select_control[34:30] == 14) {
            out6 = data_in[119:112];
        } else if (select_control[34:30] == 13) {
            out6 = data_in[111:104];
        } else if (select_control[34:30] == 12) {
            out6 = data_in[103:96];
        } else if (select_control[34:30] == 11) {
            out6 = data_in[95:88];
        } else if (select_control[34:30] == 10) {
            out6 = data_in[87:80];
        } else if (select_control[34:30] == 9) {
            out6 = data_in[79:72];
        } else if (select_control[34:30] == 8) {
            out6 = data_in[71:64];
        } else if (select_control[34:30] == 7) {
            out6 = data_in[63:56];
        } else if (select_control[34:30] == 6) {
            out6 = data_in[55:48];
        } else if (select_control[34:30] == 5) {
            out6 = data_in[47:40];
        } else if (select_control[34:30] == 4) {
            out6 = data_in[39:32];
        } else if (select_control[34:30] == 3) {
            out6 = data_in[31:24];
        } else if (select_control[34:30] == 2) {
            out6 = data_in[23:16];
        } else if (select_control[34:30] == 1) {
            out6 = data_in[15:8];
        } else  {
            out6 = data_in[7:0];
        }
        if (select_control[29:25] == 23) {
            out5 = data_in[191:184];
        } else if (select_control[29:25] == 22) {
            out5 = data_in[183:176];
        } else if (select_control[29:25] == 21) {
            out5 = data_in[175:168];
        } else if (select_control[29:25] == 20) {
            out5 = data_in[167:160];
        } else if (select_control[29:25] == 19) {
            out5 = data_in[159:152];
        } else if (select_control[29:25] == 18) {
            out5 = data_in[151:144];
        } else if (select_control[29:25] == 17) {
            out5 = data_in[143:136];
        } else if (select_control[29:25] == 16) {
            out5 = data_in[135:128];
        } else if (select_control[29:25] == 15) {
            out5 = data_in[127:120];
        } else if (select_control[29:25] == 14) {
            out5 = data_in[119:112];
        } else if (select_control[29:25] == 13) {
            out5 = data_in[111:104];
        } else if (select_control[29:25] == 12) {
            out5 = data_in[103:96];
        } else if (select_control[29:25] == 11) {
            out5 = data_in[95:88];
        } else if (select_control[29:25] == 10) {
            out5 = data_in[87:80];
        } else if (select_control[29:25] == 9) {
            out5 = data_in[79:72];
        } else if (select_control[29:25] == 8) {
            out5 = data_in[71:64];
        } else if (select_control[29:25] == 7) {
            out5 = data_in[63:56];
        } else if (select_control[29:25] == 6) {
            out5 = data_in[55:48];
        } else if (select_control[29:25] == 5) {
            out5 = data_in[47:40];
        } else if (select_control[29:25] == 4) {
            out5 = data_in[39:32];
        } else if (select_control[29:25] == 3) {
            out5 = data_in[31:24];
        } else if (select_control[29:25] == 2) {
            out5 = data_in[23:16];
        } else if (select_control[29:25] == 1) {
            out5 = data_in[15:8];
        } else  {
            out5 = data_in[7:0];
        }
        if (select_control[24:20] == 23) {
            out4 = data_in[191:184];
        } else if (select_control[24:20] == 22) {
            out4 = data_in[183:176];
        } else if (select_control[24:20] == 21) {
            out4 = data_in[175:168];
        } else if (select_control[24:20] == 20) {
            out4 = data_in[167:160];
        } else if (select_control[24:20] == 19) {
            out4 = data_in[159:152];
        } else if (select_control[24:20] == 18) {
            out4 = data_in[151:144];
        } else if (select_control[24:20] == 17) {
            out4 = data_in[143:136];
        } else if (select_control[24:20] == 16) {
            out4 = data_in[135:128];
        } else if (select_control[24:20] == 15) {
            out4 = data_in[127:120];
        } else if (select_control[24:20] == 14) {
            out4 = data_in[119:112];
        } else if (select_control[24:20] == 13) {
            out4 = data_in[111:104];
        } else if (select_control[24:20] == 12) {
            out4 = data_in[103:96];
        } else if (select_control[24:20] == 11) {
            out4 = data_in[95:88];
        } else if (select_control[24:20] == 10) {
            out4 = data_in[87:80];
        } else if (select_control[24:20] == 9) {
            out4 = data_in[79:72];
        } else if (select_control[24:20] == 8) {
            out4 = data_in[71:64];
        } else if (select_control[24:20] == 7) {
            out4 = data_in[63:56];
        } else if (select_control[24:20] == 6) {
            out4 = data_in[55:48];
        } else if (select_control[24:20] == 5) {
            out4 = data_in[47:40];
        } else if (select_control[24:20] == 4) {
            out4 = data_in[39:32];
        } else if (select_control[24:20] == 3) {
            out4 = data_in[31:24];
        } else if (select_control[24:20] == 2) {
            out4 = data_in[23:16];
        } else if (select_control[24:20] == 1) {
            out4 = data_in[15:8];
        } else  {
            out4 = data_in[7:0];
        }
        if (select_control[19:15] == 23) {
            out3 = data_in[191:184];
        } else if (select_control[19:15] == 22) {
            out3 = data_in[183:176];
        } else if (select_control[19:15] == 21) {
            out3 = data_in[175:168];
        } else if (select_control[19:15] == 20) {
            out3 = data_in[167:160];
        } else if (select_control[19:15] == 19) {
            out3 = data_in[159:152];
        } else if (select_control[19:15] == 18) {
            out3 = data_in[151:144];
        } else if (select_control[19:15] == 17) {
            out3 = data_in[143:136];
        } else if (select_control[19:15] == 16) {
            out3 = data_in[135:128];
        } else if (select_control[19:15] == 15) {
            out3 = data_in[127:120];
        } else if (select_control[19:15] == 14) {
            out3 = data_in[119:112];
        } else if (select_control[19:15] == 13) {
            out3 = data_in[111:104];
        } else if (select_control[19:15] == 12) {
            out3 = data_in[103:96];
        } else if (select_control[19:15] == 11) {
            out3 = data_in[95:88];
        } else if (select_control[19:15] == 10) {
            out3 = data_in[87:80];
        } else if (select_control[19:15] == 9) {
            out3 = data_in[79:72];
        } else if (select_control[19:15] == 8) {
            out3 = data_in[71:64];
        } else if (select_control[19:15] == 7) {
            out3 = data_in[63:56];
        } else if (select_control[19:15] == 6) {
            out3 = data_in[55:48];
        } else if (select_control[19:15] == 5) {
            out3 = data_in[47:40];
        } else if (select_control[19:15] == 4) {
            out3 = data_in[39:32];
        } else if (select_control[19:15] == 3) {
            out3 = data_in[31:24];
        } else if (select_control[19:15] == 2) {
            out3 = data_in[23:16];
        } else if (select_control[19:15] == 1) {
            out3 = data_in[15:8];
        } else  {
            out3 = data_in[7:0];
        }
        if (select_control[14:10] == 23) {
            out2 = data_in[191:184];
        } else if (select_control[14:10] == 22) {
            out2 = data_in[183:176];
        } else if (select_control[14:10] == 21) {
            out2 = data_in[175:168];
        } else if (select_control[14:10] == 20) {
            out2 = data_in[167:160];
        } else if (select_control[14:10] == 19) {
            out2 = data_in[159:152];
        } else if (select_control[14:10] == 18) {
            out2 = data_in[151:144];
        } else if (select_control[14:10] == 17) {
            out2 = data_in[143:136];
        } else if (select_control[14:10] == 16) {
            out2 = data_in[135:128];
        } else if (select_control[14:10] == 15) {
            out2 = data_in[127:120];
        } else if (select_control[14:10] == 14) {
            out2 = data_in[119:112];
        } else if (select_control[14:10] == 13) {
            out2 = data_in[111:104];
        } else if (select_control[14:10] == 12) {
            out2 = data_in[103:96];
        } else if (select_control[14:10] == 11) {
            out2 = data_in[95:88];
        } else if (select_control[14:10] == 10) {
            out2 = data_in[87:80];
        } else if (select_control[14:10] == 9) {
            out2 = data_in[79:72];
        } else if (select_control[14:10] == 8) {
            out2 = data_in[71:64];
        } else if (select_control[14:10] == 7) {
            out2 = data_in[63:56];
        } else if (select_control[14:10] == 6) {
            out2 = data_in[55:48];
        } else if (select_control[14:10] == 5) {
            out2 = data_in[47:40];
        } else if (select_control[14:10] == 4) {
            out2 = data_in[39:32];
        } else if (select_control[14:10] == 3) {
            out2 = data_in[31:24];
        } else if (select_control[14:10] == 2) {
            out2 = data_in[23:16];
        } else if (select_control[14:10] == 1) {
            out2 = data_in[15:8];
        } else  {
            out2 = data_in[7:0];
        }
        if (select_control[9:5] == 23) {
            out1 = data_in[191:184];
        } else if (select_control[9:5] == 22) {
            out1 = data_in[183:176];
        } else if (select_control[9:5] == 21) {
            out1 = data_in[175:168];
        } else if (select_control[9:5] == 20) {
            out1 = data_in[167:160];
        } else if (select_control[9:5] == 19) {
            out1 = data_in[159:152];
        } else if (select_control[9:5] == 18) {
            out1 = data_in[151:144];
        } else if (select_control[9:5] == 17) {
            out1 = data_in[143:136];
        } else if (select_control[9:5] == 16) {
            out1 = data_in[135:128];
        } else if (select_control[9:5] == 15) {
            out1 = data_in[127:120];
        } else if (select_control[9:5] == 14) {
            out1 = data_in[119:112];
        } else if (select_control[9:5] == 13) {
            out1 = data_in[111:104];
        } else if (select_control[9:5] == 12) {
            out1 = data_in[103:96];
        } else if (select_control[9:5] == 11) {
            out1 = data_in[95:88];
        } else if (select_control[9:5] == 10) {
            out1 = data_in[87:80];
        } else if (select_control[9:5] == 9) {
            out1 = data_in[79:72];
        } else if (select_control[9:5] == 8) {
            out1 = data_in[71:64];
        } else if (select_control[9:5] == 7) {
            out1 = data_in[63:56];
        } else if (select_control[9:5] == 6) {
            out1 = data_in[55:48];
        } else if (select_control[9:5] == 5) {
            out1 = data_in[47:40];
        } else if (select_control[9:5] == 4) {
            out1 = data_in[39:32];
        } else if (select_control[9:5] == 3) {
            out1 = data_in[31:24];
        } else if (select_control[9:5] == 2) {
            out1 = data_in[23:16];
        } else if (select_control[9:5] == 1) {
            out1 = data_in[15:8];
        } else  {
            out1 = data_in[7:0];
        }
        if (select_control[4:0] == 23) {
            out0 = data_in[191:184];
        } else if (select_control[4:0] == 22) {
            out0 = data_in[183:176];
        } else if (select_control[4:0] == 21) {
            out0 = data_in[175:168];
        } else if (select_control[4:0] == 20) {
            out0 = data_in[167:160];
        } else if (select_control[4:0] == 19) {
            out0 = data_in[159:152];
        } else if (select_control[4:0] == 18) {
            out0 = data_in[151:144];
        } else if (select_control[4:0] == 17) {
            out0 = data_in[143:136];
        } else if (select_control[4:0] == 16) {
            out0 = data_in[135:128];
        } else if (select_control[4:0] == 15) {
            out0 = data_in[127:120];
        } else if (select_control[4:0] == 14) {
            out0 = data_in[119:112];
        } else if (select_control[4:0] == 13) {
            out0 = data_in[111:104];
        } else if (select_control[4:0] == 12) {
            out0 = data_in[103:96];
        } else if (select_control[4:0] == 11) {
            out0 = data_in[95:88];
        } else if (select_control[4:0] == 10) {
            out0 = data_in[87:80];
        } else if (select_control[4:0] == 9) {
            out0 = data_in[79:72];
        } else if (select_control[4:0] == 8) {
            out0 = data_in[71:64];
        } else if (select_control[4:0] == 7) {
            out0 = data_in[63:56];
        } else if (select_control[4:0] == 6) {
            out0 = data_in[55:48];
        } else if (select_control[4:0] == 5) {
            out0 = data_in[47:40];
        } else if (select_control[4:0] == 4) {
            out0 = data_in[39:32];
        } else if (select_control[4:0] == 3) {
            out0 = data_in[31:24];
        } else if (select_control[4:0] == 2) {
            out0 = data_in[23:16];
        } else if (select_control[4:0] == 1) {
            out0 = data_in[15:8];
        } else  {
            out0 = data_in[7:0];
        }

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

    apply {
        if (select_control[89:85] == 23) {
            out17 = data_in[191:184];
        } else if (select_control[89:85] == 22) {
            out17 = data_in[183:176];
        } else if (select_control[89:85] == 21) {
            out17 = data_in[175:168];
        } else if (select_control[89:85] == 20) {
            out17 = data_in[167:160];
        } else if (select_control[89:85] == 19) {
            out17 = data_in[159:152];
        } else if (select_control[89:85] == 18) {
            out17 = data_in[151:144];
        } else if (select_control[89:85] == 17) {
            out17 = data_in[143:136];
        } else if (select_control[89:85] == 16) {
            out17 = data_in[135:128];
        } else if (select_control[89:85] == 15) {
            out17 = data_in[127:120];
        } else if (select_control[89:85] == 14) {
            out17 = data_in[119:112];
        } else if (select_control[89:85] == 13) {
            out17 = data_in[111:104];
        } else if (select_control[89:85] == 12) {
            out17 = data_in[103:96];
        } else if (select_control[89:85] == 11) {
            out17 = data_in[95:88];
        } else if (select_control[89:85] == 10) {
            out17 = data_in[87:80];
        } else if (select_control[89:85] == 9) {
            out17 = data_in[79:72];
        } else if (select_control[89:85] == 8) {
            out17 = data_in[71:64];
        } else if (select_control[89:85] == 7) {
            out17 = data_in[63:56];
        } else if (select_control[89:85] == 6) {
            out17 = data_in[55:48];
        } else if (select_control[89:85] == 5) {
            out17 = data_in[47:40];
        } else if (select_control[89:85] == 4) {
            out17 = data_in[39:32];
        } else if (select_control[89:85] == 3) {
            out17 = data_in[31:24];
        } else if (select_control[89:85] == 2) {
            out17 = data_in[23:16];
        } else if (select_control[89:85] == 1) {
            out17 = data_in[15:8];
        } else  {
            out17 = data_in[7:0];
        }
        if (select_control[84:80] == 23) {
            out16 = data_in[191:184];
        } else if (select_control[84:80] == 22) {
            out16 = data_in[183:176];
        } else if (select_control[84:80] == 21) {
            out16 = data_in[175:168];
        } else if (select_control[84:80] == 20) {
            out16 = data_in[167:160];
        } else if (select_control[84:80] == 19) {
            out16 = data_in[159:152];
        } else if (select_control[84:80] == 18) {
            out16 = data_in[151:144];
        } else if (select_control[84:80] == 17) {
            out16 = data_in[143:136];
        } else if (select_control[84:80] == 16) {
            out16 = data_in[135:128];
        } else if (select_control[84:80] == 15) {
            out16 = data_in[127:120];
        } else if (select_control[84:80] == 14) {
            out16 = data_in[119:112];
        } else if (select_control[84:80] == 13) {
            out16 = data_in[111:104];
        } else if (select_control[84:80] == 12) {
            out16 = data_in[103:96];
        } else if (select_control[84:80] == 11) {
            out16 = data_in[95:88];
        } else if (select_control[84:80] == 10) {
            out16 = data_in[87:80];
        } else if (select_control[84:80] == 9) {
            out16 = data_in[79:72];
        } else if (select_control[84:80] == 8) {
            out16 = data_in[71:64];
        } else if (select_control[84:80] == 7) {
            out16 = data_in[63:56];
        } else if (select_control[84:80] == 6) {
            out16 = data_in[55:48];
        } else if (select_control[84:80] == 5) {
            out16 = data_in[47:40];
        } else if (select_control[84:80] == 4) {
            out16 = data_in[39:32];
        } else if (select_control[84:80] == 3) {
            out16 = data_in[31:24];
        } else if (select_control[84:80] == 2) {
            out16 = data_in[23:16];
        } else if (select_control[84:80] == 1) {
            out16 = data_in[15:8];
        } else  {
            out16 = data_in[7:0];
        }
        if (select_control[79:75] == 23) {
            out15 = data_in[191:184];
        } else if (select_control[79:75] == 22) {
            out15 = data_in[183:176];
        } else if (select_control[79:75] == 21) {
            out15 = data_in[175:168];
        } else if (select_control[79:75] == 20) {
            out15 = data_in[167:160];
        } else if (select_control[79:75] == 19) {
            out15 = data_in[159:152];
        } else if (select_control[79:75] == 18) {
            out15 = data_in[151:144];
        } else if (select_control[79:75] == 17) {
            out15 = data_in[143:136];
        } else if (select_control[79:75] == 16) {
            out15 = data_in[135:128];
        } else if (select_control[79:75] == 15) {
            out15 = data_in[127:120];
        } else if (select_control[79:75] == 14) {
            out15 = data_in[119:112];
        } else if (select_control[79:75] == 13) {
            out15 = data_in[111:104];
        } else if (select_control[79:75] == 12) {
            out15 = data_in[103:96];
        } else if (select_control[79:75] == 11) {
            out15 = data_in[95:88];
        } else if (select_control[79:75] == 10) {
            out15 = data_in[87:80];
        } else if (select_control[79:75] == 9) {
            out15 = data_in[79:72];
        } else if (select_control[79:75] == 8) {
            out15 = data_in[71:64];
        } else if (select_control[79:75] == 7) {
            out15 = data_in[63:56];
        } else if (select_control[79:75] == 6) {
            out15 = data_in[55:48];
        } else if (select_control[79:75] == 5) {
            out15 = data_in[47:40];
        } else if (select_control[79:75] == 4) {
            out15 = data_in[39:32];
        } else if (select_control[79:75] == 3) {
            out15 = data_in[31:24];
        } else if (select_control[79:75] == 2) {
            out15 = data_in[23:16];
        } else if (select_control[79:75] == 1) {
            out15 = data_in[15:8];
        } else  {
            out15 = data_in[7:0];
        }
        if (select_control[74:70] == 23) {
            out14 = data_in[191:184];
        } else if (select_control[74:70] == 22) {
            out14 = data_in[183:176];
        } else if (select_control[74:70] == 21) {
            out14 = data_in[175:168];
        } else if (select_control[74:70] == 20) {
            out14 = data_in[167:160];
        } else if (select_control[74:70] == 19) {
            out14 = data_in[159:152];
        } else if (select_control[74:70] == 18) {
            out14 = data_in[151:144];
        } else if (select_control[74:70] == 17) {
            out14 = data_in[143:136];
        } else if (select_control[74:70] == 16) {
            out14 = data_in[135:128];
        } else if (select_control[74:70] == 15) {
            out14 = data_in[127:120];
        } else if (select_control[74:70] == 14) {
            out14 = data_in[119:112];
        } else if (select_control[74:70] == 13) {
            out14 = data_in[111:104];
        } else if (select_control[74:70] == 12) {
            out14 = data_in[103:96];
        } else if (select_control[74:70] == 11) {
            out14 = data_in[95:88];
        } else if (select_control[74:70] == 10) {
            out14 = data_in[87:80];
        } else if (select_control[74:70] == 9) {
            out14 = data_in[79:72];
        } else if (select_control[74:70] == 8) {
            out14 = data_in[71:64];
        } else if (select_control[74:70] == 7) {
            out14 = data_in[63:56];
        } else if (select_control[74:70] == 6) {
            out14 = data_in[55:48];
        } else if (select_control[74:70] == 5) {
            out14 = data_in[47:40];
        } else if (select_control[74:70] == 4) {
            out14 = data_in[39:32];
        } else if (select_control[74:70] == 3) {
            out14 = data_in[31:24];
        } else if (select_control[74:70] == 2) {
            out14 = data_in[23:16];
        } else if (select_control[74:70] == 1) {
            out14 = data_in[15:8];
        } else  {
            out14 = data_in[7:0];
        }
        if (select_control[69:65] == 23) {
            out13 = data_in[191:184];
        } else if (select_control[69:65] == 22) {
            out13 = data_in[183:176];
        } else if (select_control[69:65] == 21) {
            out13 = data_in[175:168];
        } else if (select_control[69:65] == 20) {
            out13 = data_in[167:160];
        } else if (select_control[69:65] == 19) {
            out13 = data_in[159:152];
        } else if (select_control[69:65] == 18) {
            out13 = data_in[151:144];
        } else if (select_control[69:65] == 17) {
            out13 = data_in[143:136];
        } else if (select_control[69:65] == 16) {
            out13 = data_in[135:128];
        } else if (select_control[69:65] == 15) {
            out13 = data_in[127:120];
        } else if (select_control[69:65] == 14) {
            out13 = data_in[119:112];
        } else if (select_control[69:65] == 13) {
            out13 = data_in[111:104];
        } else if (select_control[69:65] == 12) {
            out13 = data_in[103:96];
        } else if (select_control[69:65] == 11) {
            out13 = data_in[95:88];
        } else if (select_control[69:65] == 10) {
            out13 = data_in[87:80];
        } else if (select_control[69:65] == 9) {
            out13 = data_in[79:72];
        } else if (select_control[69:65] == 8) {
            out13 = data_in[71:64];
        } else if (select_control[69:65] == 7) {
            out13 = data_in[63:56];
        } else if (select_control[69:65] == 6) {
            out13 = data_in[55:48];
        } else if (select_control[69:65] == 5) {
            out13 = data_in[47:40];
        } else if (select_control[69:65] == 4) {
            out13 = data_in[39:32];
        } else if (select_control[69:65] == 3) {
            out13 = data_in[31:24];
        } else if (select_control[69:65] == 2) {
            out13 = data_in[23:16];
        } else if (select_control[69:65] == 1) {
            out13 = data_in[15:8];
        } else  {
            out13 = data_in[7:0];
        }
        if (select_control[64:60] == 23) {
            out12 = data_in[191:184];
        } else if (select_control[64:60] == 22) {
            out12 = data_in[183:176];
        } else if (select_control[64:60] == 21) {
            out12 = data_in[175:168];
        } else if (select_control[64:60] == 20) {
            out12 = data_in[167:160];
        } else if (select_control[64:60] == 19) {
            out12 = data_in[159:152];
        } else if (select_control[64:60] == 18) {
            out12 = data_in[151:144];
        } else if (select_control[64:60] == 17) {
            out12 = data_in[143:136];
        } else if (select_control[64:60] == 16) {
            out12 = data_in[135:128];
        } else if (select_control[64:60] == 15) {
            out12 = data_in[127:120];
        } else if (select_control[64:60] == 14) {
            out12 = data_in[119:112];
        } else if (select_control[64:60] == 13) {
            out12 = data_in[111:104];
        } else if (select_control[64:60] == 12) {
            out12 = data_in[103:96];
        } else if (select_control[64:60] == 11) {
            out12 = data_in[95:88];
        } else if (select_control[64:60] == 10) {
            out12 = data_in[87:80];
        } else if (select_control[64:60] == 9) {
            out12 = data_in[79:72];
        } else if (select_control[64:60] == 8) {
            out12 = data_in[71:64];
        } else if (select_control[64:60] == 7) {
            out12 = data_in[63:56];
        } else if (select_control[64:60] == 6) {
            out12 = data_in[55:48];
        } else if (select_control[64:60] == 5) {
            out12 = data_in[47:40];
        } else if (select_control[64:60] == 4) {
            out12 = data_in[39:32];
        } else if (select_control[64:60] == 3) {
            out12 = data_in[31:24];
        } else if (select_control[64:60] == 2) {
            out12 = data_in[23:16];
        } else if (select_control[64:60] == 1) {
            out12 = data_in[15:8];
        } else  {
            out12 = data_in[7:0];
        }
        if (select_control[59:55] == 23) {
            out11 = data_in[191:184];
        } else if (select_control[59:55] == 22) {
            out11 = data_in[183:176];
        } else if (select_control[59:55] == 21) {
            out11 = data_in[175:168];
        } else if (select_control[59:55] == 20) {
            out11 = data_in[167:160];
        } else if (select_control[59:55] == 19) {
            out11 = data_in[159:152];
        } else if (select_control[59:55] == 18) {
            out11 = data_in[151:144];
        } else if (select_control[59:55] == 17) {
            out11 = data_in[143:136];
        } else if (select_control[59:55] == 16) {
            out11 = data_in[135:128];
        } else if (select_control[59:55] == 15) {
            out11 = data_in[127:120];
        } else if (select_control[59:55] == 14) {
            out11 = data_in[119:112];
        } else if (select_control[59:55] == 13) {
            out11 = data_in[111:104];
        } else if (select_control[59:55] == 12) {
            out11 = data_in[103:96];
        } else if (select_control[59:55] == 11) {
            out11 = data_in[95:88];
        } else if (select_control[59:55] == 10) {
            out11 = data_in[87:80];
        } else if (select_control[59:55] == 9) {
            out11 = data_in[79:72];
        } else if (select_control[59:55] == 8) {
            out11 = data_in[71:64];
        } else if (select_control[59:55] == 7) {
            out11 = data_in[63:56];
        } else if (select_control[59:55] == 6) {
            out11 = data_in[55:48];
        } else if (select_control[59:55] == 5) {
            out11 = data_in[47:40];
        } else if (select_control[59:55] == 4) {
            out11 = data_in[39:32];
        } else if (select_control[59:55] == 3) {
            out11 = data_in[31:24];
        } else if (select_control[59:55] == 2) {
            out11 = data_in[23:16];
        } else if (select_control[59:55] == 1) {
            out11 = data_in[15:8];
        } else  {
            out11 = data_in[7:0];
        }
        if (select_control[54:50] == 23) {
            out10 = data_in[191:184];
        } else if (select_control[54:50] == 22) {
            out10 = data_in[183:176];
        } else if (select_control[54:50] == 21) {
            out10 = data_in[175:168];
        } else if (select_control[54:50] == 20) {
            out10 = data_in[167:160];
        } else if (select_control[54:50] == 19) {
            out10 = data_in[159:152];
        } else if (select_control[54:50] == 18) {
            out10 = data_in[151:144];
        } else if (select_control[54:50] == 17) {
            out10 = data_in[143:136];
        } else if (select_control[54:50] == 16) {
            out10 = data_in[135:128];
        } else if (select_control[54:50] == 15) {
            out10 = data_in[127:120];
        } else if (select_control[54:50] == 14) {
            out10 = data_in[119:112];
        } else if (select_control[54:50] == 13) {
            out10 = data_in[111:104];
        } else if (select_control[54:50] == 12) {
            out10 = data_in[103:96];
        } else if (select_control[54:50] == 11) {
            out10 = data_in[95:88];
        } else if (select_control[54:50] == 10) {
            out10 = data_in[87:80];
        } else if (select_control[54:50] == 9) {
            out10 = data_in[79:72];
        } else if (select_control[54:50] == 8) {
            out10 = data_in[71:64];
        } else if (select_control[54:50] == 7) {
            out10 = data_in[63:56];
        } else if (select_control[54:50] == 6) {
            out10 = data_in[55:48];
        } else if (select_control[54:50] == 5) {
            out10 = data_in[47:40];
        } else if (select_control[54:50] == 4) {
            out10 = data_in[39:32];
        } else if (select_control[54:50] == 3) {
            out10 = data_in[31:24];
        } else if (select_control[54:50] == 2) {
            out10 = data_in[23:16];
        } else if (select_control[54:50] == 1) {
            out10 = data_in[15:8];
        } else  {
            out10 = data_in[7:0];
        }
        if (select_control[49:45] == 23) {
            out9 = data_in[191:184];
        } else if (select_control[49:45] == 22) {
            out9 = data_in[183:176];
        } else if (select_control[49:45] == 21) {
            out9 = data_in[175:168];
        } else if (select_control[49:45] == 20) {
            out9 = data_in[167:160];
        } else if (select_control[49:45] == 19) {
            out9 = data_in[159:152];
        } else if (select_control[49:45] == 18) {
            out9 = data_in[151:144];
        } else if (select_control[49:45] == 17) {
            out9 = data_in[143:136];
        } else if (select_control[49:45] == 16) {
            out9 = data_in[135:128];
        } else if (select_control[49:45] == 15) {
            out9 = data_in[127:120];
        } else if (select_control[49:45] == 14) {
            out9 = data_in[119:112];
        } else if (select_control[49:45] == 13) {
            out9 = data_in[111:104];
        } else if (select_control[49:45] == 12) {
            out9 = data_in[103:96];
        } else if (select_control[49:45] == 11) {
            out9 = data_in[95:88];
        } else if (select_control[49:45] == 10) {
            out9 = data_in[87:80];
        } else if (select_control[49:45] == 9) {
            out9 = data_in[79:72];
        } else if (select_control[49:45] == 8) {
            out9 = data_in[71:64];
        } else if (select_control[49:45] == 7) {
            out9 = data_in[63:56];
        } else if (select_control[49:45] == 6) {
            out9 = data_in[55:48];
        } else if (select_control[49:45] == 5) {
            out9 = data_in[47:40];
        } else if (select_control[49:45] == 4) {
            out9 = data_in[39:32];
        } else if (select_control[49:45] == 3) {
            out9 = data_in[31:24];
        } else if (select_control[49:45] == 2) {
            out9 = data_in[23:16];
        } else if (select_control[49:45] == 1) {
            out9 = data_in[15:8];
        } else  {
            out9 = data_in[7:0];
        }
        if (select_control[44:40] == 23) {
            out8 = data_in[191:184];
        } else if (select_control[44:40] == 22) {
            out8 = data_in[183:176];
        } else if (select_control[44:40] == 21) {
            out8 = data_in[175:168];
        } else if (select_control[44:40] == 20) {
            out8 = data_in[167:160];
        } else if (select_control[44:40] == 19) {
            out8 = data_in[159:152];
        } else if (select_control[44:40] == 18) {
            out8 = data_in[151:144];
        } else if (select_control[44:40] == 17) {
            out8 = data_in[143:136];
        } else if (select_control[44:40] == 16) {
            out8 = data_in[135:128];
        } else if (select_control[44:40] == 15) {
            out8 = data_in[127:120];
        } else if (select_control[44:40] == 14) {
            out8 = data_in[119:112];
        } else if (select_control[44:40] == 13) {
            out8 = data_in[111:104];
        } else if (select_control[44:40] == 12) {
            out8 = data_in[103:96];
        } else if (select_control[44:40] == 11) {
            out8 = data_in[95:88];
        } else if (select_control[44:40] == 10) {
            out8 = data_in[87:80];
        } else if (select_control[44:40] == 9) {
            out8 = data_in[79:72];
        } else if (select_control[44:40] == 8) {
            out8 = data_in[71:64];
        } else if (select_control[44:40] == 7) {
            out8 = data_in[63:56];
        } else if (select_control[44:40] == 6) {
            out8 = data_in[55:48];
        } else if (select_control[44:40] == 5) {
            out8 = data_in[47:40];
        } else if (select_control[44:40] == 4) {
            out8 = data_in[39:32];
        } else if (select_control[44:40] == 3) {
            out8 = data_in[31:24];
        } else if (select_control[44:40] == 2) {
            out8 = data_in[23:16];
        } else if (select_control[44:40] == 1) {
            out8 = data_in[15:8];
        } else  {
            out8 = data_in[7:0];
        }
        if (select_control[39:35] == 23) {
            out7 = data_in[191:184];
        } else if (select_control[39:35] == 22) {
            out7 = data_in[183:176];
        } else if (select_control[39:35] == 21) {
            out7 = data_in[175:168];
        } else if (select_control[39:35] == 20) {
            out7 = data_in[167:160];
        } else if (select_control[39:35] == 19) {
            out7 = data_in[159:152];
        } else if (select_control[39:35] == 18) {
            out7 = data_in[151:144];
        } else if (select_control[39:35] == 17) {
            out7 = data_in[143:136];
        } else if (select_control[39:35] == 16) {
            out7 = data_in[135:128];
        } else if (select_control[39:35] == 15) {
            out7 = data_in[127:120];
        } else if (select_control[39:35] == 14) {
            out7 = data_in[119:112];
        } else if (select_control[39:35] == 13) {
            out7 = data_in[111:104];
        } else if (select_control[39:35] == 12) {
            out7 = data_in[103:96];
        } else if (select_control[39:35] == 11) {
            out7 = data_in[95:88];
        } else if (select_control[39:35] == 10) {
            out7 = data_in[87:80];
        } else if (select_control[39:35] == 9) {
            out7 = data_in[79:72];
        } else if (select_control[39:35] == 8) {
            out7 = data_in[71:64];
        } else if (select_control[39:35] == 7) {
            out7 = data_in[63:56];
        } else if (select_control[39:35] == 6) {
            out7 = data_in[55:48];
        } else if (select_control[39:35] == 5) {
            out7 = data_in[47:40];
        } else if (select_control[39:35] == 4) {
            out7 = data_in[39:32];
        } else if (select_control[39:35] == 3) {
            out7 = data_in[31:24];
        } else if (select_control[39:35] == 2) {
            out7 = data_in[23:16];
        } else if (select_control[39:35] == 1) {
            out7 = data_in[15:8];
        } else  {
            out7 = data_in[7:0];
        }
        if (select_control[34:30] == 23) {
            out6 = data_in[191:184];
        } else if (select_control[34:30] == 22) {
            out6 = data_in[183:176];
        } else if (select_control[34:30] == 21) {
            out6 = data_in[175:168];
        } else if (select_control[34:30] == 20) {
            out6 = data_in[167:160];
        } else if (select_control[34:30] == 19) {
            out6 = data_in[159:152];
        } else if (select_control[34:30] == 18) {
            out6 = data_in[151:144];
        } else if (select_control[34:30] == 17) {
            out6 = data_in[143:136];
        } else if (select_control[34:30] == 16) {
            out6 = data_in[135:128];
        } else if (select_control[34:30] == 15) {
            out6 = data_in[127:120];
        } else if (select_control[34:30] == 14) {
            out6 = data_in[119:112];
        } else if (select_control[34:30] == 13) {
            out6 = data_in[111:104];
        } else if (select_control[34:30] == 12) {
            out6 = data_in[103:96];
        } else if (select_control[34:30] == 11) {
            out6 = data_in[95:88];
        } else if (select_control[34:30] == 10) {
            out6 = data_in[87:80];
        } else if (select_control[34:30] == 9) {
            out6 = data_in[79:72];
        } else if (select_control[34:30] == 8) {
            out6 = data_in[71:64];
        } else if (select_control[34:30] == 7) {
            out6 = data_in[63:56];
        } else if (select_control[34:30] == 6) {
            out6 = data_in[55:48];
        } else if (select_control[34:30] == 5) {
            out6 = data_in[47:40];
        } else if (select_control[34:30] == 4) {
            out6 = data_in[39:32];
        } else if (select_control[34:30] == 3) {
            out6 = data_in[31:24];
        } else if (select_control[34:30] == 2) {
            out6 = data_in[23:16];
        } else if (select_control[34:30] == 1) {
            out6 = data_in[15:8];
        } else  {
            out6 = data_in[7:0];
        }
        if (select_control[29:25] == 23) {
            out5 = data_in[191:184];
        } else if (select_control[29:25] == 22) {
            out5 = data_in[183:176];
        } else if (select_control[29:25] == 21) {
            out5 = data_in[175:168];
        } else if (select_control[29:25] == 20) {
            out5 = data_in[167:160];
        } else if (select_control[29:25] == 19) {
            out5 = data_in[159:152];
        } else if (select_control[29:25] == 18) {
            out5 = data_in[151:144];
        } else if (select_control[29:25] == 17) {
            out5 = data_in[143:136];
        } else if (select_control[29:25] == 16) {
            out5 = data_in[135:128];
        } else if (select_control[29:25] == 15) {
            out5 = data_in[127:120];
        } else if (select_control[29:25] == 14) {
            out5 = data_in[119:112];
        } else if (select_control[29:25] == 13) {
            out5 = data_in[111:104];
        } else if (select_control[29:25] == 12) {
            out5 = data_in[103:96];
        } else if (select_control[29:25] == 11) {
            out5 = data_in[95:88];
        } else if (select_control[29:25] == 10) {
            out5 = data_in[87:80];
        } else if (select_control[29:25] == 9) {
            out5 = data_in[79:72];
        } else if (select_control[29:25] == 8) {
            out5 = data_in[71:64];
        } else if (select_control[29:25] == 7) {
            out5 = data_in[63:56];
        } else if (select_control[29:25] == 6) {
            out5 = data_in[55:48];
        } else if (select_control[29:25] == 5) {
            out5 = data_in[47:40];
        } else if (select_control[29:25] == 4) {
            out5 = data_in[39:32];
        } else if (select_control[29:25] == 3) {
            out5 = data_in[31:24];
        } else if (select_control[29:25] == 2) {
            out5 = data_in[23:16];
        } else if (select_control[29:25] == 1) {
            out5 = data_in[15:8];
        } else  {
            out5 = data_in[7:0];
        }
        if (select_control[24:20] == 23) {
            out4 = data_in[191:184];
        } else if (select_control[24:20] == 22) {
            out4 = data_in[183:176];
        } else if (select_control[24:20] == 21) {
            out4 = data_in[175:168];
        } else if (select_control[24:20] == 20) {
            out4 = data_in[167:160];
        } else if (select_control[24:20] == 19) {
            out4 = data_in[159:152];
        } else if (select_control[24:20] == 18) {
            out4 = data_in[151:144];
        } else if (select_control[24:20] == 17) {
            out4 = data_in[143:136];
        } else if (select_control[24:20] == 16) {
            out4 = data_in[135:128];
        } else if (select_control[24:20] == 15) {
            out4 = data_in[127:120];
        } else if (select_control[24:20] == 14) {
            out4 = data_in[119:112];
        } else if (select_control[24:20] == 13) {
            out4 = data_in[111:104];
        } else if (select_control[24:20] == 12) {
            out4 = data_in[103:96];
        } else if (select_control[24:20] == 11) {
            out4 = data_in[95:88];
        } else if (select_control[24:20] == 10) {
            out4 = data_in[87:80];
        } else if (select_control[24:20] == 9) {
            out4 = data_in[79:72];
        } else if (select_control[24:20] == 8) {
            out4 = data_in[71:64];
        } else if (select_control[24:20] == 7) {
            out4 = data_in[63:56];
        } else if (select_control[24:20] == 6) {
            out4 = data_in[55:48];
        } else if (select_control[24:20] == 5) {
            out4 = data_in[47:40];
        } else if (select_control[24:20] == 4) {
            out4 = data_in[39:32];
        } else if (select_control[24:20] == 3) {
            out4 = data_in[31:24];
        } else if (select_control[24:20] == 2) {
            out4 = data_in[23:16];
        } else if (select_control[24:20] == 1) {
            out4 = data_in[15:8];
        } else  {
            out4 = data_in[7:0];
        }
        if (select_control[19:15] == 23) {
            out3 = data_in[191:184];
        } else if (select_control[19:15] == 22) {
            out3 = data_in[183:176];
        } else if (select_control[19:15] == 21) {
            out3 = data_in[175:168];
        } else if (select_control[19:15] == 20) {
            out3 = data_in[167:160];
        } else if (select_control[19:15] == 19) {
            out3 = data_in[159:152];
        } else if (select_control[19:15] == 18) {
            out3 = data_in[151:144];
        } else if (select_control[19:15] == 17) {
            out3 = data_in[143:136];
        } else if (select_control[19:15] == 16) {
            out3 = data_in[135:128];
        } else if (select_control[19:15] == 15) {
            out3 = data_in[127:120];
        } else if (select_control[19:15] == 14) {
            out3 = data_in[119:112];
        } else if (select_control[19:15] == 13) {
            out3 = data_in[111:104];
        } else if (select_control[19:15] == 12) {
            out3 = data_in[103:96];
        } else if (select_control[19:15] == 11) {
            out3 = data_in[95:88];
        } else if (select_control[19:15] == 10) {
            out3 = data_in[87:80];
        } else if (select_control[19:15] == 9) {
            out3 = data_in[79:72];
        } else if (select_control[19:15] == 8) {
            out3 = data_in[71:64];
        } else if (select_control[19:15] == 7) {
            out3 = data_in[63:56];
        } else if (select_control[19:15] == 6) {
            out3 = data_in[55:48];
        } else if (select_control[19:15] == 5) {
            out3 = data_in[47:40];
        } else if (select_control[19:15] == 4) {
            out3 = data_in[39:32];
        } else if (select_control[19:15] == 3) {
            out3 = data_in[31:24];
        } else if (select_control[19:15] == 2) {
            out3 = data_in[23:16];
        } else if (select_control[19:15] == 1) {
            out3 = data_in[15:8];
        } else  {
            out3 = data_in[7:0];
        }
        if (select_control[14:10] == 23) {
            out2 = data_in[191:184];
        } else if (select_control[14:10] == 22) {
            out2 = data_in[183:176];
        } else if (select_control[14:10] == 21) {
            out2 = data_in[175:168];
        } else if (select_control[14:10] == 20) {
            out2 = data_in[167:160];
        } else if (select_control[14:10] == 19) {
            out2 = data_in[159:152];
        } else if (select_control[14:10] == 18) {
            out2 = data_in[151:144];
        } else if (select_control[14:10] == 17) {
            out2 = data_in[143:136];
        } else if (select_control[14:10] == 16) {
            out2 = data_in[135:128];
        } else if (select_control[14:10] == 15) {
            out2 = data_in[127:120];
        } else if (select_control[14:10] == 14) {
            out2 = data_in[119:112];
        } else if (select_control[14:10] == 13) {
            out2 = data_in[111:104];
        } else if (select_control[14:10] == 12) {
            out2 = data_in[103:96];
        } else if (select_control[14:10] == 11) {
            out2 = data_in[95:88];
        } else if (select_control[14:10] == 10) {
            out2 = data_in[87:80];
        } else if (select_control[14:10] == 9) {
            out2 = data_in[79:72];
        } else if (select_control[14:10] == 8) {
            out2 = data_in[71:64];
        } else if (select_control[14:10] == 7) {
            out2 = data_in[63:56];
        } else if (select_control[14:10] == 6) {
            out2 = data_in[55:48];
        } else if (select_control[14:10] == 5) {
            out2 = data_in[47:40];
        } else if (select_control[14:10] == 4) {
            out2 = data_in[39:32];
        } else if (select_control[14:10] == 3) {
            out2 = data_in[31:24];
        } else if (select_control[14:10] == 2) {
            out2 = data_in[23:16];
        } else if (select_control[14:10] == 1) {
            out2 = data_in[15:8];
        } else  {
            out2 = data_in[7:0];
        }
        if (select_control[9:5] == 23) {
            out1 = data_in[191:184];
        } else if (select_control[9:5] == 22) {
            out1 = data_in[183:176];
        } else if (select_control[9:5] == 21) {
            out1 = data_in[175:168];
        } else if (select_control[9:5] == 20) {
            out1 = data_in[167:160];
        } else if (select_control[9:5] == 19) {
            out1 = data_in[159:152];
        } else if (select_control[9:5] == 18) {
            out1 = data_in[151:144];
        } else if (select_control[9:5] == 17) {
            out1 = data_in[143:136];
        } else if (select_control[9:5] == 16) {
            out1 = data_in[135:128];
        } else if (select_control[9:5] == 15) {
            out1 = data_in[127:120];
        } else if (select_control[9:5] == 14) {
            out1 = data_in[119:112];
        } else if (select_control[9:5] == 13) {
            out1 = data_in[111:104];
        } else if (select_control[9:5] == 12) {
            out1 = data_in[103:96];
        } else if (select_control[9:5] == 11) {
            out1 = data_in[95:88];
        } else if (select_control[9:5] == 10) {
            out1 = data_in[87:80];
        } else if (select_control[9:5] == 9) {
            out1 = data_in[79:72];
        } else if (select_control[9:5] == 8) {
            out1 = data_in[71:64];
        } else if (select_control[9:5] == 7) {
            out1 = data_in[63:56];
        } else if (select_control[9:5] == 6) {
            out1 = data_in[55:48];
        } else if (select_control[9:5] == 5) {
            out1 = data_in[47:40];
        } else if (select_control[9:5] == 4) {
            out1 = data_in[39:32];
        } else if (select_control[9:5] == 3) {
            out1 = data_in[31:24];
        } else if (select_control[9:5] == 2) {
            out1 = data_in[23:16];
        } else if (select_control[9:5] == 1) {
            out1 = data_in[15:8];
        } else  {
            out1 = data_in[7:0];
        }
        if (select_control[4:0] == 23) {
            out0 = data_in[191:184];
        } else if (select_control[4:0] == 22) {
            out0 = data_in[183:176];
        } else if (select_control[4:0] == 21) {
            out0 = data_in[175:168];
        } else if (select_control[4:0] == 20) {
            out0 = data_in[167:160];
        } else if (select_control[4:0] == 19) {
            out0 = data_in[159:152];
        } else if (select_control[4:0] == 18) {
            out0 = data_in[151:144];
        } else if (select_control[4:0] == 17) {
            out0 = data_in[143:136];
        } else if (select_control[4:0] == 16) {
            out0 = data_in[135:128];
        } else if (select_control[4:0] == 15) {
            out0 = data_in[127:120];
        } else if (select_control[4:0] == 14) {
            out0 = data_in[119:112];
        } else if (select_control[4:0] == 13) {
            out0 = data_in[111:104];
        } else if (select_control[4:0] == 12) {
            out0 = data_in[103:96];
        } else if (select_control[4:0] == 11) {
            out0 = data_in[95:88];
        } else if (select_control[4:0] == 10) {
            out0 = data_in[87:80];
        } else if (select_control[4:0] == 9) {
            out0 = data_in[79:72];
        } else if (select_control[4:0] == 8) {
            out0 = data_in[71:64];
        } else if (select_control[4:0] == 7) {
            out0 = data_in[63:56];
        } else if (select_control[4:0] == 6) {
            out0 = data_in[55:48];
        } else if (select_control[4:0] == 5) {
            out0 = data_in[47:40];
        } else if (select_control[4:0] == 4) {
            out0 = data_in[39:32];
        } else if (select_control[4:0] == 3) {
            out0 = data_in[31:24];
        } else if (select_control[4:0] == 2) {
            out0 = data_in[23:16];
        } else if (select_control[4:0] == 1) {
            out0 = data_in[15:8];
        } else  {
            out0 = data_in[7:0];
        }

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

    apply {
        if (select_control[79:75] == 31) {
            out15 = data_in[255:248];
        } else if (select_control[79:75] == 30) {
            out15 = data_in[247:240];
        } else if (select_control[79:75] == 29) {
            out15 = data_in[239:232];
        } else if (select_control[79:75] == 28) {
            out15 = data_in[231:224];
        } else if (select_control[79:75] == 27) {
            out15 = data_in[223:216];
        } else if (select_control[79:75] == 26) {
            out15 = data_in[215:208];
        } else if (select_control[79:75] == 25) {
            out15 = data_in[207:200];
        } else if (select_control[79:75] == 24) {
            out15 = data_in[199:192];
        } else if (select_control[79:75] == 23) {
            out15 = data_in[191:184];
        } else if (select_control[79:75] == 22) {
            out15 = data_in[183:176];
        } else if (select_control[79:75] == 21) {
            out15 = data_in[175:168];
        } else if (select_control[79:75] == 20) {
            out15 = data_in[167:160];
        } else if (select_control[79:75] == 19) {
            out15 = data_in[159:152];
        } else if (select_control[79:75] == 18) {
            out15 = data_in[151:144];
        } else if (select_control[79:75] == 17) {
            out15 = data_in[143:136];
        } else if (select_control[79:75] == 16) {
            out15 = data_in[135:128];
        } else if (select_control[79:75] == 15) {
            out15 = data_in[127:120];
        } else if (select_control[79:75] == 14) {
            out15 = data_in[119:112];
        } else if (select_control[79:75] == 13) {
            out15 = data_in[111:104];
        } else if (select_control[79:75] == 12) {
            out15 = data_in[103:96];
        } else if (select_control[79:75] == 11) {
            out15 = data_in[95:88];
        } else if (select_control[79:75] == 10) {
            out15 = data_in[87:80];
        } else if (select_control[79:75] == 9) {
            out15 = data_in[79:72];
        } else if (select_control[79:75] == 8) {
            out15 = data_in[71:64];
        } else if (select_control[79:75] == 7) {
            out15 = data_in[63:56];
        } else if (select_control[79:75] == 6) {
            out15 = data_in[55:48];
        } else if (select_control[79:75] == 5) {
            out15 = data_in[47:40];
        } else if (select_control[79:75] == 4) {
            out15 = data_in[39:32];
        } else if (select_control[79:75] == 3) {
            out15 = data_in[31:24];
        } else if (select_control[79:75] == 2) {
            out15 = data_in[23:16];
        } else if (select_control[79:75] == 1) {
            out15 = data_in[15:8];
        } else  {
            out15 = data_in[7:0];
        }
        if (select_control[74:70] == 31) {
            out14 = data_in[255:248];
        } else if (select_control[74:70] == 30) {
            out14 = data_in[247:240];
        } else if (select_control[74:70] == 29) {
            out14 = data_in[239:232];
        } else if (select_control[74:70] == 28) {
            out14 = data_in[231:224];
        } else if (select_control[74:70] == 27) {
            out14 = data_in[223:216];
        } else if (select_control[74:70] == 26) {
            out14 = data_in[215:208];
        } else if (select_control[74:70] == 25) {
            out14 = data_in[207:200];
        } else if (select_control[74:70] == 24) {
            out14 = data_in[199:192];
        } else if (select_control[74:70] == 23) {
            out14 = data_in[191:184];
        } else if (select_control[74:70] == 22) {
            out14 = data_in[183:176];
        } else if (select_control[74:70] == 21) {
            out14 = data_in[175:168];
        } else if (select_control[74:70] == 20) {
            out14 = data_in[167:160];
        } else if (select_control[74:70] == 19) {
            out14 = data_in[159:152];
        } else if (select_control[74:70] == 18) {
            out14 = data_in[151:144];
        } else if (select_control[74:70] == 17) {
            out14 = data_in[143:136];
        } else if (select_control[74:70] == 16) {
            out14 = data_in[135:128];
        } else if (select_control[74:70] == 15) {
            out14 = data_in[127:120];
        } else if (select_control[74:70] == 14) {
            out14 = data_in[119:112];
        } else if (select_control[74:70] == 13) {
            out14 = data_in[111:104];
        } else if (select_control[74:70] == 12) {
            out14 = data_in[103:96];
        } else if (select_control[74:70] == 11) {
            out14 = data_in[95:88];
        } else if (select_control[74:70] == 10) {
            out14 = data_in[87:80];
        } else if (select_control[74:70] == 9) {
            out14 = data_in[79:72];
        } else if (select_control[74:70] == 8) {
            out14 = data_in[71:64];
        } else if (select_control[74:70] == 7) {
            out14 = data_in[63:56];
        } else if (select_control[74:70] == 6) {
            out14 = data_in[55:48];
        } else if (select_control[74:70] == 5) {
            out14 = data_in[47:40];
        } else if (select_control[74:70] == 4) {
            out14 = data_in[39:32];
        } else if (select_control[74:70] == 3) {
            out14 = data_in[31:24];
        } else if (select_control[74:70] == 2) {
            out14 = data_in[23:16];
        } else if (select_control[74:70] == 1) {
            out14 = data_in[15:8];
        } else  {
            out14 = data_in[7:0];
        }
        if (select_control[69:65] == 31) {
            out13 = data_in[255:248];
        } else if (select_control[69:65] == 30) {
            out13 = data_in[247:240];
        } else if (select_control[69:65] == 29) {
            out13 = data_in[239:232];
        } else if (select_control[69:65] == 28) {
            out13 = data_in[231:224];
        } else if (select_control[69:65] == 27) {
            out13 = data_in[223:216];
        } else if (select_control[69:65] == 26) {
            out13 = data_in[215:208];
        } else if (select_control[69:65] == 25) {
            out13 = data_in[207:200];
        } else if (select_control[69:65] == 24) {
            out13 = data_in[199:192];
        } else if (select_control[69:65] == 23) {
            out13 = data_in[191:184];
        } else if (select_control[69:65] == 22) {
            out13 = data_in[183:176];
        } else if (select_control[69:65] == 21) {
            out13 = data_in[175:168];
        } else if (select_control[69:65] == 20) {
            out13 = data_in[167:160];
        } else if (select_control[69:65] == 19) {
            out13 = data_in[159:152];
        } else if (select_control[69:65] == 18) {
            out13 = data_in[151:144];
        } else if (select_control[69:65] == 17) {
            out13 = data_in[143:136];
        } else if (select_control[69:65] == 16) {
            out13 = data_in[135:128];
        } else if (select_control[69:65] == 15) {
            out13 = data_in[127:120];
        } else if (select_control[69:65] == 14) {
            out13 = data_in[119:112];
        } else if (select_control[69:65] == 13) {
            out13 = data_in[111:104];
        } else if (select_control[69:65] == 12) {
            out13 = data_in[103:96];
        } else if (select_control[69:65] == 11) {
            out13 = data_in[95:88];
        } else if (select_control[69:65] == 10) {
            out13 = data_in[87:80];
        } else if (select_control[69:65] == 9) {
            out13 = data_in[79:72];
        } else if (select_control[69:65] == 8) {
            out13 = data_in[71:64];
        } else if (select_control[69:65] == 7) {
            out13 = data_in[63:56];
        } else if (select_control[69:65] == 6) {
            out13 = data_in[55:48];
        } else if (select_control[69:65] == 5) {
            out13 = data_in[47:40];
        } else if (select_control[69:65] == 4) {
            out13 = data_in[39:32];
        } else if (select_control[69:65] == 3) {
            out13 = data_in[31:24];
        } else if (select_control[69:65] == 2) {
            out13 = data_in[23:16];
        } else if (select_control[69:65] == 1) {
            out13 = data_in[15:8];
        } else  {
            out13 = data_in[7:0];
        }
        if (select_control[64:60] == 31) {
            out12 = data_in[255:248];
        } else if (select_control[64:60] == 30) {
            out12 = data_in[247:240];
        } else if (select_control[64:60] == 29) {
            out12 = data_in[239:232];
        } else if (select_control[64:60] == 28) {
            out12 = data_in[231:224];
        } else if (select_control[64:60] == 27) {
            out12 = data_in[223:216];
        } else if (select_control[64:60] == 26) {
            out12 = data_in[215:208];
        } else if (select_control[64:60] == 25) {
            out12 = data_in[207:200];
        } else if (select_control[64:60] == 24) {
            out12 = data_in[199:192];
        } else if (select_control[64:60] == 23) {
            out12 = data_in[191:184];
        } else if (select_control[64:60] == 22) {
            out12 = data_in[183:176];
        } else if (select_control[64:60] == 21) {
            out12 = data_in[175:168];
        } else if (select_control[64:60] == 20) {
            out12 = data_in[167:160];
        } else if (select_control[64:60] == 19) {
            out12 = data_in[159:152];
        } else if (select_control[64:60] == 18) {
            out12 = data_in[151:144];
        } else if (select_control[64:60] == 17) {
            out12 = data_in[143:136];
        } else if (select_control[64:60] == 16) {
            out12 = data_in[135:128];
        } else if (select_control[64:60] == 15) {
            out12 = data_in[127:120];
        } else if (select_control[64:60] == 14) {
            out12 = data_in[119:112];
        } else if (select_control[64:60] == 13) {
            out12 = data_in[111:104];
        } else if (select_control[64:60] == 12) {
            out12 = data_in[103:96];
        } else if (select_control[64:60] == 11) {
            out12 = data_in[95:88];
        } else if (select_control[64:60] == 10) {
            out12 = data_in[87:80];
        } else if (select_control[64:60] == 9) {
            out12 = data_in[79:72];
        } else if (select_control[64:60] == 8) {
            out12 = data_in[71:64];
        } else if (select_control[64:60] == 7) {
            out12 = data_in[63:56];
        } else if (select_control[64:60] == 6) {
            out12 = data_in[55:48];
        } else if (select_control[64:60] == 5) {
            out12 = data_in[47:40];
        } else if (select_control[64:60] == 4) {
            out12 = data_in[39:32];
        } else if (select_control[64:60] == 3) {
            out12 = data_in[31:24];
        } else if (select_control[64:60] == 2) {
            out12 = data_in[23:16];
        } else if (select_control[64:60] == 1) {
            out12 = data_in[15:8];
        } else  {
            out12 = data_in[7:0];
        }
        if (select_control[59:55] == 31) {
            out11 = data_in[255:248];
        } else if (select_control[59:55] == 30) {
            out11 = data_in[247:240];
        } else if (select_control[59:55] == 29) {
            out11 = data_in[239:232];
        } else if (select_control[59:55] == 28) {
            out11 = data_in[231:224];
        } else if (select_control[59:55] == 27) {
            out11 = data_in[223:216];
        } else if (select_control[59:55] == 26) {
            out11 = data_in[215:208];
        } else if (select_control[59:55] == 25) {
            out11 = data_in[207:200];
        } else if (select_control[59:55] == 24) {
            out11 = data_in[199:192];
        } else if (select_control[59:55] == 23) {
            out11 = data_in[191:184];
        } else if (select_control[59:55] == 22) {
            out11 = data_in[183:176];
        } else if (select_control[59:55] == 21) {
            out11 = data_in[175:168];
        } else if (select_control[59:55] == 20) {
            out11 = data_in[167:160];
        } else if (select_control[59:55] == 19) {
            out11 = data_in[159:152];
        } else if (select_control[59:55] == 18) {
            out11 = data_in[151:144];
        } else if (select_control[59:55] == 17) {
            out11 = data_in[143:136];
        } else if (select_control[59:55] == 16) {
            out11 = data_in[135:128];
        } else if (select_control[59:55] == 15) {
            out11 = data_in[127:120];
        } else if (select_control[59:55] == 14) {
            out11 = data_in[119:112];
        } else if (select_control[59:55] == 13) {
            out11 = data_in[111:104];
        } else if (select_control[59:55] == 12) {
            out11 = data_in[103:96];
        } else if (select_control[59:55] == 11) {
            out11 = data_in[95:88];
        } else if (select_control[59:55] == 10) {
            out11 = data_in[87:80];
        } else if (select_control[59:55] == 9) {
            out11 = data_in[79:72];
        } else if (select_control[59:55] == 8) {
            out11 = data_in[71:64];
        } else if (select_control[59:55] == 7) {
            out11 = data_in[63:56];
        } else if (select_control[59:55] == 6) {
            out11 = data_in[55:48];
        } else if (select_control[59:55] == 5) {
            out11 = data_in[47:40];
        } else if (select_control[59:55] == 4) {
            out11 = data_in[39:32];
        } else if (select_control[59:55] == 3) {
            out11 = data_in[31:24];
        } else if (select_control[59:55] == 2) {
            out11 = data_in[23:16];
        } else if (select_control[59:55] == 1) {
            out11 = data_in[15:8];
        } else  {
            out11 = data_in[7:0];
        }
        if (select_control[54:50] == 31) {
            out10 = data_in[255:248];
        } else if (select_control[54:50] == 30) {
            out10 = data_in[247:240];
        } else if (select_control[54:50] == 29) {
            out10 = data_in[239:232];
        } else if (select_control[54:50] == 28) {
            out10 = data_in[231:224];
        } else if (select_control[54:50] == 27) {
            out10 = data_in[223:216];
        } else if (select_control[54:50] == 26) {
            out10 = data_in[215:208];
        } else if (select_control[54:50] == 25) {
            out10 = data_in[207:200];
        } else if (select_control[54:50] == 24) {
            out10 = data_in[199:192];
        } else if (select_control[54:50] == 23) {
            out10 = data_in[191:184];
        } else if (select_control[54:50] == 22) {
            out10 = data_in[183:176];
        } else if (select_control[54:50] == 21) {
            out10 = data_in[175:168];
        } else if (select_control[54:50] == 20) {
            out10 = data_in[167:160];
        } else if (select_control[54:50] == 19) {
            out10 = data_in[159:152];
        } else if (select_control[54:50] == 18) {
            out10 = data_in[151:144];
        } else if (select_control[54:50] == 17) {
            out10 = data_in[143:136];
        } else if (select_control[54:50] == 16) {
            out10 = data_in[135:128];
        } else if (select_control[54:50] == 15) {
            out10 = data_in[127:120];
        } else if (select_control[54:50] == 14) {
            out10 = data_in[119:112];
        } else if (select_control[54:50] == 13) {
            out10 = data_in[111:104];
        } else if (select_control[54:50] == 12) {
            out10 = data_in[103:96];
        } else if (select_control[54:50] == 11) {
            out10 = data_in[95:88];
        } else if (select_control[54:50] == 10) {
            out10 = data_in[87:80];
        } else if (select_control[54:50] == 9) {
            out10 = data_in[79:72];
        } else if (select_control[54:50] == 8) {
            out10 = data_in[71:64];
        } else if (select_control[54:50] == 7) {
            out10 = data_in[63:56];
        } else if (select_control[54:50] == 6) {
            out10 = data_in[55:48];
        } else if (select_control[54:50] == 5) {
            out10 = data_in[47:40];
        } else if (select_control[54:50] == 4) {
            out10 = data_in[39:32];
        } else if (select_control[54:50] == 3) {
            out10 = data_in[31:24];
        } else if (select_control[54:50] == 2) {
            out10 = data_in[23:16];
        } else if (select_control[54:50] == 1) {
            out10 = data_in[15:8];
        } else  {
            out10 = data_in[7:0];
        }
        if (select_control[49:45] == 31) {
            out9 = data_in[255:248];
        } else if (select_control[49:45] == 30) {
            out9 = data_in[247:240];
        } else if (select_control[49:45] == 29) {
            out9 = data_in[239:232];
        } else if (select_control[49:45] == 28) {
            out9 = data_in[231:224];
        } else if (select_control[49:45] == 27) {
            out9 = data_in[223:216];
        } else if (select_control[49:45] == 26) {
            out9 = data_in[215:208];
        } else if (select_control[49:45] == 25) {
            out9 = data_in[207:200];
        } else if (select_control[49:45] == 24) {
            out9 = data_in[199:192];
        } else if (select_control[49:45] == 23) {
            out9 = data_in[191:184];
        } else if (select_control[49:45] == 22) {
            out9 = data_in[183:176];
        } else if (select_control[49:45] == 21) {
            out9 = data_in[175:168];
        } else if (select_control[49:45] == 20) {
            out9 = data_in[167:160];
        } else if (select_control[49:45] == 19) {
            out9 = data_in[159:152];
        } else if (select_control[49:45] == 18) {
            out9 = data_in[151:144];
        } else if (select_control[49:45] == 17) {
            out9 = data_in[143:136];
        } else if (select_control[49:45] == 16) {
            out9 = data_in[135:128];
        } else if (select_control[49:45] == 15) {
            out9 = data_in[127:120];
        } else if (select_control[49:45] == 14) {
            out9 = data_in[119:112];
        } else if (select_control[49:45] == 13) {
            out9 = data_in[111:104];
        } else if (select_control[49:45] == 12) {
            out9 = data_in[103:96];
        } else if (select_control[49:45] == 11) {
            out9 = data_in[95:88];
        } else if (select_control[49:45] == 10) {
            out9 = data_in[87:80];
        } else if (select_control[49:45] == 9) {
            out9 = data_in[79:72];
        } else if (select_control[49:45] == 8) {
            out9 = data_in[71:64];
        } else if (select_control[49:45] == 7) {
            out9 = data_in[63:56];
        } else if (select_control[49:45] == 6) {
            out9 = data_in[55:48];
        } else if (select_control[49:45] == 5) {
            out9 = data_in[47:40];
        } else if (select_control[49:45] == 4) {
            out9 = data_in[39:32];
        } else if (select_control[49:45] == 3) {
            out9 = data_in[31:24];
        } else if (select_control[49:45] == 2) {
            out9 = data_in[23:16];
        } else if (select_control[49:45] == 1) {
            out9 = data_in[15:8];
        } else  {
            out9 = data_in[7:0];
        }
        if (select_control[44:40] == 31) {
            out8 = data_in[255:248];
        } else if (select_control[44:40] == 30) {
            out8 = data_in[247:240];
        } else if (select_control[44:40] == 29) {
            out8 = data_in[239:232];
        } else if (select_control[44:40] == 28) {
            out8 = data_in[231:224];
        } else if (select_control[44:40] == 27) {
            out8 = data_in[223:216];
        } else if (select_control[44:40] == 26) {
            out8 = data_in[215:208];
        } else if (select_control[44:40] == 25) {
            out8 = data_in[207:200];
        } else if (select_control[44:40] == 24) {
            out8 = data_in[199:192];
        } else if (select_control[44:40] == 23) {
            out8 = data_in[191:184];
        } else if (select_control[44:40] == 22) {
            out8 = data_in[183:176];
        } else if (select_control[44:40] == 21) {
            out8 = data_in[175:168];
        } else if (select_control[44:40] == 20) {
            out8 = data_in[167:160];
        } else if (select_control[44:40] == 19) {
            out8 = data_in[159:152];
        } else if (select_control[44:40] == 18) {
            out8 = data_in[151:144];
        } else if (select_control[44:40] == 17) {
            out8 = data_in[143:136];
        } else if (select_control[44:40] == 16) {
            out8 = data_in[135:128];
        } else if (select_control[44:40] == 15) {
            out8 = data_in[127:120];
        } else if (select_control[44:40] == 14) {
            out8 = data_in[119:112];
        } else if (select_control[44:40] == 13) {
            out8 = data_in[111:104];
        } else if (select_control[44:40] == 12) {
            out8 = data_in[103:96];
        } else if (select_control[44:40] == 11) {
            out8 = data_in[95:88];
        } else if (select_control[44:40] == 10) {
            out8 = data_in[87:80];
        } else if (select_control[44:40] == 9) {
            out8 = data_in[79:72];
        } else if (select_control[44:40] == 8) {
            out8 = data_in[71:64];
        } else if (select_control[44:40] == 7) {
            out8 = data_in[63:56];
        } else if (select_control[44:40] == 6) {
            out8 = data_in[55:48];
        } else if (select_control[44:40] == 5) {
            out8 = data_in[47:40];
        } else if (select_control[44:40] == 4) {
            out8 = data_in[39:32];
        } else if (select_control[44:40] == 3) {
            out8 = data_in[31:24];
        } else if (select_control[44:40] == 2) {
            out8 = data_in[23:16];
        } else if (select_control[44:40] == 1) {
            out8 = data_in[15:8];
        } else  {
            out8 = data_in[7:0];
        }
        if (select_control[39:35] == 31) {
            out7 = data_in[255:248];
        } else if (select_control[39:35] == 30) {
            out7 = data_in[247:240];
        } else if (select_control[39:35] == 29) {
            out7 = data_in[239:232];
        } else if (select_control[39:35] == 28) {
            out7 = data_in[231:224];
        } else if (select_control[39:35] == 27) {
            out7 = data_in[223:216];
        } else if (select_control[39:35] == 26) {
            out7 = data_in[215:208];
        } else if (select_control[39:35] == 25) {
            out7 = data_in[207:200];
        } else if (select_control[39:35] == 24) {
            out7 = data_in[199:192];
        } else if (select_control[39:35] == 23) {
            out7 = data_in[191:184];
        } else if (select_control[39:35] == 22) {
            out7 = data_in[183:176];
        } else if (select_control[39:35] == 21) {
            out7 = data_in[175:168];
        } else if (select_control[39:35] == 20) {
            out7 = data_in[167:160];
        } else if (select_control[39:35] == 19) {
            out7 = data_in[159:152];
        } else if (select_control[39:35] == 18) {
            out7 = data_in[151:144];
        } else if (select_control[39:35] == 17) {
            out7 = data_in[143:136];
        } else if (select_control[39:35] == 16) {
            out7 = data_in[135:128];
        } else if (select_control[39:35] == 15) {
            out7 = data_in[127:120];
        } else if (select_control[39:35] == 14) {
            out7 = data_in[119:112];
        } else if (select_control[39:35] == 13) {
            out7 = data_in[111:104];
        } else if (select_control[39:35] == 12) {
            out7 = data_in[103:96];
        } else if (select_control[39:35] == 11) {
            out7 = data_in[95:88];
        } else if (select_control[39:35] == 10) {
            out7 = data_in[87:80];
        } else if (select_control[39:35] == 9) {
            out7 = data_in[79:72];
        } else if (select_control[39:35] == 8) {
            out7 = data_in[71:64];
        } else if (select_control[39:35] == 7) {
            out7 = data_in[63:56];
        } else if (select_control[39:35] == 6) {
            out7 = data_in[55:48];
        } else if (select_control[39:35] == 5) {
            out7 = data_in[47:40];
        } else if (select_control[39:35] == 4) {
            out7 = data_in[39:32];
        } else if (select_control[39:35] == 3) {
            out7 = data_in[31:24];
        } else if (select_control[39:35] == 2) {
            out7 = data_in[23:16];
        } else if (select_control[39:35] == 1) {
            out7 = data_in[15:8];
        } else  {
            out7 = data_in[7:0];
        }
        if (select_control[34:30] == 31) {
            out6 = data_in[255:248];
        } else if (select_control[34:30] == 30) {
            out6 = data_in[247:240];
        } else if (select_control[34:30] == 29) {
            out6 = data_in[239:232];
        } else if (select_control[34:30] == 28) {
            out6 = data_in[231:224];
        } else if (select_control[34:30] == 27) {
            out6 = data_in[223:216];
        } else if (select_control[34:30] == 26) {
            out6 = data_in[215:208];
        } else if (select_control[34:30] == 25) {
            out6 = data_in[207:200];
        } else if (select_control[34:30] == 24) {
            out6 = data_in[199:192];
        } else if (select_control[34:30] == 23) {
            out6 = data_in[191:184];
        } else if (select_control[34:30] == 22) {
            out6 = data_in[183:176];
        } else if (select_control[34:30] == 21) {
            out6 = data_in[175:168];
        } else if (select_control[34:30] == 20) {
            out6 = data_in[167:160];
        } else if (select_control[34:30] == 19) {
            out6 = data_in[159:152];
        } else if (select_control[34:30] == 18) {
            out6 = data_in[151:144];
        } else if (select_control[34:30] == 17) {
            out6 = data_in[143:136];
        } else if (select_control[34:30] == 16) {
            out6 = data_in[135:128];
        } else if (select_control[34:30] == 15) {
            out6 = data_in[127:120];
        } else if (select_control[34:30] == 14) {
            out6 = data_in[119:112];
        } else if (select_control[34:30] == 13) {
            out6 = data_in[111:104];
        } else if (select_control[34:30] == 12) {
            out6 = data_in[103:96];
        } else if (select_control[34:30] == 11) {
            out6 = data_in[95:88];
        } else if (select_control[34:30] == 10) {
            out6 = data_in[87:80];
        } else if (select_control[34:30] == 9) {
            out6 = data_in[79:72];
        } else if (select_control[34:30] == 8) {
            out6 = data_in[71:64];
        } else if (select_control[34:30] == 7) {
            out6 = data_in[63:56];
        } else if (select_control[34:30] == 6) {
            out6 = data_in[55:48];
        } else if (select_control[34:30] == 5) {
            out6 = data_in[47:40];
        } else if (select_control[34:30] == 4) {
            out6 = data_in[39:32];
        } else if (select_control[34:30] == 3) {
            out6 = data_in[31:24];
        } else if (select_control[34:30] == 2) {
            out6 = data_in[23:16];
        } else if (select_control[34:30] == 1) {
            out6 = data_in[15:8];
        } else  {
            out6 = data_in[7:0];
        }
        if (select_control[29:25] == 31) {
            out5 = data_in[255:248];
        } else if (select_control[29:25] == 30) {
            out5 = data_in[247:240];
        } else if (select_control[29:25] == 29) {
            out5 = data_in[239:232];
        } else if (select_control[29:25] == 28) {
            out5 = data_in[231:224];
        } else if (select_control[29:25] == 27) {
            out5 = data_in[223:216];
        } else if (select_control[29:25] == 26) {
            out5 = data_in[215:208];
        } else if (select_control[29:25] == 25) {
            out5 = data_in[207:200];
        } else if (select_control[29:25] == 24) {
            out5 = data_in[199:192];
        } else if (select_control[29:25] == 23) {
            out5 = data_in[191:184];
        } else if (select_control[29:25] == 22) {
            out5 = data_in[183:176];
        } else if (select_control[29:25] == 21) {
            out5 = data_in[175:168];
        } else if (select_control[29:25] == 20) {
            out5 = data_in[167:160];
        } else if (select_control[29:25] == 19) {
            out5 = data_in[159:152];
        } else if (select_control[29:25] == 18) {
            out5 = data_in[151:144];
        } else if (select_control[29:25] == 17) {
            out5 = data_in[143:136];
        } else if (select_control[29:25] == 16) {
            out5 = data_in[135:128];
        } else if (select_control[29:25] == 15) {
            out5 = data_in[127:120];
        } else if (select_control[29:25] == 14) {
            out5 = data_in[119:112];
        } else if (select_control[29:25] == 13) {
            out5 = data_in[111:104];
        } else if (select_control[29:25] == 12) {
            out5 = data_in[103:96];
        } else if (select_control[29:25] == 11) {
            out5 = data_in[95:88];
        } else if (select_control[29:25] == 10) {
            out5 = data_in[87:80];
        } else if (select_control[29:25] == 9) {
            out5 = data_in[79:72];
        } else if (select_control[29:25] == 8) {
            out5 = data_in[71:64];
        } else if (select_control[29:25] == 7) {
            out5 = data_in[63:56];
        } else if (select_control[29:25] == 6) {
            out5 = data_in[55:48];
        } else if (select_control[29:25] == 5) {
            out5 = data_in[47:40];
        } else if (select_control[29:25] == 4) {
            out5 = data_in[39:32];
        } else if (select_control[29:25] == 3) {
            out5 = data_in[31:24];
        } else if (select_control[29:25] == 2) {
            out5 = data_in[23:16];
        } else if (select_control[29:25] == 1) {
            out5 = data_in[15:8];
        } else  {
            out5 = data_in[7:0];
        }
        if (select_control[24:20] == 31) {
            out4 = data_in[255:248];
        } else if (select_control[24:20] == 30) {
            out4 = data_in[247:240];
        } else if (select_control[24:20] == 29) {
            out4 = data_in[239:232];
        } else if (select_control[24:20] == 28) {
            out4 = data_in[231:224];
        } else if (select_control[24:20] == 27) {
            out4 = data_in[223:216];
        } else if (select_control[24:20] == 26) {
            out4 = data_in[215:208];
        } else if (select_control[24:20] == 25) {
            out4 = data_in[207:200];
        } else if (select_control[24:20] == 24) {
            out4 = data_in[199:192];
        } else if (select_control[24:20] == 23) {
            out4 = data_in[191:184];
        } else if (select_control[24:20] == 22) {
            out4 = data_in[183:176];
        } else if (select_control[24:20] == 21) {
            out4 = data_in[175:168];
        } else if (select_control[24:20] == 20) {
            out4 = data_in[167:160];
        } else if (select_control[24:20] == 19) {
            out4 = data_in[159:152];
        } else if (select_control[24:20] == 18) {
            out4 = data_in[151:144];
        } else if (select_control[24:20] == 17) {
            out4 = data_in[143:136];
        } else if (select_control[24:20] == 16) {
            out4 = data_in[135:128];
        } else if (select_control[24:20] == 15) {
            out4 = data_in[127:120];
        } else if (select_control[24:20] == 14) {
            out4 = data_in[119:112];
        } else if (select_control[24:20] == 13) {
            out4 = data_in[111:104];
        } else if (select_control[24:20] == 12) {
            out4 = data_in[103:96];
        } else if (select_control[24:20] == 11) {
            out4 = data_in[95:88];
        } else if (select_control[24:20] == 10) {
            out4 = data_in[87:80];
        } else if (select_control[24:20] == 9) {
            out4 = data_in[79:72];
        } else if (select_control[24:20] == 8) {
            out4 = data_in[71:64];
        } else if (select_control[24:20] == 7) {
            out4 = data_in[63:56];
        } else if (select_control[24:20] == 6) {
            out4 = data_in[55:48];
        } else if (select_control[24:20] == 5) {
            out4 = data_in[47:40];
        } else if (select_control[24:20] == 4) {
            out4 = data_in[39:32];
        } else if (select_control[24:20] == 3) {
            out4 = data_in[31:24];
        } else if (select_control[24:20] == 2) {
            out4 = data_in[23:16];
        } else if (select_control[24:20] == 1) {
            out4 = data_in[15:8];
        } else  {
            out4 = data_in[7:0];
        }
        if (select_control[19:15] == 31) {
            out3 = data_in[255:248];
        } else if (select_control[19:15] == 30) {
            out3 = data_in[247:240];
        } else if (select_control[19:15] == 29) {
            out3 = data_in[239:232];
        } else if (select_control[19:15] == 28) {
            out3 = data_in[231:224];
        } else if (select_control[19:15] == 27) {
            out3 = data_in[223:216];
        } else if (select_control[19:15] == 26) {
            out3 = data_in[215:208];
        } else if (select_control[19:15] == 25) {
            out3 = data_in[207:200];
        } else if (select_control[19:15] == 24) {
            out3 = data_in[199:192];
        } else if (select_control[19:15] == 23) {
            out3 = data_in[191:184];
        } else if (select_control[19:15] == 22) {
            out3 = data_in[183:176];
        } else if (select_control[19:15] == 21) {
            out3 = data_in[175:168];
        } else if (select_control[19:15] == 20) {
            out3 = data_in[167:160];
        } else if (select_control[19:15] == 19) {
            out3 = data_in[159:152];
        } else if (select_control[19:15] == 18) {
            out3 = data_in[151:144];
        } else if (select_control[19:15] == 17) {
            out3 = data_in[143:136];
        } else if (select_control[19:15] == 16) {
            out3 = data_in[135:128];
        } else if (select_control[19:15] == 15) {
            out3 = data_in[127:120];
        } else if (select_control[19:15] == 14) {
            out3 = data_in[119:112];
        } else if (select_control[19:15] == 13) {
            out3 = data_in[111:104];
        } else if (select_control[19:15] == 12) {
            out3 = data_in[103:96];
        } else if (select_control[19:15] == 11) {
            out3 = data_in[95:88];
        } else if (select_control[19:15] == 10) {
            out3 = data_in[87:80];
        } else if (select_control[19:15] == 9) {
            out3 = data_in[79:72];
        } else if (select_control[19:15] == 8) {
            out3 = data_in[71:64];
        } else if (select_control[19:15] == 7) {
            out3 = data_in[63:56];
        } else if (select_control[19:15] == 6) {
            out3 = data_in[55:48];
        } else if (select_control[19:15] == 5) {
            out3 = data_in[47:40];
        } else if (select_control[19:15] == 4) {
            out3 = data_in[39:32];
        } else if (select_control[19:15] == 3) {
            out3 = data_in[31:24];
        } else if (select_control[19:15] == 2) {
            out3 = data_in[23:16];
        } else if (select_control[19:15] == 1) {
            out3 = data_in[15:8];
        } else  {
            out3 = data_in[7:0];
        }
        if (select_control[14:10] == 31) {
            out2 = data_in[255:248];
        } else if (select_control[14:10] == 30) {
            out2 = data_in[247:240];
        } else if (select_control[14:10] == 29) {
            out2 = data_in[239:232];
        } else if (select_control[14:10] == 28) {
            out2 = data_in[231:224];
        } else if (select_control[14:10] == 27) {
            out2 = data_in[223:216];
        } else if (select_control[14:10] == 26) {
            out2 = data_in[215:208];
        } else if (select_control[14:10] == 25) {
            out2 = data_in[207:200];
        } else if (select_control[14:10] == 24) {
            out2 = data_in[199:192];
        } else if (select_control[14:10] == 23) {
            out2 = data_in[191:184];
        } else if (select_control[14:10] == 22) {
            out2 = data_in[183:176];
        } else if (select_control[14:10] == 21) {
            out2 = data_in[175:168];
        } else if (select_control[14:10] == 20) {
            out2 = data_in[167:160];
        } else if (select_control[14:10] == 19) {
            out2 = data_in[159:152];
        } else if (select_control[14:10] == 18) {
            out2 = data_in[151:144];
        } else if (select_control[14:10] == 17) {
            out2 = data_in[143:136];
        } else if (select_control[14:10] == 16) {
            out2 = data_in[135:128];
        } else if (select_control[14:10] == 15) {
            out2 = data_in[127:120];
        } else if (select_control[14:10] == 14) {
            out2 = data_in[119:112];
        } else if (select_control[14:10] == 13) {
            out2 = data_in[111:104];
        } else if (select_control[14:10] == 12) {
            out2 = data_in[103:96];
        } else if (select_control[14:10] == 11) {
            out2 = data_in[95:88];
        } else if (select_control[14:10] == 10) {
            out2 = data_in[87:80];
        } else if (select_control[14:10] == 9) {
            out2 = data_in[79:72];
        } else if (select_control[14:10] == 8) {
            out2 = data_in[71:64];
        } else if (select_control[14:10] == 7) {
            out2 = data_in[63:56];
        } else if (select_control[14:10] == 6) {
            out2 = data_in[55:48];
        } else if (select_control[14:10] == 5) {
            out2 = data_in[47:40];
        } else if (select_control[14:10] == 4) {
            out2 = data_in[39:32];
        } else if (select_control[14:10] == 3) {
            out2 = data_in[31:24];
        } else if (select_control[14:10] == 2) {
            out2 = data_in[23:16];
        } else if (select_control[14:10] == 1) {
            out2 = data_in[15:8];
        } else  {
            out2 = data_in[7:0];
        }
        if (select_control[9:5] == 31) {
            out1 = data_in[255:248];
        } else if (select_control[9:5] == 30) {
            out1 = data_in[247:240];
        } else if (select_control[9:5] == 29) {
            out1 = data_in[239:232];
        } else if (select_control[9:5] == 28) {
            out1 = data_in[231:224];
        } else if (select_control[9:5] == 27) {
            out1 = data_in[223:216];
        } else if (select_control[9:5] == 26) {
            out1 = data_in[215:208];
        } else if (select_control[9:5] == 25) {
            out1 = data_in[207:200];
        } else if (select_control[9:5] == 24) {
            out1 = data_in[199:192];
        } else if (select_control[9:5] == 23) {
            out1 = data_in[191:184];
        } else if (select_control[9:5] == 22) {
            out1 = data_in[183:176];
        } else if (select_control[9:5] == 21) {
            out1 = data_in[175:168];
        } else if (select_control[9:5] == 20) {
            out1 = data_in[167:160];
        } else if (select_control[9:5] == 19) {
            out1 = data_in[159:152];
        } else if (select_control[9:5] == 18) {
            out1 = data_in[151:144];
        } else if (select_control[9:5] == 17) {
            out1 = data_in[143:136];
        } else if (select_control[9:5] == 16) {
            out1 = data_in[135:128];
        } else if (select_control[9:5] == 15) {
            out1 = data_in[127:120];
        } else if (select_control[9:5] == 14) {
            out1 = data_in[119:112];
        } else if (select_control[9:5] == 13) {
            out1 = data_in[111:104];
        } else if (select_control[9:5] == 12) {
            out1 = data_in[103:96];
        } else if (select_control[9:5] == 11) {
            out1 = data_in[95:88];
        } else if (select_control[9:5] == 10) {
            out1 = data_in[87:80];
        } else if (select_control[9:5] == 9) {
            out1 = data_in[79:72];
        } else if (select_control[9:5] == 8) {
            out1 = data_in[71:64];
        } else if (select_control[9:5] == 7) {
            out1 = data_in[63:56];
        } else if (select_control[9:5] == 6) {
            out1 = data_in[55:48];
        } else if (select_control[9:5] == 5) {
            out1 = data_in[47:40];
        } else if (select_control[9:5] == 4) {
            out1 = data_in[39:32];
        } else if (select_control[9:5] == 3) {
            out1 = data_in[31:24];
        } else if (select_control[9:5] == 2) {
            out1 = data_in[23:16];
        } else if (select_control[9:5] == 1) {
            out1 = data_in[15:8];
        } else  {
            out1 = data_in[7:0];
        }
        if (select_control[4:0] == 31) {
            out0 = data_in[255:248];
        } else if (select_control[4:0] == 30) {
            out0 = data_in[247:240];
        } else if (select_control[4:0] == 29) {
            out0 = data_in[239:232];
        } else if (select_control[4:0] == 28) {
            out0 = data_in[231:224];
        } else if (select_control[4:0] == 27) {
            out0 = data_in[223:216];
        } else if (select_control[4:0] == 26) {
            out0 = data_in[215:208];
        } else if (select_control[4:0] == 25) {
            out0 = data_in[207:200];
        } else if (select_control[4:0] == 24) {
            out0 = data_in[199:192];
        } else if (select_control[4:0] == 23) {
            out0 = data_in[191:184];
        } else if (select_control[4:0] == 22) {
            out0 = data_in[183:176];
        } else if (select_control[4:0] == 21) {
            out0 = data_in[175:168];
        } else if (select_control[4:0] == 20) {
            out0 = data_in[167:160];
        } else if (select_control[4:0] == 19) {
            out0 = data_in[159:152];
        } else if (select_control[4:0] == 18) {
            out0 = data_in[151:144];
        } else if (select_control[4:0] == 17) {
            out0 = data_in[143:136];
        } else if (select_control[4:0] == 16) {
            out0 = data_in[135:128];
        } else if (select_control[4:0] == 15) {
            out0 = data_in[127:120];
        } else if (select_control[4:0] == 14) {
            out0 = data_in[119:112];
        } else if (select_control[4:0] == 13) {
            out0 = data_in[111:104];
        } else if (select_control[4:0] == 12) {
            out0 = data_in[103:96];
        } else if (select_control[4:0] == 11) {
            out0 = data_in[95:88];
        } else if (select_control[4:0] == 10) {
            out0 = data_in[87:80];
        } else if (select_control[4:0] == 9) {
            out0 = data_in[79:72];
        } else if (select_control[4:0] == 8) {
            out0 = data_in[71:64];
        } else if (select_control[4:0] == 7) {
            out0 = data_in[63:56];
        } else if (select_control[4:0] == 6) {
            out0 = data_in[55:48];
        } else if (select_control[4:0] == 5) {
            out0 = data_in[47:40];
        } else if (select_control[4:0] == 4) {
            out0 = data_in[39:32];
        } else if (select_control[4:0] == 3) {
            out0 = data_in[31:24];
        } else if (select_control[4:0] == 2) {
            out0 = data_in[23:16];
        } else if (select_control[4:0] == 1) {
            out0 = data_in[15:8];
        } else  {
            out0 = data_in[7:0];
        }

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

    apply {
        if (select_control[119:115] == 31) {
            out23 = data_in[255:248];
        } else if (select_control[119:115] == 30) {
            out23 = data_in[247:240];
        } else if (select_control[119:115] == 29) {
            out23 = data_in[239:232];
        } else if (select_control[119:115] == 28) {
            out23 = data_in[231:224];
        } else if (select_control[119:115] == 27) {
            out23 = data_in[223:216];
        } else if (select_control[119:115] == 26) {
            out23 = data_in[215:208];
        } else if (select_control[119:115] == 25) {
            out23 = data_in[207:200];
        } else if (select_control[119:115] == 24) {
            out23 = data_in[199:192];
        } else if (select_control[119:115] == 23) {
            out23 = data_in[191:184];
        } else if (select_control[119:115] == 22) {
            out23 = data_in[183:176];
        } else if (select_control[119:115] == 21) {
            out23 = data_in[175:168];
        } else if (select_control[119:115] == 20) {
            out23 = data_in[167:160];
        } else if (select_control[119:115] == 19) {
            out23 = data_in[159:152];
        } else if (select_control[119:115] == 18) {
            out23 = data_in[151:144];
        } else if (select_control[119:115] == 17) {
            out23 = data_in[143:136];
        } else if (select_control[119:115] == 16) {
            out23 = data_in[135:128];
        } else if (select_control[119:115] == 15) {
            out23 = data_in[127:120];
        } else if (select_control[119:115] == 14) {
            out23 = data_in[119:112];
        } else if (select_control[119:115] == 13) {
            out23 = data_in[111:104];
        } else if (select_control[119:115] == 12) {
            out23 = data_in[103:96];
        } else if (select_control[119:115] == 11) {
            out23 = data_in[95:88];
        } else if (select_control[119:115] == 10) {
            out23 = data_in[87:80];
        } else if (select_control[119:115] == 9) {
            out23 = data_in[79:72];
        } else if (select_control[119:115] == 8) {
            out23 = data_in[71:64];
        } else if (select_control[119:115] == 7) {
            out23 = data_in[63:56];
        } else if (select_control[119:115] == 6) {
            out23 = data_in[55:48];
        } else if (select_control[119:115] == 5) {
            out23 = data_in[47:40];
        } else if (select_control[119:115] == 4) {
            out23 = data_in[39:32];
        } else if (select_control[119:115] == 3) {
            out23 = data_in[31:24];
        } else if (select_control[119:115] == 2) {
            out23 = data_in[23:16];
        } else if (select_control[119:115] == 1) {
            out23 = data_in[15:8];
        } else  {
            out23 = data_in[7:0];
        }
        if (select_control[114:110] == 31) {
            out22 = data_in[255:248];
        } else if (select_control[114:110] == 30) {
            out22 = data_in[247:240];
        } else if (select_control[114:110] == 29) {
            out22 = data_in[239:232];
        } else if (select_control[114:110] == 28) {
            out22 = data_in[231:224];
        } else if (select_control[114:110] == 27) {
            out22 = data_in[223:216];
        } else if (select_control[114:110] == 26) {
            out22 = data_in[215:208];
        } else if (select_control[114:110] == 25) {
            out22 = data_in[207:200];
        } else if (select_control[114:110] == 24) {
            out22 = data_in[199:192];
        } else if (select_control[114:110] == 23) {
            out22 = data_in[191:184];
        } else if (select_control[114:110] == 22) {
            out22 = data_in[183:176];
        } else if (select_control[114:110] == 21) {
            out22 = data_in[175:168];
        } else if (select_control[114:110] == 20) {
            out22 = data_in[167:160];
        } else if (select_control[114:110] == 19) {
            out22 = data_in[159:152];
        } else if (select_control[114:110] == 18) {
            out22 = data_in[151:144];
        } else if (select_control[114:110] == 17) {
            out22 = data_in[143:136];
        } else if (select_control[114:110] == 16) {
            out22 = data_in[135:128];
        } else if (select_control[114:110] == 15) {
            out22 = data_in[127:120];
        } else if (select_control[114:110] == 14) {
            out22 = data_in[119:112];
        } else if (select_control[114:110] == 13) {
            out22 = data_in[111:104];
        } else if (select_control[114:110] == 12) {
            out22 = data_in[103:96];
        } else if (select_control[114:110] == 11) {
            out22 = data_in[95:88];
        } else if (select_control[114:110] == 10) {
            out22 = data_in[87:80];
        } else if (select_control[114:110] == 9) {
            out22 = data_in[79:72];
        } else if (select_control[114:110] == 8) {
            out22 = data_in[71:64];
        } else if (select_control[114:110] == 7) {
            out22 = data_in[63:56];
        } else if (select_control[114:110] == 6) {
            out22 = data_in[55:48];
        } else if (select_control[114:110] == 5) {
            out22 = data_in[47:40];
        } else if (select_control[114:110] == 4) {
            out22 = data_in[39:32];
        } else if (select_control[114:110] == 3) {
            out22 = data_in[31:24];
        } else if (select_control[114:110] == 2) {
            out22 = data_in[23:16];
        } else if (select_control[114:110] == 1) {
            out22 = data_in[15:8];
        } else  {
            out22 = data_in[7:0];
        }
        if (select_control[109:105] == 31) {
            out21 = data_in[255:248];
        } else if (select_control[109:105] == 30) {
            out21 = data_in[247:240];
        } else if (select_control[109:105] == 29) {
            out21 = data_in[239:232];
        } else if (select_control[109:105] == 28) {
            out21 = data_in[231:224];
        } else if (select_control[109:105] == 27) {
            out21 = data_in[223:216];
        } else if (select_control[109:105] == 26) {
            out21 = data_in[215:208];
        } else if (select_control[109:105] == 25) {
            out21 = data_in[207:200];
        } else if (select_control[109:105] == 24) {
            out21 = data_in[199:192];
        } else if (select_control[109:105] == 23) {
            out21 = data_in[191:184];
        } else if (select_control[109:105] == 22) {
            out21 = data_in[183:176];
        } else if (select_control[109:105] == 21) {
            out21 = data_in[175:168];
        } else if (select_control[109:105] == 20) {
            out21 = data_in[167:160];
        } else if (select_control[109:105] == 19) {
            out21 = data_in[159:152];
        } else if (select_control[109:105] == 18) {
            out21 = data_in[151:144];
        } else if (select_control[109:105] == 17) {
            out21 = data_in[143:136];
        } else if (select_control[109:105] == 16) {
            out21 = data_in[135:128];
        } else if (select_control[109:105] == 15) {
            out21 = data_in[127:120];
        } else if (select_control[109:105] == 14) {
            out21 = data_in[119:112];
        } else if (select_control[109:105] == 13) {
            out21 = data_in[111:104];
        } else if (select_control[109:105] == 12) {
            out21 = data_in[103:96];
        } else if (select_control[109:105] == 11) {
            out21 = data_in[95:88];
        } else if (select_control[109:105] == 10) {
            out21 = data_in[87:80];
        } else if (select_control[109:105] == 9) {
            out21 = data_in[79:72];
        } else if (select_control[109:105] == 8) {
            out21 = data_in[71:64];
        } else if (select_control[109:105] == 7) {
            out21 = data_in[63:56];
        } else if (select_control[109:105] == 6) {
            out21 = data_in[55:48];
        } else if (select_control[109:105] == 5) {
            out21 = data_in[47:40];
        } else if (select_control[109:105] == 4) {
            out21 = data_in[39:32];
        } else if (select_control[109:105] == 3) {
            out21 = data_in[31:24];
        } else if (select_control[109:105] == 2) {
            out21 = data_in[23:16];
        } else if (select_control[109:105] == 1) {
            out21 = data_in[15:8];
        } else  {
            out21 = data_in[7:0];
        }
        if (select_control[104:100] == 31) {
            out20 = data_in[255:248];
        } else if (select_control[104:100] == 30) {
            out20 = data_in[247:240];
        } else if (select_control[104:100] == 29) {
            out20 = data_in[239:232];
        } else if (select_control[104:100] == 28) {
            out20 = data_in[231:224];
        } else if (select_control[104:100] == 27) {
            out20 = data_in[223:216];
        } else if (select_control[104:100] == 26) {
            out20 = data_in[215:208];
        } else if (select_control[104:100] == 25) {
            out20 = data_in[207:200];
        } else if (select_control[104:100] == 24) {
            out20 = data_in[199:192];
        } else if (select_control[104:100] == 23) {
            out20 = data_in[191:184];
        } else if (select_control[104:100] == 22) {
            out20 = data_in[183:176];
        } else if (select_control[104:100] == 21) {
            out20 = data_in[175:168];
        } else if (select_control[104:100] == 20) {
            out20 = data_in[167:160];
        } else if (select_control[104:100] == 19) {
            out20 = data_in[159:152];
        } else if (select_control[104:100] == 18) {
            out20 = data_in[151:144];
        } else if (select_control[104:100] == 17) {
            out20 = data_in[143:136];
        } else if (select_control[104:100] == 16) {
            out20 = data_in[135:128];
        } else if (select_control[104:100] == 15) {
            out20 = data_in[127:120];
        } else if (select_control[104:100] == 14) {
            out20 = data_in[119:112];
        } else if (select_control[104:100] == 13) {
            out20 = data_in[111:104];
        } else if (select_control[104:100] == 12) {
            out20 = data_in[103:96];
        } else if (select_control[104:100] == 11) {
            out20 = data_in[95:88];
        } else if (select_control[104:100] == 10) {
            out20 = data_in[87:80];
        } else if (select_control[104:100] == 9) {
            out20 = data_in[79:72];
        } else if (select_control[104:100] == 8) {
            out20 = data_in[71:64];
        } else if (select_control[104:100] == 7) {
            out20 = data_in[63:56];
        } else if (select_control[104:100] == 6) {
            out20 = data_in[55:48];
        } else if (select_control[104:100] == 5) {
            out20 = data_in[47:40];
        } else if (select_control[104:100] == 4) {
            out20 = data_in[39:32];
        } else if (select_control[104:100] == 3) {
            out20 = data_in[31:24];
        } else if (select_control[104:100] == 2) {
            out20 = data_in[23:16];
        } else if (select_control[104:100] == 1) {
            out20 = data_in[15:8];
        } else  {
            out20 = data_in[7:0];
        }
        if (select_control[99:95] == 31) {
            out19 = data_in[255:248];
        } else if (select_control[99:95] == 30) {
            out19 = data_in[247:240];
        } else if (select_control[99:95] == 29) {
            out19 = data_in[239:232];
        } else if (select_control[99:95] == 28) {
            out19 = data_in[231:224];
        } else if (select_control[99:95] == 27) {
            out19 = data_in[223:216];
        } else if (select_control[99:95] == 26) {
            out19 = data_in[215:208];
        } else if (select_control[99:95] == 25) {
            out19 = data_in[207:200];
        } else if (select_control[99:95] == 24) {
            out19 = data_in[199:192];
        } else if (select_control[99:95] == 23) {
            out19 = data_in[191:184];
        } else if (select_control[99:95] == 22) {
            out19 = data_in[183:176];
        } else if (select_control[99:95] == 21) {
            out19 = data_in[175:168];
        } else if (select_control[99:95] == 20) {
            out19 = data_in[167:160];
        } else if (select_control[99:95] == 19) {
            out19 = data_in[159:152];
        } else if (select_control[99:95] == 18) {
            out19 = data_in[151:144];
        } else if (select_control[99:95] == 17) {
            out19 = data_in[143:136];
        } else if (select_control[99:95] == 16) {
            out19 = data_in[135:128];
        } else if (select_control[99:95] == 15) {
            out19 = data_in[127:120];
        } else if (select_control[99:95] == 14) {
            out19 = data_in[119:112];
        } else if (select_control[99:95] == 13) {
            out19 = data_in[111:104];
        } else if (select_control[99:95] == 12) {
            out19 = data_in[103:96];
        } else if (select_control[99:95] == 11) {
            out19 = data_in[95:88];
        } else if (select_control[99:95] == 10) {
            out19 = data_in[87:80];
        } else if (select_control[99:95] == 9) {
            out19 = data_in[79:72];
        } else if (select_control[99:95] == 8) {
            out19 = data_in[71:64];
        } else if (select_control[99:95] == 7) {
            out19 = data_in[63:56];
        } else if (select_control[99:95] == 6) {
            out19 = data_in[55:48];
        } else if (select_control[99:95] == 5) {
            out19 = data_in[47:40];
        } else if (select_control[99:95] == 4) {
            out19 = data_in[39:32];
        } else if (select_control[99:95] == 3) {
            out19 = data_in[31:24];
        } else if (select_control[99:95] == 2) {
            out19 = data_in[23:16];
        } else if (select_control[99:95] == 1) {
            out19 = data_in[15:8];
        } else  {
            out19 = data_in[7:0];
        }
        if (select_control[94:90] == 31) {
            out18 = data_in[255:248];
        } else if (select_control[94:90] == 30) {
            out18 = data_in[247:240];
        } else if (select_control[94:90] == 29) {
            out18 = data_in[239:232];
        } else if (select_control[94:90] == 28) {
            out18 = data_in[231:224];
        } else if (select_control[94:90] == 27) {
            out18 = data_in[223:216];
        } else if (select_control[94:90] == 26) {
            out18 = data_in[215:208];
        } else if (select_control[94:90] == 25) {
            out18 = data_in[207:200];
        } else if (select_control[94:90] == 24) {
            out18 = data_in[199:192];
        } else if (select_control[94:90] == 23) {
            out18 = data_in[191:184];
        } else if (select_control[94:90] == 22) {
            out18 = data_in[183:176];
        } else if (select_control[94:90] == 21) {
            out18 = data_in[175:168];
        } else if (select_control[94:90] == 20) {
            out18 = data_in[167:160];
        } else if (select_control[94:90] == 19) {
            out18 = data_in[159:152];
        } else if (select_control[94:90] == 18) {
            out18 = data_in[151:144];
        } else if (select_control[94:90] == 17) {
            out18 = data_in[143:136];
        } else if (select_control[94:90] == 16) {
            out18 = data_in[135:128];
        } else if (select_control[94:90] == 15) {
            out18 = data_in[127:120];
        } else if (select_control[94:90] == 14) {
            out18 = data_in[119:112];
        } else if (select_control[94:90] == 13) {
            out18 = data_in[111:104];
        } else if (select_control[94:90] == 12) {
            out18 = data_in[103:96];
        } else if (select_control[94:90] == 11) {
            out18 = data_in[95:88];
        } else if (select_control[94:90] == 10) {
            out18 = data_in[87:80];
        } else if (select_control[94:90] == 9) {
            out18 = data_in[79:72];
        } else if (select_control[94:90] == 8) {
            out18 = data_in[71:64];
        } else if (select_control[94:90] == 7) {
            out18 = data_in[63:56];
        } else if (select_control[94:90] == 6) {
            out18 = data_in[55:48];
        } else if (select_control[94:90] == 5) {
            out18 = data_in[47:40];
        } else if (select_control[94:90] == 4) {
            out18 = data_in[39:32];
        } else if (select_control[94:90] == 3) {
            out18 = data_in[31:24];
        } else if (select_control[94:90] == 2) {
            out18 = data_in[23:16];
        } else if (select_control[94:90] == 1) {
            out18 = data_in[15:8];
        } else  {
            out18 = data_in[7:0];
        }
        if (select_control[89:85] == 31) {
            out17 = data_in[255:248];
        } else if (select_control[89:85] == 30) {
            out17 = data_in[247:240];
        } else if (select_control[89:85] == 29) {
            out17 = data_in[239:232];
        } else if (select_control[89:85] == 28) {
            out17 = data_in[231:224];
        } else if (select_control[89:85] == 27) {
            out17 = data_in[223:216];
        } else if (select_control[89:85] == 26) {
            out17 = data_in[215:208];
        } else if (select_control[89:85] == 25) {
            out17 = data_in[207:200];
        } else if (select_control[89:85] == 24) {
            out17 = data_in[199:192];
        } else if (select_control[89:85] == 23) {
            out17 = data_in[191:184];
        } else if (select_control[89:85] == 22) {
            out17 = data_in[183:176];
        } else if (select_control[89:85] == 21) {
            out17 = data_in[175:168];
        } else if (select_control[89:85] == 20) {
            out17 = data_in[167:160];
        } else if (select_control[89:85] == 19) {
            out17 = data_in[159:152];
        } else if (select_control[89:85] == 18) {
            out17 = data_in[151:144];
        } else if (select_control[89:85] == 17) {
            out17 = data_in[143:136];
        } else if (select_control[89:85] == 16) {
            out17 = data_in[135:128];
        } else if (select_control[89:85] == 15) {
            out17 = data_in[127:120];
        } else if (select_control[89:85] == 14) {
            out17 = data_in[119:112];
        } else if (select_control[89:85] == 13) {
            out17 = data_in[111:104];
        } else if (select_control[89:85] == 12) {
            out17 = data_in[103:96];
        } else if (select_control[89:85] == 11) {
            out17 = data_in[95:88];
        } else if (select_control[89:85] == 10) {
            out17 = data_in[87:80];
        } else if (select_control[89:85] == 9) {
            out17 = data_in[79:72];
        } else if (select_control[89:85] == 8) {
            out17 = data_in[71:64];
        } else if (select_control[89:85] == 7) {
            out17 = data_in[63:56];
        } else if (select_control[89:85] == 6) {
            out17 = data_in[55:48];
        } else if (select_control[89:85] == 5) {
            out17 = data_in[47:40];
        } else if (select_control[89:85] == 4) {
            out17 = data_in[39:32];
        } else if (select_control[89:85] == 3) {
            out17 = data_in[31:24];
        } else if (select_control[89:85] == 2) {
            out17 = data_in[23:16];
        } else if (select_control[89:85] == 1) {
            out17 = data_in[15:8];
        } else  {
            out17 = data_in[7:0];
        }
        if (select_control[84:80] == 31) {
            out16 = data_in[255:248];
        } else if (select_control[84:80] == 30) {
            out16 = data_in[247:240];
        } else if (select_control[84:80] == 29) {
            out16 = data_in[239:232];
        } else if (select_control[84:80] == 28) {
            out16 = data_in[231:224];
        } else if (select_control[84:80] == 27) {
            out16 = data_in[223:216];
        } else if (select_control[84:80] == 26) {
            out16 = data_in[215:208];
        } else if (select_control[84:80] == 25) {
            out16 = data_in[207:200];
        } else if (select_control[84:80] == 24) {
            out16 = data_in[199:192];
        } else if (select_control[84:80] == 23) {
            out16 = data_in[191:184];
        } else if (select_control[84:80] == 22) {
            out16 = data_in[183:176];
        } else if (select_control[84:80] == 21) {
            out16 = data_in[175:168];
        } else if (select_control[84:80] == 20) {
            out16 = data_in[167:160];
        } else if (select_control[84:80] == 19) {
            out16 = data_in[159:152];
        } else if (select_control[84:80] == 18) {
            out16 = data_in[151:144];
        } else if (select_control[84:80] == 17) {
            out16 = data_in[143:136];
        } else if (select_control[84:80] == 16) {
            out16 = data_in[135:128];
        } else if (select_control[84:80] == 15) {
            out16 = data_in[127:120];
        } else if (select_control[84:80] == 14) {
            out16 = data_in[119:112];
        } else if (select_control[84:80] == 13) {
            out16 = data_in[111:104];
        } else if (select_control[84:80] == 12) {
            out16 = data_in[103:96];
        } else if (select_control[84:80] == 11) {
            out16 = data_in[95:88];
        } else if (select_control[84:80] == 10) {
            out16 = data_in[87:80];
        } else if (select_control[84:80] == 9) {
            out16 = data_in[79:72];
        } else if (select_control[84:80] == 8) {
            out16 = data_in[71:64];
        } else if (select_control[84:80] == 7) {
            out16 = data_in[63:56];
        } else if (select_control[84:80] == 6) {
            out16 = data_in[55:48];
        } else if (select_control[84:80] == 5) {
            out16 = data_in[47:40];
        } else if (select_control[84:80] == 4) {
            out16 = data_in[39:32];
        } else if (select_control[84:80] == 3) {
            out16 = data_in[31:24];
        } else if (select_control[84:80] == 2) {
            out16 = data_in[23:16];
        } else if (select_control[84:80] == 1) {
            out16 = data_in[15:8];
        } else  {
            out16 = data_in[7:0];
        }
        if (select_control[79:75] == 31) {
            out15 = data_in[255:248];
        } else if (select_control[79:75] == 30) {
            out15 = data_in[247:240];
        } else if (select_control[79:75] == 29) {
            out15 = data_in[239:232];
        } else if (select_control[79:75] == 28) {
            out15 = data_in[231:224];
        } else if (select_control[79:75] == 27) {
            out15 = data_in[223:216];
        } else if (select_control[79:75] == 26) {
            out15 = data_in[215:208];
        } else if (select_control[79:75] == 25) {
            out15 = data_in[207:200];
        } else if (select_control[79:75] == 24) {
            out15 = data_in[199:192];
        } else if (select_control[79:75] == 23) {
            out15 = data_in[191:184];
        } else if (select_control[79:75] == 22) {
            out15 = data_in[183:176];
        } else if (select_control[79:75] == 21) {
            out15 = data_in[175:168];
        } else if (select_control[79:75] == 20) {
            out15 = data_in[167:160];
        } else if (select_control[79:75] == 19) {
            out15 = data_in[159:152];
        } else if (select_control[79:75] == 18) {
            out15 = data_in[151:144];
        } else if (select_control[79:75] == 17) {
            out15 = data_in[143:136];
        } else if (select_control[79:75] == 16) {
            out15 = data_in[135:128];
        } else if (select_control[79:75] == 15) {
            out15 = data_in[127:120];
        } else if (select_control[79:75] == 14) {
            out15 = data_in[119:112];
        } else if (select_control[79:75] == 13) {
            out15 = data_in[111:104];
        } else if (select_control[79:75] == 12) {
            out15 = data_in[103:96];
        } else if (select_control[79:75] == 11) {
            out15 = data_in[95:88];
        } else if (select_control[79:75] == 10) {
            out15 = data_in[87:80];
        } else if (select_control[79:75] == 9) {
            out15 = data_in[79:72];
        } else if (select_control[79:75] == 8) {
            out15 = data_in[71:64];
        } else if (select_control[79:75] == 7) {
            out15 = data_in[63:56];
        } else if (select_control[79:75] == 6) {
            out15 = data_in[55:48];
        } else if (select_control[79:75] == 5) {
            out15 = data_in[47:40];
        } else if (select_control[79:75] == 4) {
            out15 = data_in[39:32];
        } else if (select_control[79:75] == 3) {
            out15 = data_in[31:24];
        } else if (select_control[79:75] == 2) {
            out15 = data_in[23:16];
        } else if (select_control[79:75] == 1) {
            out15 = data_in[15:8];
        } else  {
            out15 = data_in[7:0];
        }
        if (select_control[74:70] == 31) {
            out14 = data_in[255:248];
        } else if (select_control[74:70] == 30) {
            out14 = data_in[247:240];
        } else if (select_control[74:70] == 29) {
            out14 = data_in[239:232];
        } else if (select_control[74:70] == 28) {
            out14 = data_in[231:224];
        } else if (select_control[74:70] == 27) {
            out14 = data_in[223:216];
        } else if (select_control[74:70] == 26) {
            out14 = data_in[215:208];
        } else if (select_control[74:70] == 25) {
            out14 = data_in[207:200];
        } else if (select_control[74:70] == 24) {
            out14 = data_in[199:192];
        } else if (select_control[74:70] == 23) {
            out14 = data_in[191:184];
        } else if (select_control[74:70] == 22) {
            out14 = data_in[183:176];
        } else if (select_control[74:70] == 21) {
            out14 = data_in[175:168];
        } else if (select_control[74:70] == 20) {
            out14 = data_in[167:160];
        } else if (select_control[74:70] == 19) {
            out14 = data_in[159:152];
        } else if (select_control[74:70] == 18) {
            out14 = data_in[151:144];
        } else if (select_control[74:70] == 17) {
            out14 = data_in[143:136];
        } else if (select_control[74:70] == 16) {
            out14 = data_in[135:128];
        } else if (select_control[74:70] == 15) {
            out14 = data_in[127:120];
        } else if (select_control[74:70] == 14) {
            out14 = data_in[119:112];
        } else if (select_control[74:70] == 13) {
            out14 = data_in[111:104];
        } else if (select_control[74:70] == 12) {
            out14 = data_in[103:96];
        } else if (select_control[74:70] == 11) {
            out14 = data_in[95:88];
        } else if (select_control[74:70] == 10) {
            out14 = data_in[87:80];
        } else if (select_control[74:70] == 9) {
            out14 = data_in[79:72];
        } else if (select_control[74:70] == 8) {
            out14 = data_in[71:64];
        } else if (select_control[74:70] == 7) {
            out14 = data_in[63:56];
        } else if (select_control[74:70] == 6) {
            out14 = data_in[55:48];
        } else if (select_control[74:70] == 5) {
            out14 = data_in[47:40];
        } else if (select_control[74:70] == 4) {
            out14 = data_in[39:32];
        } else if (select_control[74:70] == 3) {
            out14 = data_in[31:24];
        } else if (select_control[74:70] == 2) {
            out14 = data_in[23:16];
        } else if (select_control[74:70] == 1) {
            out14 = data_in[15:8];
        } else  {
            out14 = data_in[7:0];
        }
        if (select_control[69:65] == 31) {
            out13 = data_in[255:248];
        } else if (select_control[69:65] == 30) {
            out13 = data_in[247:240];
        } else if (select_control[69:65] == 29) {
            out13 = data_in[239:232];
        } else if (select_control[69:65] == 28) {
            out13 = data_in[231:224];
        } else if (select_control[69:65] == 27) {
            out13 = data_in[223:216];
        } else if (select_control[69:65] == 26) {
            out13 = data_in[215:208];
        } else if (select_control[69:65] == 25) {
            out13 = data_in[207:200];
        } else if (select_control[69:65] == 24) {
            out13 = data_in[199:192];
        } else if (select_control[69:65] == 23) {
            out13 = data_in[191:184];
        } else if (select_control[69:65] == 22) {
            out13 = data_in[183:176];
        } else if (select_control[69:65] == 21) {
            out13 = data_in[175:168];
        } else if (select_control[69:65] == 20) {
            out13 = data_in[167:160];
        } else if (select_control[69:65] == 19) {
            out13 = data_in[159:152];
        } else if (select_control[69:65] == 18) {
            out13 = data_in[151:144];
        } else if (select_control[69:65] == 17) {
            out13 = data_in[143:136];
        } else if (select_control[69:65] == 16) {
            out13 = data_in[135:128];
        } else if (select_control[69:65] == 15) {
            out13 = data_in[127:120];
        } else if (select_control[69:65] == 14) {
            out13 = data_in[119:112];
        } else if (select_control[69:65] == 13) {
            out13 = data_in[111:104];
        } else if (select_control[69:65] == 12) {
            out13 = data_in[103:96];
        } else if (select_control[69:65] == 11) {
            out13 = data_in[95:88];
        } else if (select_control[69:65] == 10) {
            out13 = data_in[87:80];
        } else if (select_control[69:65] == 9) {
            out13 = data_in[79:72];
        } else if (select_control[69:65] == 8) {
            out13 = data_in[71:64];
        } else if (select_control[69:65] == 7) {
            out13 = data_in[63:56];
        } else if (select_control[69:65] == 6) {
            out13 = data_in[55:48];
        } else if (select_control[69:65] == 5) {
            out13 = data_in[47:40];
        } else if (select_control[69:65] == 4) {
            out13 = data_in[39:32];
        } else if (select_control[69:65] == 3) {
            out13 = data_in[31:24];
        } else if (select_control[69:65] == 2) {
            out13 = data_in[23:16];
        } else if (select_control[69:65] == 1) {
            out13 = data_in[15:8];
        } else  {
            out13 = data_in[7:0];
        }
        if (select_control[64:60] == 31) {
            out12 = data_in[255:248];
        } else if (select_control[64:60] == 30) {
            out12 = data_in[247:240];
        } else if (select_control[64:60] == 29) {
            out12 = data_in[239:232];
        } else if (select_control[64:60] == 28) {
            out12 = data_in[231:224];
        } else if (select_control[64:60] == 27) {
            out12 = data_in[223:216];
        } else if (select_control[64:60] == 26) {
            out12 = data_in[215:208];
        } else if (select_control[64:60] == 25) {
            out12 = data_in[207:200];
        } else if (select_control[64:60] == 24) {
            out12 = data_in[199:192];
        } else if (select_control[64:60] == 23) {
            out12 = data_in[191:184];
        } else if (select_control[64:60] == 22) {
            out12 = data_in[183:176];
        } else if (select_control[64:60] == 21) {
            out12 = data_in[175:168];
        } else if (select_control[64:60] == 20) {
            out12 = data_in[167:160];
        } else if (select_control[64:60] == 19) {
            out12 = data_in[159:152];
        } else if (select_control[64:60] == 18) {
            out12 = data_in[151:144];
        } else if (select_control[64:60] == 17) {
            out12 = data_in[143:136];
        } else if (select_control[64:60] == 16) {
            out12 = data_in[135:128];
        } else if (select_control[64:60] == 15) {
            out12 = data_in[127:120];
        } else if (select_control[64:60] == 14) {
            out12 = data_in[119:112];
        } else if (select_control[64:60] == 13) {
            out12 = data_in[111:104];
        } else if (select_control[64:60] == 12) {
            out12 = data_in[103:96];
        } else if (select_control[64:60] == 11) {
            out12 = data_in[95:88];
        } else if (select_control[64:60] == 10) {
            out12 = data_in[87:80];
        } else if (select_control[64:60] == 9) {
            out12 = data_in[79:72];
        } else if (select_control[64:60] == 8) {
            out12 = data_in[71:64];
        } else if (select_control[64:60] == 7) {
            out12 = data_in[63:56];
        } else if (select_control[64:60] == 6) {
            out12 = data_in[55:48];
        } else if (select_control[64:60] == 5) {
            out12 = data_in[47:40];
        } else if (select_control[64:60] == 4) {
            out12 = data_in[39:32];
        } else if (select_control[64:60] == 3) {
            out12 = data_in[31:24];
        } else if (select_control[64:60] == 2) {
            out12 = data_in[23:16];
        } else if (select_control[64:60] == 1) {
            out12 = data_in[15:8];
        } else  {
            out12 = data_in[7:0];
        }
        if (select_control[59:55] == 31) {
            out11 = data_in[255:248];
        } else if (select_control[59:55] == 30) {
            out11 = data_in[247:240];
        } else if (select_control[59:55] == 29) {
            out11 = data_in[239:232];
        } else if (select_control[59:55] == 28) {
            out11 = data_in[231:224];
        } else if (select_control[59:55] == 27) {
            out11 = data_in[223:216];
        } else if (select_control[59:55] == 26) {
            out11 = data_in[215:208];
        } else if (select_control[59:55] == 25) {
            out11 = data_in[207:200];
        } else if (select_control[59:55] == 24) {
            out11 = data_in[199:192];
        } else if (select_control[59:55] == 23) {
            out11 = data_in[191:184];
        } else if (select_control[59:55] == 22) {
            out11 = data_in[183:176];
        } else if (select_control[59:55] == 21) {
            out11 = data_in[175:168];
        } else if (select_control[59:55] == 20) {
            out11 = data_in[167:160];
        } else if (select_control[59:55] == 19) {
            out11 = data_in[159:152];
        } else if (select_control[59:55] == 18) {
            out11 = data_in[151:144];
        } else if (select_control[59:55] == 17) {
            out11 = data_in[143:136];
        } else if (select_control[59:55] == 16) {
            out11 = data_in[135:128];
        } else if (select_control[59:55] == 15) {
            out11 = data_in[127:120];
        } else if (select_control[59:55] == 14) {
            out11 = data_in[119:112];
        } else if (select_control[59:55] == 13) {
            out11 = data_in[111:104];
        } else if (select_control[59:55] == 12) {
            out11 = data_in[103:96];
        } else if (select_control[59:55] == 11) {
            out11 = data_in[95:88];
        } else if (select_control[59:55] == 10) {
            out11 = data_in[87:80];
        } else if (select_control[59:55] == 9) {
            out11 = data_in[79:72];
        } else if (select_control[59:55] == 8) {
            out11 = data_in[71:64];
        } else if (select_control[59:55] == 7) {
            out11 = data_in[63:56];
        } else if (select_control[59:55] == 6) {
            out11 = data_in[55:48];
        } else if (select_control[59:55] == 5) {
            out11 = data_in[47:40];
        } else if (select_control[59:55] == 4) {
            out11 = data_in[39:32];
        } else if (select_control[59:55] == 3) {
            out11 = data_in[31:24];
        } else if (select_control[59:55] == 2) {
            out11 = data_in[23:16];
        } else if (select_control[59:55] == 1) {
            out11 = data_in[15:8];
        } else  {
            out11 = data_in[7:0];
        }
        if (select_control[54:50] == 31) {
            out10 = data_in[255:248];
        } else if (select_control[54:50] == 30) {
            out10 = data_in[247:240];
        } else if (select_control[54:50] == 29) {
            out10 = data_in[239:232];
        } else if (select_control[54:50] == 28) {
            out10 = data_in[231:224];
        } else if (select_control[54:50] == 27) {
            out10 = data_in[223:216];
        } else if (select_control[54:50] == 26) {
            out10 = data_in[215:208];
        } else if (select_control[54:50] == 25) {
            out10 = data_in[207:200];
        } else if (select_control[54:50] == 24) {
            out10 = data_in[199:192];
        } else if (select_control[54:50] == 23) {
            out10 = data_in[191:184];
        } else if (select_control[54:50] == 22) {
            out10 = data_in[183:176];
        } else if (select_control[54:50] == 21) {
            out10 = data_in[175:168];
        } else if (select_control[54:50] == 20) {
            out10 = data_in[167:160];
        } else if (select_control[54:50] == 19) {
            out10 = data_in[159:152];
        } else if (select_control[54:50] == 18) {
            out10 = data_in[151:144];
        } else if (select_control[54:50] == 17) {
            out10 = data_in[143:136];
        } else if (select_control[54:50] == 16) {
            out10 = data_in[135:128];
        } else if (select_control[54:50] == 15) {
            out10 = data_in[127:120];
        } else if (select_control[54:50] == 14) {
            out10 = data_in[119:112];
        } else if (select_control[54:50] == 13) {
            out10 = data_in[111:104];
        } else if (select_control[54:50] == 12) {
            out10 = data_in[103:96];
        } else if (select_control[54:50] == 11) {
            out10 = data_in[95:88];
        } else if (select_control[54:50] == 10) {
            out10 = data_in[87:80];
        } else if (select_control[54:50] == 9) {
            out10 = data_in[79:72];
        } else if (select_control[54:50] == 8) {
            out10 = data_in[71:64];
        } else if (select_control[54:50] == 7) {
            out10 = data_in[63:56];
        } else if (select_control[54:50] == 6) {
            out10 = data_in[55:48];
        } else if (select_control[54:50] == 5) {
            out10 = data_in[47:40];
        } else if (select_control[54:50] == 4) {
            out10 = data_in[39:32];
        } else if (select_control[54:50] == 3) {
            out10 = data_in[31:24];
        } else if (select_control[54:50] == 2) {
            out10 = data_in[23:16];
        } else if (select_control[54:50] == 1) {
            out10 = data_in[15:8];
        } else  {
            out10 = data_in[7:0];
        }
        if (select_control[49:45] == 31) {
            out9 = data_in[255:248];
        } else if (select_control[49:45] == 30) {
            out9 = data_in[247:240];
        } else if (select_control[49:45] == 29) {
            out9 = data_in[239:232];
        } else if (select_control[49:45] == 28) {
            out9 = data_in[231:224];
        } else if (select_control[49:45] == 27) {
            out9 = data_in[223:216];
        } else if (select_control[49:45] == 26) {
            out9 = data_in[215:208];
        } else if (select_control[49:45] == 25) {
            out9 = data_in[207:200];
        } else if (select_control[49:45] == 24) {
            out9 = data_in[199:192];
        } else if (select_control[49:45] == 23) {
            out9 = data_in[191:184];
        } else if (select_control[49:45] == 22) {
            out9 = data_in[183:176];
        } else if (select_control[49:45] == 21) {
            out9 = data_in[175:168];
        } else if (select_control[49:45] == 20) {
            out9 = data_in[167:160];
        } else if (select_control[49:45] == 19) {
            out9 = data_in[159:152];
        } else if (select_control[49:45] == 18) {
            out9 = data_in[151:144];
        } else if (select_control[49:45] == 17) {
            out9 = data_in[143:136];
        } else if (select_control[49:45] == 16) {
            out9 = data_in[135:128];
        } else if (select_control[49:45] == 15) {
            out9 = data_in[127:120];
        } else if (select_control[49:45] == 14) {
            out9 = data_in[119:112];
        } else if (select_control[49:45] == 13) {
            out9 = data_in[111:104];
        } else if (select_control[49:45] == 12) {
            out9 = data_in[103:96];
        } else if (select_control[49:45] == 11) {
            out9 = data_in[95:88];
        } else if (select_control[49:45] == 10) {
            out9 = data_in[87:80];
        } else if (select_control[49:45] == 9) {
            out9 = data_in[79:72];
        } else if (select_control[49:45] == 8) {
            out9 = data_in[71:64];
        } else if (select_control[49:45] == 7) {
            out9 = data_in[63:56];
        } else if (select_control[49:45] == 6) {
            out9 = data_in[55:48];
        } else if (select_control[49:45] == 5) {
            out9 = data_in[47:40];
        } else if (select_control[49:45] == 4) {
            out9 = data_in[39:32];
        } else if (select_control[49:45] == 3) {
            out9 = data_in[31:24];
        } else if (select_control[49:45] == 2) {
            out9 = data_in[23:16];
        } else if (select_control[49:45] == 1) {
            out9 = data_in[15:8];
        } else  {
            out9 = data_in[7:0];
        }
        if (select_control[44:40] == 31) {
            out8 = data_in[255:248];
        } else if (select_control[44:40] == 30) {
            out8 = data_in[247:240];
        } else if (select_control[44:40] == 29) {
            out8 = data_in[239:232];
        } else if (select_control[44:40] == 28) {
            out8 = data_in[231:224];
        } else if (select_control[44:40] == 27) {
            out8 = data_in[223:216];
        } else if (select_control[44:40] == 26) {
            out8 = data_in[215:208];
        } else if (select_control[44:40] == 25) {
            out8 = data_in[207:200];
        } else if (select_control[44:40] == 24) {
            out8 = data_in[199:192];
        } else if (select_control[44:40] == 23) {
            out8 = data_in[191:184];
        } else if (select_control[44:40] == 22) {
            out8 = data_in[183:176];
        } else if (select_control[44:40] == 21) {
            out8 = data_in[175:168];
        } else if (select_control[44:40] == 20) {
            out8 = data_in[167:160];
        } else if (select_control[44:40] == 19) {
            out8 = data_in[159:152];
        } else if (select_control[44:40] == 18) {
            out8 = data_in[151:144];
        } else if (select_control[44:40] == 17) {
            out8 = data_in[143:136];
        } else if (select_control[44:40] == 16) {
            out8 = data_in[135:128];
        } else if (select_control[44:40] == 15) {
            out8 = data_in[127:120];
        } else if (select_control[44:40] == 14) {
            out8 = data_in[119:112];
        } else if (select_control[44:40] == 13) {
            out8 = data_in[111:104];
        } else if (select_control[44:40] == 12) {
            out8 = data_in[103:96];
        } else if (select_control[44:40] == 11) {
            out8 = data_in[95:88];
        } else if (select_control[44:40] == 10) {
            out8 = data_in[87:80];
        } else if (select_control[44:40] == 9) {
            out8 = data_in[79:72];
        } else if (select_control[44:40] == 8) {
            out8 = data_in[71:64];
        } else if (select_control[44:40] == 7) {
            out8 = data_in[63:56];
        } else if (select_control[44:40] == 6) {
            out8 = data_in[55:48];
        } else if (select_control[44:40] == 5) {
            out8 = data_in[47:40];
        } else if (select_control[44:40] == 4) {
            out8 = data_in[39:32];
        } else if (select_control[44:40] == 3) {
            out8 = data_in[31:24];
        } else if (select_control[44:40] == 2) {
            out8 = data_in[23:16];
        } else if (select_control[44:40] == 1) {
            out8 = data_in[15:8];
        } else  {
            out8 = data_in[7:0];
        }
        if (select_control[39:35] == 31) {
            out7 = data_in[255:248];
        } else if (select_control[39:35] == 30) {
            out7 = data_in[247:240];
        } else if (select_control[39:35] == 29) {
            out7 = data_in[239:232];
        } else if (select_control[39:35] == 28) {
            out7 = data_in[231:224];
        } else if (select_control[39:35] == 27) {
            out7 = data_in[223:216];
        } else if (select_control[39:35] == 26) {
            out7 = data_in[215:208];
        } else if (select_control[39:35] == 25) {
            out7 = data_in[207:200];
        } else if (select_control[39:35] == 24) {
            out7 = data_in[199:192];
        } else if (select_control[39:35] == 23) {
            out7 = data_in[191:184];
        } else if (select_control[39:35] == 22) {
            out7 = data_in[183:176];
        } else if (select_control[39:35] == 21) {
            out7 = data_in[175:168];
        } else if (select_control[39:35] == 20) {
            out7 = data_in[167:160];
        } else if (select_control[39:35] == 19) {
            out7 = data_in[159:152];
        } else if (select_control[39:35] == 18) {
            out7 = data_in[151:144];
        } else if (select_control[39:35] == 17) {
            out7 = data_in[143:136];
        } else if (select_control[39:35] == 16) {
            out7 = data_in[135:128];
        } else if (select_control[39:35] == 15) {
            out7 = data_in[127:120];
        } else if (select_control[39:35] == 14) {
            out7 = data_in[119:112];
        } else if (select_control[39:35] == 13) {
            out7 = data_in[111:104];
        } else if (select_control[39:35] == 12) {
            out7 = data_in[103:96];
        } else if (select_control[39:35] == 11) {
            out7 = data_in[95:88];
        } else if (select_control[39:35] == 10) {
            out7 = data_in[87:80];
        } else if (select_control[39:35] == 9) {
            out7 = data_in[79:72];
        } else if (select_control[39:35] == 8) {
            out7 = data_in[71:64];
        } else if (select_control[39:35] == 7) {
            out7 = data_in[63:56];
        } else if (select_control[39:35] == 6) {
            out7 = data_in[55:48];
        } else if (select_control[39:35] == 5) {
            out7 = data_in[47:40];
        } else if (select_control[39:35] == 4) {
            out7 = data_in[39:32];
        } else if (select_control[39:35] == 3) {
            out7 = data_in[31:24];
        } else if (select_control[39:35] == 2) {
            out7 = data_in[23:16];
        } else if (select_control[39:35] == 1) {
            out7 = data_in[15:8];
        } else  {
            out7 = data_in[7:0];
        }
        if (select_control[34:30] == 31) {
            out6 = data_in[255:248];
        } else if (select_control[34:30] == 30) {
            out6 = data_in[247:240];
        } else if (select_control[34:30] == 29) {
            out6 = data_in[239:232];
        } else if (select_control[34:30] == 28) {
            out6 = data_in[231:224];
        } else if (select_control[34:30] == 27) {
            out6 = data_in[223:216];
        } else if (select_control[34:30] == 26) {
            out6 = data_in[215:208];
        } else if (select_control[34:30] == 25) {
            out6 = data_in[207:200];
        } else if (select_control[34:30] == 24) {
            out6 = data_in[199:192];
        } else if (select_control[34:30] == 23) {
            out6 = data_in[191:184];
        } else if (select_control[34:30] == 22) {
            out6 = data_in[183:176];
        } else if (select_control[34:30] == 21) {
            out6 = data_in[175:168];
        } else if (select_control[34:30] == 20) {
            out6 = data_in[167:160];
        } else if (select_control[34:30] == 19) {
            out6 = data_in[159:152];
        } else if (select_control[34:30] == 18) {
            out6 = data_in[151:144];
        } else if (select_control[34:30] == 17) {
            out6 = data_in[143:136];
        } else if (select_control[34:30] == 16) {
            out6 = data_in[135:128];
        } else if (select_control[34:30] == 15) {
            out6 = data_in[127:120];
        } else if (select_control[34:30] == 14) {
            out6 = data_in[119:112];
        } else if (select_control[34:30] == 13) {
            out6 = data_in[111:104];
        } else if (select_control[34:30] == 12) {
            out6 = data_in[103:96];
        } else if (select_control[34:30] == 11) {
            out6 = data_in[95:88];
        } else if (select_control[34:30] == 10) {
            out6 = data_in[87:80];
        } else if (select_control[34:30] == 9) {
            out6 = data_in[79:72];
        } else if (select_control[34:30] == 8) {
            out6 = data_in[71:64];
        } else if (select_control[34:30] == 7) {
            out6 = data_in[63:56];
        } else if (select_control[34:30] == 6) {
            out6 = data_in[55:48];
        } else if (select_control[34:30] == 5) {
            out6 = data_in[47:40];
        } else if (select_control[34:30] == 4) {
            out6 = data_in[39:32];
        } else if (select_control[34:30] == 3) {
            out6 = data_in[31:24];
        } else if (select_control[34:30] == 2) {
            out6 = data_in[23:16];
        } else if (select_control[34:30] == 1) {
            out6 = data_in[15:8];
        } else  {
            out6 = data_in[7:0];
        }
        if (select_control[29:25] == 31) {
            out5 = data_in[255:248];
        } else if (select_control[29:25] == 30) {
            out5 = data_in[247:240];
        } else if (select_control[29:25] == 29) {
            out5 = data_in[239:232];
        } else if (select_control[29:25] == 28) {
            out5 = data_in[231:224];
        } else if (select_control[29:25] == 27) {
            out5 = data_in[223:216];
        } else if (select_control[29:25] == 26) {
            out5 = data_in[215:208];
        } else if (select_control[29:25] == 25) {
            out5 = data_in[207:200];
        } else if (select_control[29:25] == 24) {
            out5 = data_in[199:192];
        } else if (select_control[29:25] == 23) {
            out5 = data_in[191:184];
        } else if (select_control[29:25] == 22) {
            out5 = data_in[183:176];
        } else if (select_control[29:25] == 21) {
            out5 = data_in[175:168];
        } else if (select_control[29:25] == 20) {
            out5 = data_in[167:160];
        } else if (select_control[29:25] == 19) {
            out5 = data_in[159:152];
        } else if (select_control[29:25] == 18) {
            out5 = data_in[151:144];
        } else if (select_control[29:25] == 17) {
            out5 = data_in[143:136];
        } else if (select_control[29:25] == 16) {
            out5 = data_in[135:128];
        } else if (select_control[29:25] == 15) {
            out5 = data_in[127:120];
        } else if (select_control[29:25] == 14) {
            out5 = data_in[119:112];
        } else if (select_control[29:25] == 13) {
            out5 = data_in[111:104];
        } else if (select_control[29:25] == 12) {
            out5 = data_in[103:96];
        } else if (select_control[29:25] == 11) {
            out5 = data_in[95:88];
        } else if (select_control[29:25] == 10) {
            out5 = data_in[87:80];
        } else if (select_control[29:25] == 9) {
            out5 = data_in[79:72];
        } else if (select_control[29:25] == 8) {
            out5 = data_in[71:64];
        } else if (select_control[29:25] == 7) {
            out5 = data_in[63:56];
        } else if (select_control[29:25] == 6) {
            out5 = data_in[55:48];
        } else if (select_control[29:25] == 5) {
            out5 = data_in[47:40];
        } else if (select_control[29:25] == 4) {
            out5 = data_in[39:32];
        } else if (select_control[29:25] == 3) {
            out5 = data_in[31:24];
        } else if (select_control[29:25] == 2) {
            out5 = data_in[23:16];
        } else if (select_control[29:25] == 1) {
            out5 = data_in[15:8];
        } else  {
            out5 = data_in[7:0];
        }
        if (select_control[24:20] == 31) {
            out4 = data_in[255:248];
        } else if (select_control[24:20] == 30) {
            out4 = data_in[247:240];
        } else if (select_control[24:20] == 29) {
            out4 = data_in[239:232];
        } else if (select_control[24:20] == 28) {
            out4 = data_in[231:224];
        } else if (select_control[24:20] == 27) {
            out4 = data_in[223:216];
        } else if (select_control[24:20] == 26) {
            out4 = data_in[215:208];
        } else if (select_control[24:20] == 25) {
            out4 = data_in[207:200];
        } else if (select_control[24:20] == 24) {
            out4 = data_in[199:192];
        } else if (select_control[24:20] == 23) {
            out4 = data_in[191:184];
        } else if (select_control[24:20] == 22) {
            out4 = data_in[183:176];
        } else if (select_control[24:20] == 21) {
            out4 = data_in[175:168];
        } else if (select_control[24:20] == 20) {
            out4 = data_in[167:160];
        } else if (select_control[24:20] == 19) {
            out4 = data_in[159:152];
        } else if (select_control[24:20] == 18) {
            out4 = data_in[151:144];
        } else if (select_control[24:20] == 17) {
            out4 = data_in[143:136];
        } else if (select_control[24:20] == 16) {
            out4 = data_in[135:128];
        } else if (select_control[24:20] == 15) {
            out4 = data_in[127:120];
        } else if (select_control[24:20] == 14) {
            out4 = data_in[119:112];
        } else if (select_control[24:20] == 13) {
            out4 = data_in[111:104];
        } else if (select_control[24:20] == 12) {
            out4 = data_in[103:96];
        } else if (select_control[24:20] == 11) {
            out4 = data_in[95:88];
        } else if (select_control[24:20] == 10) {
            out4 = data_in[87:80];
        } else if (select_control[24:20] == 9) {
            out4 = data_in[79:72];
        } else if (select_control[24:20] == 8) {
            out4 = data_in[71:64];
        } else if (select_control[24:20] == 7) {
            out4 = data_in[63:56];
        } else if (select_control[24:20] == 6) {
            out4 = data_in[55:48];
        } else if (select_control[24:20] == 5) {
            out4 = data_in[47:40];
        } else if (select_control[24:20] == 4) {
            out4 = data_in[39:32];
        } else if (select_control[24:20] == 3) {
            out4 = data_in[31:24];
        } else if (select_control[24:20] == 2) {
            out4 = data_in[23:16];
        } else if (select_control[24:20] == 1) {
            out4 = data_in[15:8];
        } else  {
            out4 = data_in[7:0];
        }
        if (select_control[19:15] == 31) {
            out3 = data_in[255:248];
        } else if (select_control[19:15] == 30) {
            out3 = data_in[247:240];
        } else if (select_control[19:15] == 29) {
            out3 = data_in[239:232];
        } else if (select_control[19:15] == 28) {
            out3 = data_in[231:224];
        } else if (select_control[19:15] == 27) {
            out3 = data_in[223:216];
        } else if (select_control[19:15] == 26) {
            out3 = data_in[215:208];
        } else if (select_control[19:15] == 25) {
            out3 = data_in[207:200];
        } else if (select_control[19:15] == 24) {
            out3 = data_in[199:192];
        } else if (select_control[19:15] == 23) {
            out3 = data_in[191:184];
        } else if (select_control[19:15] == 22) {
            out3 = data_in[183:176];
        } else if (select_control[19:15] == 21) {
            out3 = data_in[175:168];
        } else if (select_control[19:15] == 20) {
            out3 = data_in[167:160];
        } else if (select_control[19:15] == 19) {
            out3 = data_in[159:152];
        } else if (select_control[19:15] == 18) {
            out3 = data_in[151:144];
        } else if (select_control[19:15] == 17) {
            out3 = data_in[143:136];
        } else if (select_control[19:15] == 16) {
            out3 = data_in[135:128];
        } else if (select_control[19:15] == 15) {
            out3 = data_in[127:120];
        } else if (select_control[19:15] == 14) {
            out3 = data_in[119:112];
        } else if (select_control[19:15] == 13) {
            out3 = data_in[111:104];
        } else if (select_control[19:15] == 12) {
            out3 = data_in[103:96];
        } else if (select_control[19:15] == 11) {
            out3 = data_in[95:88];
        } else if (select_control[19:15] == 10) {
            out3 = data_in[87:80];
        } else if (select_control[19:15] == 9) {
            out3 = data_in[79:72];
        } else if (select_control[19:15] == 8) {
            out3 = data_in[71:64];
        } else if (select_control[19:15] == 7) {
            out3 = data_in[63:56];
        } else if (select_control[19:15] == 6) {
            out3 = data_in[55:48];
        } else if (select_control[19:15] == 5) {
            out3 = data_in[47:40];
        } else if (select_control[19:15] == 4) {
            out3 = data_in[39:32];
        } else if (select_control[19:15] == 3) {
            out3 = data_in[31:24];
        } else if (select_control[19:15] == 2) {
            out3 = data_in[23:16];
        } else if (select_control[19:15] == 1) {
            out3 = data_in[15:8];
        } else  {
            out3 = data_in[7:0];
        }
        if (select_control[14:10] == 31) {
            out2 = data_in[255:248];
        } else if (select_control[14:10] == 30) {
            out2 = data_in[247:240];
        } else if (select_control[14:10] == 29) {
            out2 = data_in[239:232];
        } else if (select_control[14:10] == 28) {
            out2 = data_in[231:224];
        } else if (select_control[14:10] == 27) {
            out2 = data_in[223:216];
        } else if (select_control[14:10] == 26) {
            out2 = data_in[215:208];
        } else if (select_control[14:10] == 25) {
            out2 = data_in[207:200];
        } else if (select_control[14:10] == 24) {
            out2 = data_in[199:192];
        } else if (select_control[14:10] == 23) {
            out2 = data_in[191:184];
        } else if (select_control[14:10] == 22) {
            out2 = data_in[183:176];
        } else if (select_control[14:10] == 21) {
            out2 = data_in[175:168];
        } else if (select_control[14:10] == 20) {
            out2 = data_in[167:160];
        } else if (select_control[14:10] == 19) {
            out2 = data_in[159:152];
        } else if (select_control[14:10] == 18) {
            out2 = data_in[151:144];
        } else if (select_control[14:10] == 17) {
            out2 = data_in[143:136];
        } else if (select_control[14:10] == 16) {
            out2 = data_in[135:128];
        } else if (select_control[14:10] == 15) {
            out2 = data_in[127:120];
        } else if (select_control[14:10] == 14) {
            out2 = data_in[119:112];
        } else if (select_control[14:10] == 13) {
            out2 = data_in[111:104];
        } else if (select_control[14:10] == 12) {
            out2 = data_in[103:96];
        } else if (select_control[14:10] == 11) {
            out2 = data_in[95:88];
        } else if (select_control[14:10] == 10) {
            out2 = data_in[87:80];
        } else if (select_control[14:10] == 9) {
            out2 = data_in[79:72];
        } else if (select_control[14:10] == 8) {
            out2 = data_in[71:64];
        } else if (select_control[14:10] == 7) {
            out2 = data_in[63:56];
        } else if (select_control[14:10] == 6) {
            out2 = data_in[55:48];
        } else if (select_control[14:10] == 5) {
            out2 = data_in[47:40];
        } else if (select_control[14:10] == 4) {
            out2 = data_in[39:32];
        } else if (select_control[14:10] == 3) {
            out2 = data_in[31:24];
        } else if (select_control[14:10] == 2) {
            out2 = data_in[23:16];
        } else if (select_control[14:10] == 1) {
            out2 = data_in[15:8];
        } else  {
            out2 = data_in[7:0];
        }
        if (select_control[9:5] == 31) {
            out1 = data_in[255:248];
        } else if (select_control[9:5] == 30) {
            out1 = data_in[247:240];
        } else if (select_control[9:5] == 29) {
            out1 = data_in[239:232];
        } else if (select_control[9:5] == 28) {
            out1 = data_in[231:224];
        } else if (select_control[9:5] == 27) {
            out1 = data_in[223:216];
        } else if (select_control[9:5] == 26) {
            out1 = data_in[215:208];
        } else if (select_control[9:5] == 25) {
            out1 = data_in[207:200];
        } else if (select_control[9:5] == 24) {
            out1 = data_in[199:192];
        } else if (select_control[9:5] == 23) {
            out1 = data_in[191:184];
        } else if (select_control[9:5] == 22) {
            out1 = data_in[183:176];
        } else if (select_control[9:5] == 21) {
            out1 = data_in[175:168];
        } else if (select_control[9:5] == 20) {
            out1 = data_in[167:160];
        } else if (select_control[9:5] == 19) {
            out1 = data_in[159:152];
        } else if (select_control[9:5] == 18) {
            out1 = data_in[151:144];
        } else if (select_control[9:5] == 17) {
            out1 = data_in[143:136];
        } else if (select_control[9:5] == 16) {
            out1 = data_in[135:128];
        } else if (select_control[9:5] == 15) {
            out1 = data_in[127:120];
        } else if (select_control[9:5] == 14) {
            out1 = data_in[119:112];
        } else if (select_control[9:5] == 13) {
            out1 = data_in[111:104];
        } else if (select_control[9:5] == 12) {
            out1 = data_in[103:96];
        } else if (select_control[9:5] == 11) {
            out1 = data_in[95:88];
        } else if (select_control[9:5] == 10) {
            out1 = data_in[87:80];
        } else if (select_control[9:5] == 9) {
            out1 = data_in[79:72];
        } else if (select_control[9:5] == 8) {
            out1 = data_in[71:64];
        } else if (select_control[9:5] == 7) {
            out1 = data_in[63:56];
        } else if (select_control[9:5] == 6) {
            out1 = data_in[55:48];
        } else if (select_control[9:5] == 5) {
            out1 = data_in[47:40];
        } else if (select_control[9:5] == 4) {
            out1 = data_in[39:32];
        } else if (select_control[9:5] == 3) {
            out1 = data_in[31:24];
        } else if (select_control[9:5] == 2) {
            out1 = data_in[23:16];
        } else if (select_control[9:5] == 1) {
            out1 = data_in[15:8];
        } else  {
            out1 = data_in[7:0];
        }
        if (select_control[4:0] == 31) {
            out0 = data_in[255:248];
        } else if (select_control[4:0] == 30) {
            out0 = data_in[247:240];
        } else if (select_control[4:0] == 29) {
            out0 = data_in[239:232];
        } else if (select_control[4:0] == 28) {
            out0 = data_in[231:224];
        } else if (select_control[4:0] == 27) {
            out0 = data_in[223:216];
        } else if (select_control[4:0] == 26) {
            out0 = data_in[215:208];
        } else if (select_control[4:0] == 25) {
            out0 = data_in[207:200];
        } else if (select_control[4:0] == 24) {
            out0 = data_in[199:192];
        } else if (select_control[4:0] == 23) {
            out0 = data_in[191:184];
        } else if (select_control[4:0] == 22) {
            out0 = data_in[183:176];
        } else if (select_control[4:0] == 21) {
            out0 = data_in[175:168];
        } else if (select_control[4:0] == 20) {
            out0 = data_in[167:160];
        } else if (select_control[4:0] == 19) {
            out0 = data_in[159:152];
        } else if (select_control[4:0] == 18) {
            out0 = data_in[151:144];
        } else if (select_control[4:0] == 17) {
            out0 = data_in[143:136];
        } else if (select_control[4:0] == 16) {
            out0 = data_in[135:128];
        } else if (select_control[4:0] == 15) {
            out0 = data_in[127:120];
        } else if (select_control[4:0] == 14) {
            out0 = data_in[119:112];
        } else if (select_control[4:0] == 13) {
            out0 = data_in[111:104];
        } else if (select_control[4:0] == 12) {
            out0 = data_in[103:96];
        } else if (select_control[4:0] == 11) {
            out0 = data_in[95:88];
        } else if (select_control[4:0] == 10) {
            out0 = data_in[87:80];
        } else if (select_control[4:0] == 9) {
            out0 = data_in[79:72];
        } else if (select_control[4:0] == 8) {
            out0 = data_in[71:64];
        } else if (select_control[4:0] == 7) {
            out0 = data_in[63:56];
        } else if (select_control[4:0] == 6) {
            out0 = data_in[55:48];
        } else if (select_control[4:0] == 5) {
            out0 = data_in[47:40];
        } else if (select_control[4:0] == 4) {
            out0 = data_in[39:32];
        } else if (select_control[4:0] == 3) {
            out0 = data_in[31:24];
        } else if (select_control[4:0] == 2) {
            out0 = data_in[23:16];
        } else if (select_control[4:0] == 1) {
            out0 = data_in[15:8];
        } else  {
            out0 = data_in[7:0];
        }

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
