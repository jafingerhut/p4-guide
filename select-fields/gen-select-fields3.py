#! /usr/bin/env python
 
from __future__ import print_function
import os, sys
import re


# This variation should work for arbitrary positive integer values of
# field_width.

def print_select_field_code(
        field_width=8,
        input_fields=8,
        output_fields=4):
    control_name = ("Select%dBitFields_%d_to_%d"
                    "" % (field_width, input_fields, output_fields))
    select_one_field_fn_name = control_name + "_select_one_field"
    pure_fn_name = control_name + "_pure_function"
    data_in_width = field_width * input_fields
    data_out_width = field_width * output_fields
    lg2_field_width = 1
    while (field_width > (1 << lg2_field_width)):
        lg2_field_width += 1
    ceil_lg2_input_fields = 1
    while (input_fields > (1 << ceil_lg2_input_fields)):
        ceil_lg2_input_fields += 1
    select_control_width = ceil_lg2_input_fields * output_fields

    select_one_field_body = ""
    for input_field in range(input_fields-1, 0-1, -1):
        else_kw = "} else "
        if input_field == input_fields-1:
            else_kw = ""
        data_in_lsb = input_field * field_width
        data_in_msb = data_in_lsb + field_width - 1

        # Make the 'default' selection from input field 0, with no
        # 'if (select_control[msb:lsb] == 0)' condition, just an
        # 'else'.
        if_cond = ("if (sel == %d)"
                   "" % (input_field))
        if input_field == 0:
            if_cond = ""
        select_one_field_body += ("""        %s%s {
            one_out_field = data_in[%d:%d];
""" % (else_kw, if_cond, data_in_msb, data_in_lsb))
    select_one_field_body += "        }"

    decls = []
    out_assigns = []
    data_out_subexprs = []
    for output_field in range(output_fields-1, 0-1, -1):
        decls.append("bit<%d> out%d;" % (field_width, output_field))

        data_out_subexprs.append("out%d" % (output_field))

        sc_lsb = output_field * ceil_lg2_input_fields
        sc_msb = sc_lsb + ceil_lg2_input_fields - 1
        out_assign = ("sof.apply(data_in, select_control[%d:%d], out%d);"
                      "" % (sc_msb, sc_lsb, output_field))
        out_assigns.append(out_assign)

    print("""control %s(
    in bit<%d> data_in,
    in bit<%d> sel,
    out bit<%d> one_out_field)
{
    apply {""" % (select_one_field_fn_name, data_in_width,
        ceil_lg2_input_fields, field_width))
    print(select_one_field_body)
    print("""    }
}

""")

    print("""control %s(
    in bit<%d> data_in,
    in bit<%d> select_control,
    out bit<%d> data_out)
{""" % (pure_fn_name, data_in_width,
        select_control_width, data_out_width))
    print('    ' + '\n    '.join(decls))
    print("    %s() sof;" % (select_one_field_fn_name))
    print("    apply {")
    print('        ' + '\n        '.join(out_assigns))
    print("        data_out = (")
    print("            " + " ++\n            ".join(data_out_subexprs))
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
