#! /usr/bin/env python3
# Copyright 2024 Andy Fingerhut
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


######################################################################
# Parsing optional command line arguments
######################################################################

import collections
import argparse
import sys


def auto_int(x):
    return int(x, 0)


parser = argparse.ArgumentParser(description="""
Print a small number of TCAM entries that together match any value
in the range [min, max], where the value to match is bit-width bits wide.""")
parser.add_argument('--debug', dest='debug', action='store_true',
                    help="""Enable extra debug messages.""")
parser.add_argument('--test', dest='test', action='store_true',
                    help="""Perform exhaustive test of _all_ ranges with the given width in bits.  Warnings: this is reasonably fast for W <= 10, but the number of test cases grows roughly as 2^(2*W)""")
parser.add_argument('--compare', dest='compare', action='store_true',
                    help="""Perform exhaustive comparison of _all_ ranges for both algorithms.""")
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


def int_to_bin_str(int_val, W):
    max_val = (1 << W) - 1
    if int_val < 0 or int_val > max_val:
        msg = ("Error: int_val=%d is outside of range [0, %d]"
               "" % (int_val, max_val))
        raise ValueError(msg)
    if W == 0:
        return ""
    bin_str = format(int_val, 'b')
    if len(bin_str) < W:
        bin_str = ('0' * (W - len(bin_str))) + bin_str
    return bin_str


def one_mask(msb, lsb):
    if msb < lsb-1:
        msg = ("Error: msb=%d < %d=lsb"
               "" % (msb, lsb))
        raise ValueError(msg)
    if lsb < 0:
        msg = ("Error: lsb=%d < 0"
               "" % (lsb))
        raise ValueError(msg)
    if msb == (lsb-1):
        return 0
    W = msb - lsb + 1
    mask = (1 << W) - 1
    mask <<= lsb
    return mask


def extract(val, msb, lsb):
    if msb < lsb-1:
        msg = ("Error: msb=%d < %d=lsb"
               "" % (msb, lsb))
        raise ValueError(msg)
    if lsb < 0:
        msg = ("Error: lsb=%d < 0"
               "" % (lsb))
        raise ValueError(msg)
    if msb == (lsb-1):
        return 0
    val >>= lsb
    return val & one_mask(msb-lsb, 0)


def find_one_bit_indices(val):
    idx = 0
    mask = 1
    indices = []
    while mask <= val:
        if (val & mask) != 0:
            indices.append(idx)
        idx += 1
        mask <<= 1
    return indices


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


def range_to_prefix_tcam_entries(W, min_val, max_val):
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


# Calculate a minimum set of TCAM entries that matches the range,
# based upon the algorithm of Figure 1 in the following paper:
#
#     Baruch Schieber, Daniel Geist, and Ayal Zaks, "Computing the
#     minimum DNF representation of Boolean functions defined by
#     intervals", Discrete Applied Mathematics, Volume 149, Number 1,
#     pp. 154-173, 2005, https://doi.org/10.1016/j.dam.2004.08.009

def range_to_tcam_entries_SGZ_helper(W, min_val, max_val):
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

#    print("--> SGZ W=%d min_val=%d max_val=%d" % (W, min_val, max_val))
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
        return [int_to_bin_str(min_val, W)]
        #return [{"value": min_val, "mask": max_field_val}]
    if (min_val == 0) and (max_val == max_field_val):
        return ['x' * W]
        #return [{"value": 0, "mask": 0}]
    min_val_msb = min_val >> (W-1)
    max_val_msb = max_val >> (W-1)
    if min_val_msb == max_val_msb:
        T = range_to_tcam_entries_SGZ_helper(W-1, extract(min_val, W-2, 0),
                                             extract(max_val, W-2, 0))
        min_val_msb_str = int_to_bin_str(min_val_msb, 1)
        #msb_mask = 1 << (W-1)
        #msb_bit_val = min_val_msb << (W-1)
        for entry in T:
            tcam_entries.append(min_val_msb_str + entry)
            #tcam_entries.append({"value": entry["value"] | msb_bit_val,
            #                     "mask": entry["mask"] | msb_mask})
        return tcam_entries
    if min_val == 0:
        c = max_val + 1
        one_bit_indices = find_one_bit_indices(c)
        for idx in one_bit_indices:
            # idx = (W-1) -> slice_width=0,  slice_lsb=W
            # idx = 0 -> slice_width=W-1,    slice_lsb=1
            slice_lsb = idx + 1
            slice_width = W - slice_lsb
            tcam_entries.append(int_to_bin_str(c >> slice_lsb, slice_width)
                                + "0" + ("x" * idx))
            #if idx == (W-1):
            #    mask1 = 0
            #else:
            #    mask1 = one_mask(W-1, idx+1)
            #mask2 = one_mask(W-1, idx)
            #tcam_entries.append({"value": c & mask1, "mask": mask2})
        return tcam_entries
    if max_val == max_field_val:
        d = min_val - 1
        d_complement = d ^ max_field_val
        zero_bit_indices = find_one_bit_indices(d_complement)
        for idx in zero_bit_indices:
            slice_lsb = idx + 1
            slice_width = W - slice_lsb
            tcam_entries.append(int_to_bin_str(d >> slice_lsb, slice_width)
                                + "1" + ("x" * idx))
            #if idx == (W-1):
            #    mask1 = 0
            #else:
            #    mask1 = one_mask(W-1, idx+1)
            #mask2 = one_mask(W-1, idx)
            #tcam_entries.append({"value": (d & mask1) + (1 << idx),
            #                     "mask": mask2})
        return tcam_entries

    if W < 2:
        msg = ("Error: W=%d < 2 in case where it should be >= 2"
               "" % (W))
        raise ValueError(msg)

    min_val_2_msbs = min_val >> (W-2)
    max_val_2_msbs = max_val >> (W-2)
