#! /usr/bin/env python3

import os, sys
import re

######################################################################
# Parsing optional command line arguments
######################################################################

import argparse

debug = False

def auto_int(x):
    return int(x, 0)


parser = argparse.ArgumentParser(description="""
Print a small number of TCAM entries that together match any value
in the range [min, max], where the value to match is bit-width bits wide.""")
parser.add_argument('--debug', dest='debug', action='store_true',
                    help="""Enable extra debug messages.""")
parser.add_argument('--test', dest='test', action='store_true',
                    help="""Perform exhaustive test of _all_ ranges with the given width in bits.  Warnings: this is reasonably fast for W <= 10, but the number of test cases grows roughly as 2^(2*W)""")
parser.add_argument('--bit-width', dest='W', type=int, required=True,
                    help="""The width in bits of the field to match on.""")
parser.add_argument('--min', dest='min', type=auto_int, required=True,
                    help="""The minimum value of the range to match.  Interpreted as Python literal number, allowing 0x prefix for base 16, 0o for base 8, and 0b for base 2.""")
parser.add_argument('--max', dest='max', type=auto_int, required=True,
                    help="""The maximum value of the range to match.  Allows same bases as --min""")
args = parser.parse_known_args()[0]

debug = args.debug
#print("debug=%s" % (debug))
#print('W=%d' % (args.W))
#print('min=%d' % (args.min))
#print('max=%d' % (args.max))

all_prefix_masks = {}

def calculate_all_prefix_masks_dict(W):
    all_prefix_masks_dict = {}
    W_mask = (1 << W) - 1
    mask = W_mask
    while mask != 0:
        all_prefix_masks_dict[mask] = True
        mask = (mask << 1) & W_mask
    all_prefix_masks_dict[0] = True
    return all_prefix_masks_dict


def is_prefix_mask(W, mask):
    if W not in all_prefix_masks:
        all_prefix_masks[W] = calculate_all_prefix_masks_dict(W)
    return mask in all_prefix_masks[W]


def is_value_mask(W, entry):
    assert type(W) is int
    assert type(entry) is dict
    assert "value" in entry
    assert "mask" in entry
    assert type(entry["value"]) is int
    assert type(entry["mask"]) is int
    max_field_val = (1 << W) - 1
    value = entry["value"]
    mask = entry["mask"]
    assert value >= 0 and value <= max_field_val
    assert mask >= 0 and mask <= max_field_val
    if (value & mask) != value:
        print("W=%d value=%d mask=%d" % (W, value, mask))
    assert (value & mask) == value
    return True


def is_prefix_value_mask(W, entry):
    assert is_value_mask(W, entry)
    assert is_prefix_mask(W, entry["mask"])
    return True


def prefix_mask_range(W, entry):
    assert is_prefix_value_mask(W, entry)
    W_mask = (1 << W) - 1
    return {"min": entry["value"],
            "max": entry["value"] + (W_mask ^ entry["mask"])}


def part_tcam_entries(W, extreme_val, bitpos, side):
    W_mask = (1 << W) - 1
    tcam_entries = []
    if debug:
        print("W=%d extreme_val=%d bitpos=%d side=%s"
              "" % (W, extreme_val, bitpos, side))
    while bitpos >= 0:
#        if debug:
#            print("part_tcam_entries step #1: bitpos=%d"
#                  "" % (bitpos))
        mask = (1 << bitpos) - 1
        if side == 'left':
            check_val = 0
        else:
            check_val = mask
        if (extreme_val & mask) == check_val:
            entry = {"value": extreme_val ^ check_val, "mask": W_mask ^ mask}
            if debug:
                debug_range = prefix_mask_range(W, entry)
                print("bitpos=%d value=%d mask=%d min=%d max=%d"
                      "" % (bitpos, entry["value"], entry["mask"],
                            debug_range["min"], debug_range["max"]))
            tcam_entries.append(entry)
            break
        bitpos = bitpos - 1
        bitpos_mask = 1 << bitpos
        if side == 'left':
            check_val = 0
        else:
            check_val = bitpos_mask
        if (extreme_val & bitpos_mask) == check_val:
            lsb_mask = bitpos_mask - 1
            tmp_mask = W_mask ^ lsb_mask
            entry = {"value": (extreme_val ^ bitpos_mask) & tmp_mask,
                     "mask": tmp_mask}
            if debug:
#                print("part_tcam_entries case #2: bitpos=%d value=%d mask=%d"
#                      "" % (bitpos, entry["value"], entry["mask"]))
                debug_range = prefix_mask_range(W, entry)
                print("bitpos=%d value=%d mask=%d min=%d max=%d"
                      "" % (bitpos, entry["value"], entry["mask"],
                            debug_range["min"], debug_range["max"]))
            tcam_entries.append(entry)
    return tcam_entries


