// Copyright 2017 Andy Fingerhut
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

control Select8BitFields_4_to_2_pure_function(
    in bit<32> data_in,
    in bit<4> select_control,
    out bit<16> data_out)
{
    apply {
        data_out = (
            ((bit<8>) (data_in >> ((bit<5>) select_control[3:2] << 3))) ++
            ((bit<8>) (data_in >> ((bit<5>) select_control[1:0] << 3)))
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
    apply {
        data_out = (
            ((bit<8>) (data_in >> ((bit<5>) select_control[5:4] << 3))) ++
            ((bit<8>) (data_in >> ((bit<5>) select_control[3:2] << 3))) ++
            ((bit<8>) (data_in >> ((bit<5>) select_control[1:0] << 3)))
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
    apply {
        data_out = (
            ((bit<8>) (data_in >> ((bit<6>) select_control[11:9] << 3))) ++
            ((bit<8>) (data_in >> ((bit<6>) select_control[8:6] << 3))) ++
            ((bit<8>) (data_in >> ((bit<6>) select_control[5:3] << 3))) ++
            ((bit<8>) (data_in >> ((bit<6>) select_control[2:0] << 3)))
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
    apply {
        data_out = (
            ((bit<8>) (data_in >> ((bit<6>) select_control[17:15] << 3))) ++
            ((bit<8>) (data_in >> ((bit<6>) select_control[14:12] << 3))) ++
            ((bit<8>) (data_in >> ((bit<6>) select_control[11:9] << 3))) ++
            ((bit<8>) (data_in >> ((bit<6>) select_control[8:6] << 3))) ++
            ((bit<8>) (data_in >> ((bit<6>) select_control[5:3] << 3))) ++
            ((bit<8>) (data_in >> ((bit<6>) select_control[2:0] << 3)))
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
    apply {
        data_out = (
            ((bit<8>) (data_in >> ((bit<7>) select_control[31:28] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[27:24] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[23:20] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[19:16] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[15:12] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[11:8] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[7:4] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[3:0] << 3)))
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
    apply {
        data_out = (
            ((bit<8>) (data_in >> ((bit<7>) select_control[47:44] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[43:40] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[39:36] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[35:32] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[31:28] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[27:24] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[23:20] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[19:16] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[15:12] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[11:8] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[7:4] << 3))) ++
            ((bit<8>) (data_in >> ((bit<7>) select_control[3:0] << 3)))
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
    apply {
        data_out = (
            ((bit<8>) (data_in >> ((bit<8>) select_control[59:55] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[54:50] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[49:45] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[44:40] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[39:35] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[34:30] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[29:25] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[24:20] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[19:15] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[14:10] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[9:5] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[4:0] << 3)))
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
    apply {
        data_out = (
            ((bit<8>) (data_in >> ((bit<8>) select_control[89:85] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[84:80] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[79:75] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[74:70] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[69:65] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[64:60] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[59:55] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[54:50] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[49:45] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[44:40] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[39:35] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[34:30] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[29:25] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[24:20] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[19:15] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[14:10] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[9:5] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[4:0] << 3)))
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
    apply {
        data_out = (
            ((bit<8>) (data_in >> ((bit<8>) select_control[79:75] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[74:70] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[69:65] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[64:60] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[59:55] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[54:50] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[49:45] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[44:40] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[39:35] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[34:30] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[29:25] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[24:20] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[19:15] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[14:10] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[9:5] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[4:0] << 3)))
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
    apply {
        data_out = (
            ((bit<8>) (data_in >> ((bit<8>) select_control[119:115] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[114:110] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[109:105] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[104:100] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[99:95] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[94:90] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[89:85] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[84:80] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[79:75] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[74:70] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[69:65] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[64:60] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[59:55] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[54:50] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[49:45] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[44:40] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[39:35] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[34:30] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[29:25] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[24:20] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[19:15] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[14:10] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[9:5] << 3))) ++
            ((bit<8>) (data_in >> ((bit<8>) select_control[4:0] << 3)))
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