#    print("    dbg min_val_2_msbs=%d max_val_2_msbs=%d"
#          "" % (min_val_2_msbs, max_val_2_msbs))
    if (min_val_2_msbs == 1) and (max_val_2_msbs == 2):
        T1 = range_to_tcam_entries_SGZ_helper(W-2, extract(min_val, W-3, 0),
                                              one_mask(W-3, 0))
        T2 = range_to_tcam_entries_SGZ_helper(W-2, 0,
                                              extract(max_val, W-3, 0))
        for vm in T1:
            tcam_entries.append("01" + vm)
            #tcam_entries.append({"value": (1 << (W-2)) + vm["value"],
            #                     "mask": vm["mask"] + one_mask(W-1,W-2)})
        for vm in T2:
            tcam_entries.append("10" + vm)
            #tcam_entries.append({"value": (2 << (W-2)) + vm["value"],
            #                     "mask": vm["mask"] + one_mask(W-1,W-2)})
        return tcam_entries

    if (min_val_2_msbs == 0) and (max_val_2_msbs == 2):
        T = range_to_tcam_entries_SGZ_helper(W-1, extract(min_val, W-3, 0),
                                             (extract(max_val, W-1, W-1) << (W-2)) |
                                             extract(max_val, W-3, 0))
        for vm in T:
            tcam_entries.append(vm[0] + "0" + vm[1:])
        tcam_entries.append("01" + ("x" * (W-2)))
        return tcam_entries

    if (min_val_2_msbs == 1) and (max_val_2_msbs == 3):
        T = range_to_tcam_entries_SGZ_helper(W-1, extract(min_val, W-3, 0),
                                             (extract(max_val, W-1, W-1) << (W-2)) |
                                             extract(max_val, W-3, 0))
        for vm in T:
            tcam_entries.append(vm[0] + "1" + vm[1:])
        tcam_entries.append("10" + ("x" * (W-2)))
        return tcam_entries

    if (min_val_2_msbs == 0) and (max_val_2_msbs == 3):
        tmp = 1
        m = one_mask(W-1, W-tmp)
        while ((min_val & m) == 0) and ((max_val & m) == m):
            j = tmp
            tmp += 1
            m = one_mask(W-1, W-tmp)
        T = ["unused_index_0_val"]
        i = 1
        while i <= j-1:
            T.append(("x" * (i-1)) + "01" + ("x" * (j-1-i)))
            i += 1
        T.append("1" + ("x" * (j-2)) + "0")
        Tpp = range_to_tcam_entries_SGZ_helper(W-j+1,
                                               extract(min_val, W-j, 0),
                                               extract(max_val, W-j, 0))
        min_val_slice = extract(min_val, W-j-1, 0)
        max_val_slice = extract(max_val, W-j-1, 0)
        if max_val_slice < min_val_slice - 1:
            i = 1
            while i <= j:
                tcam_entries.append(T[i] + ("x" * (W-j)))
                i += 1
            for vm in Tpp:
                tcam_entries.append(("x" * (j-1)) + vm)
            return tcam_entries
        else:
            i = 1
            while i <= j-1:
                tcam_entries.append(T[i] + ("x" * (W-j)))
                i += 1
            for vm in Tpp:
                if vm[0] == "1":
                    tcam_entries.append("1" + ("x" * (j-1)) + vm[1:])
                else:
                    tcam_entries.append(("x" * (j-1)) + vm)
            return tcam_entries

    msg = ("Error: W=%d min_val=%d max_val=%d not implemented yet"
           "" % (W, min_val, max_val))
    raise ValueError(msg)