def range_to_tcam_entries(W, min_val, max_val):
    if type(W) is not int:
        msg = ("W must be int but got %s" % (type(W)))
        raise TypeError(msg)
    if type(min_val) is not int:
        msg = ("min_val must be int but got %s" % (type(min_val)))
        raise TypeError(msg)
    if type(max_val) is not int:
        msg = ("max_val must be int but got %s" % (type(max_val)))
        raise TypeError(msg)

    max_field_val = (1 << W) - 1

    #print('max_field_val=%d' % (max_field_val))
    if min_val < 0 or min_val > max_field_val:
        msg = ("Error: min=%d outside of range of W-bit value [0, %d]"
               "" % (min_val, max_field_val))
        raise ValueError(msg)
    
    if max_val < 0 or max_val > max_field_val:
        msg = ("Error: max=%d outside of range of W-bit value [0, %d]"
               "" % (max_val, max_field_val))
        raise ValueError(msg)

    if min_val > max_val:
        msg = ("Error: min=%d is larger than max=%d"
               "" % (min_val, max_val))
        raise ValueError(msg)

    tcam_entries = []

    if min_val == max_val:
        entry = {"value": min_val, "mask": max_field_val}
        tcam_entries.append(entry)
        return tcam_entries

    # else the min and max values are different, so there is some bit
    # position where they differ.  Find the most significant bit
    # position where they differ
    bitpos = W - 1
    bitpos_mask = 1 << bitpos
    while (min_val & bitpos_mask) == (max_val & bitpos_mask):
        bitpos = bitpos - 1
        bitpos_mask = bitpos_mask >> 1

    # Check for special case of a single TCAM entry covering the
    # entire range
    mask = (1 << (bitpos + 1)) - 1
    if ((min_val & mask) == 0) and ((max_val & mask) == mask):
        entry = {"value": min_val, "mask": max_field_val ^ mask}
        tcam_entries.append(entry)
        return tcam_entries

    # Otherwise, it requires at least 2 TCAM entries to cover the
    # range: one for the "left part" with most significant differing
    # bit equal to 0, and one for the "right part" with most
    # significant differing bit equal to 1.
    left_part_tcam_entries = part_tcam_entries(W, min_val, bitpos, "left")
    right_part_tcam_entries = part_tcam_entries(W, max_val, bitpos, "right")
    #right_part_tcam_entries = []
    
    tcam_entries = left_part_tcam_entries + right_part_tcam_entries
    return tcam_entries


def sorted_tcam_entries(W, entries):
    entries_with_ranges = []
    for entry in entries:
        range = prefix_mask_range(W, entry)
        entry_with_range = {"value": entry["value"],
                            "mask": entry["mask"],
                            "range": range}
        entries_with_ranges.append(entry_with_range)
    return sorted(entries_with_ranges, key=lambda x: x["range"]["min"])


def debug_print_tcam_entries(W, tcam_entries):
    n = len(tcam_entries)
    entries_with_ranges = sorted_tcam_entries(W, entries)
    print("idx      value      mask   range_min range_max")
    print("         (hex)      (hex)  (decimal) (decimal)")
    for i in range(n):
        print("%2d %10x %10x %10d %10d"
              "" % (i,
                    entries_with_ranges[i]["value"],
                    entries_with_ranges[i]["mask"],
                    entries_with_ranges[i]["range"]["min"],
                    entries_with_ranges[i]["range"]["max"]))


def check_tcam_entries(W, min_val, max_val, entries):
    entries_with_ranges = sorted_tcam_entries(W, entries)
    n = len(entries_with_ranges)
    if entries_with_ranges[0]["range"]["min"] != min_val:
        msg = ("min value of first range %d != %d = min_val"
               "" % (entries_with_ranges[0]["range"]["min"], min_val))
        raise ValueError(msg)
    if entries_with_ranges[n-1]["range"]["max"] != max_val:
        msg = ("min value of first range %d != %d = max_val"
               "" % (entries_with_ranges[n-1]["range"]["max"], max_val))
        raise ValueError(msg)
    for i in range(1, n):
        if entries_with_ranges[i]["range"]["min"] != (entries_with_ranges[i-1]["range"]["max"] + 1):
            msg = ("min value of range %d is %d but expected one more than max of range %d, which is %d"
                   "" % (i,
                         entries_with_ranges[i]["range"]["min"],
                         i-1,
                         entries_with_ranges[i-1]["range"]["max"]))
            raise ValueError(msg)
    return True


entries = range_to_tcam_entries(args.W, args.min, args.max)

debug_print_tcam_entries(args.W, entries)
check_tcam_entries(args.W, args.min, args.max, entries)

# Exhaustive test of all ranges that fit in width W bits
if args.test:
    n = 0
    for min_val in range(1 << args.W):
        for max_val in range(min_val, 1 << args.W):
            entries = range_to_tcam_entries(args.W, min_val, max_val)
            check_tcam_entries(args.W, min_val, max_val, entries)
            n += 1
    print("Successfully checked %d ranges with width W=%d bits"
          "" % (n, args.W))
