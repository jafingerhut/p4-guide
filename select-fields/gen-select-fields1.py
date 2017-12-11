#! /usr/bin/env python
 
from __future__ import print_function
import os, sys
import re


# This variation only works if field_width is a power of 2, because of
# the way calculates data_out.  Either that, or it would need a P4_16
# implementation that can do multiplication of values that are not
# compile time constants.

def print_select_field_code(
        field_width=8,
        input_fields=8,
        output_fields=4):
    control_name = ("Select%dBitFields_%d_to_%d"
                    "" % (field_width, input_fields, output_fields))
    pure_fn_name = control_name + "_pure_function"
    data_in_width = field_width * input_fields
    data_out_width = field_width * output_fields
    lg2_field_width = 1
    while (field_width > (1 << lg2_field_width)):
        lg2_field_width += 1
    assert (field_width == (1 << lg2_field_width))
    ceil_lg2_input_fields = 1
    while (input_fields > (1 << ceil_lg2_input_fields)):
        ceil_lg2_input_fields += 1
    select_control_width = ceil_lg2_input_fields * output_fields

    print("""control %s(
    in bit<%d> data_in,
    in bit<%d> select_control,
    out bit<%d> data_out)
{
    apply {""" % (pure_fn_name, data_in_width,
                  select_control_width, data_out_width))

    print("        data_out = (")
    for output_field in range(output_fields-1, 0-1, -1):
        shift_value_width = lg2_field_width + ceil_lg2_input_fields
        sc_lsb = output_field * ceil_lg2_input_fields
        sc_msb = sc_lsb + ceil_lg2_input_fields - 1
        do_append = " ++"
        if output_field == 0:
            do_append = ""
        print("            ((bit<%d>) "
              "(data_in >> ((bit<%d>) select_control[%d:%d] << %d)))%s"
              "" % (field_width, shift_value_width, sc_msb, sc_lsb,
                    lg2_field_width, do_append))
    print("            );")

    print("""    }
}

""")

    print("""control %s(
    in bit<%d> data_in,
    out bit<%d> data_out)
{
    %s() sf;
    bit<%d> select_control;

    action get_sc(bit<%d> sc) {
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
}""" % (control_name, data_in_width, data_out_width,
        pure_fn_name, select_control_width, select_control_width))



field_width = 8
for input_fields in [4, 8, 16, 24, 32]:
    for output_fields in range(input_fields/2, input_fields, input_fields/4):
        print_select_field_code(
            field_width=field_width, input_fields=input_fields,
            output_fields=output_fields)