def range_to_tcam_entries_SGZ(W, min_val, max_val):
    vmstr_entries = range_to_tcam_entries_SGZ_helper(W, min_val, max_val)
    entries = []
    for vmstr in vmstr_entries:
        entries.append(convert_vmstr_to_value_mask(vmstr, W))
    return entries


def debug_print_tcam_entries(W, tcam_entries):
    n = len(tcam_entries)
    entries_with_ranges = sorted_tcam_entries(W, tcam_entries)
    print("idx      value      mask   range_min range_max")
    print("         (hex)      (hex)  (decimal) (decimal)")
    for i in range(n):
        print("%2d %10x %10x %10d %10d"
              "" % (i,
                    entries_with_ranges[i]["value"],
                    entries_with_ranges[i]["mask"],
                    entries_with_ranges[i]["range"]["min"],
                    entries_with_ranges[i]["range"]["max"]))


def convert_value_mask_to_vmstr(value_mask, W):
    assert is_value_mask(W, value_mask)
    val = value_mask["value"]
    mask = value_mask["mask"]
    tmp = 1 << W
    i = 0
    s = ""
    while i < W:
        tmp >>= 1
        if (mask & tmp) != 0:
            if (val & tmp) != 0:
                s += "1"
            else:
                s += "0"
        else:
            if (val & tmp) != 0:
                # Invalid -- entry cannot be matched by any key
                s += "I"
            else:
                s += "x"
        i += 1
    return s


def convert_vmstr_to_value_mask(vmstr, W):
    if len(vmstr) != W:
        msg = ("vmstr='%s' (length %d characters) should have length exactly W=%d"
               "" % (len(vmstr), W))
        raise ValueError(msg)
    tmp = 1 << W
    val = 0
    mask = 0
    for c in vmstr:
        tmp >>= 1
        if c == "0":
            mask |= tmp
        elif c == "1":
            mask |= tmp
            val |= tmp
        elif c == "x":
            # Nothing to do in this case
            pass
        else:
            msg = ("Found disallowed character '%s' in vmstr '%s'"
                   "" % (c, vmstr))
            raise ValueError(msg)
    return {"value": val, "mask": mask}


def find_matching_entry(key, entries):
    for e in entries:
        if (key & e["mask"]) == e["value"]:
            return e
    return None


# validate_tcam_entries_are_range:
#
# Try all possible key values K in the range [0, 2^W-1] and verify
# that:
# + If K is in the range [min_val, max_val], then it matches at least
#   one entry in entries
# + If K is not in the range [min_val, max_val], then it matches _no_
#   entries in entries

def validate_tcam_entries_are_range(W, min_val, max_val, entries):
    for k in range(1 << W):
        m = find_matching_entry(k, entries)
        if (min_val <= k) and (k <= max_val):
            if m is None:
                return {"error": True,
                        "status": "k did not match any TCAM entry, but it should have",
                        "k": k}
        else:
            if m is not None:
                return {"error": True,
                        "status": "k matched a TCAM entry, but it should not have",
                        "k": k}
    return {"error": False}


#entries = range_to_prefix_tcam_entries(args.W, args.min, args.max)
entries = range_to_tcam_entries_SGZ(args.W, args.min, args.max)

ents = [convert_value_mask_to_vmstr(x, args.W) for x in entries]
for entry in sorted(ents):
    print(entry)
ret = validate_tcam_entries_are_range(args.W, args.min, args.max, entries)
if ret["error"]:
    print("TCAM entries do NOT match range [%d, %d] correctly."
          "" % (args.min, args.max))
    print("For k=%d, %s" % (ret["k"], ret["status"]))
else:
    print("TCAM entries match range [%d, %d] correctly."
          "" % (args.min, args.max))
#sys.exit(0)

###debug_print_tcam_entries(args.W, entries)
#validate_tcam_entries_are_range(args.W, args.min, args.max, entries)

# Exhaustive test of all ranges that fit in width W bits
if args.test:
    n = 0
    for min_val in range(1 << args.W):
        for max_val in range(min_val, 1 << args.W):
            entries = range_to_tcam_entries_SGZ(args.W, min_val, max_val)
            ret = validate_tcam_entries_are_range(args.W, min_val, max_val, entries)
            if ret["error"]:
                print("TCAM entries do NOT match range [%d, %d] correctly."
                      "" % (args.min, args.max))
                print("For k=%d, %s" % (ret["k"], ret["status"]))
                sys.exit(1)
            n += 1
            if (n % 50000) == 0:
                print("... checked %d ranges so far" % (n))
    print("Successfully checked %d ranges with width W=%d bits"
          "" % (n, args.W))

def print_header_line(W, max_savings):
    print("%6s   " % "n1", end="")
    for savings in range(0,max_savings+1):
        print(" %6d" % (savings), end="")
    print("")

if args.compare:
    counts = collections.defaultdict(dict)
    savings_examples = {}
    num_entries_examples = {}
    n = 0
    for min_val in range(1 << args.W):
        for max_val in range(min_val, 1 << args.W):
            entries1 = range_to_prefix_tcam_entries(args.W, min_val, max_val)
            entries2 = range_to_tcam_entries_SGZ(args.W, min_val, max_val)
            n1 = len(entries1)
            n2 = len(entries2)
            if n2 in counts[n1]:
                counts[n1][n2] += 1
            else:
                counts[n1][n2] = 1
            savings = n1 - n2
            if savings not in savings_examples:
                savings_examples[savings] = {"min_val": min_val,
                                             "max_val": max_val}
            if n2 not in num_entries_examples:
                num_entries_examples[n2] = {"min_val": min_val,
                                            "max_val": max_val}
            n += 1
            if (n % 50000) == 0:
                print("... checked %d ranges so far" % (n))
    print("Successfully checked %d ranges with width W=%d bits"
          "" % (n, args.W))
    max_savings = 0
    savings_sum = 0
    for n1 in sorted(counts.keys()):
        for n2 in sorted(counts[n1].keys()):
            savings = n1 - n2
            savings_sum += savings * counts[n1][n2]
            if savings > max_savings:
                max_savings = savings
    print_header_line(args.W, max_savings)
    print("--------------------")
    for n1 in sorted(counts.keys()):
        print("%6d : " % (n1), end="")
        max_n2 = None
        max_savings_for_row = 0
        for n2 in counts[n1].keys():
            if (max_n2 is None) or (n2 > max_n2):
                max_n2 = n2
            savings = n1 - n2
            if savings > max_savings_for_row:
                max_savings_for_row = savings
        if max_n2 > n1:
            print("ERROR: n1=%d < max_n2=%d, which should not happen"
                  "" % (n1, max_n2))
        max_cols = min(n1+1, max_savings_for_row+1)
        cols_printed = 0
        for n2 in range(n1, -1, -1):
            if n2 in counts[n1]:
                c = counts[n1][n2]
            else:
                c = 0
            print(" %6d" % (c), end="")
            cols_printed += 1
            if cols_printed >= max_cols:
                break
        print("")
    print("--------------------")
    print_header_line(args.W, max_savings)
    print("average savings = %d / %d = %.3f"
          "" % (savings_sum, n, savings_sum / n))

    for savings in sorted(savings_examples.keys()):
        min_val = savings_examples[savings]["min_val"]
        max_val = savings_examples[savings]["max_val"]
        print("--------------------")
        print("Example of interval with savings=%d: [%d,%d]"
              "" % (savings, min_val, max_val))
        entries1 = range_to_prefix_tcam_entries(args.W, min_val, max_val)
        entries2 = range_to_tcam_entries_SGZ(args.W, min_val, max_val)
        e1 = [convert_value_mask_to_vmstr(x, args.W) for x in entries1]
        e2 = [convert_value_mask_to_vmstr(x, args.W) for x in entries2]
        print("Entries restricted to prefix value/masks:")
        for e in sorted(e1):
            print(e)
        print("Entries using SGZ algorithm:")
        for e in sorted(e2):
            print(e)

    for n2 in sorted(num_entries_examples.keys()):
        min_val = num_entries_examples[n2]["min_val"]
        max_val = num_entries_examples[n2]["max_val"]
        print("--------------------")
        print("Example of interval with %d as the optimal number of TCAM entries: [%d,%d]"
              "" % (n2, min_val, max_val))
        entries1 = range_to_prefix_tcam_entries(args.W, min_val, max_val)
        entries2 = range_to_tcam_entries_SGZ(args.W, min_val, max_val)
        e1 = [convert_value_mask_to_vmstr(x, args.W) for x in entries1]
        e2 = [convert_value_mask_to_vmstr(x, args.W) for x in entries2]
        print("Entries restricted to prefix value/masks:")
        for e in sorted(e1):
            print(e)
        print("Entries using SGZ algorithm:")
        for e in sorted(e2):
            print(e)
