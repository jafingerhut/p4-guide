#! /usr/bin/env python3
# Copyright 2023 Andy Fingerhut
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


import sys

# Calculate a CRC of an input bit string using a given CRC polynomial,
# using a simple but slow 1-bit-at-a-time method as described on this
# Wikipedia page:

# https://en.wikipedia.org/wiki/Cyclic_redundancy_check

# Note: It is NOT the same as the one that uses strings.  This one
# uses arbitrary precision integers instead, so it is easier to
# translate into other languages using similar bit-wise integer
# operations.

# This program uses the convention of "feeding the bits of data" in
# from the most significant bit first to the least significant bit
# last.

# Also the convention that the CRC polynomial integer has bit position
# 0 for x^0 coefficient, bit position 1 for x^1 coefficient, and so
# on.  Thus I believe perhaps its least significant bit must be 1.
# TODO: Is that an actual requirement for CRC polynomials?

debug = 0

# Find the bit position of the most significant 1 bit in i, if any.
def find_most_significant_1_bitpos(i):
    assert i >= 0
    if i == 0:
        ret = -1
    elif i == 1:
        ret = 0
    else:     # i >= 2
        bitpos = 0
        mask = 1 << bitpos
        prev_bitpos = 0
        while mask <= i:
            if debug >= 2:
                print("dbg: #1 mask=%d bitpos=%d i=%d" % (mask, bitpos, i))
            prev_bitpos = bitpos
            if bitpos == 0:
                bitpos = 1
            else:
                bitpos *= 2
            mask = 1 << bitpos
        # if prev_mask = (1 << prev_bitpos), now we know that
        # prev_mask <= i < mask.

        # Because mask > i, masks's msb 1 is in a strictly larger
        # bit position than i's msb 1.

        # Because prev_mask <= i, prev_mask's msb 1 is either in
        # the same bit position as i's msb 1, or in a less
        # significant bit position.

        # Now do a binary search between bitpos and prev_bitpos to
        # find i's msb 1 position.
        bitpos_hi = bitpos
        mask_hi = mask

        bitpos_lo = prev_bitpos
        mask_lo = 1 << bitpos_lo

        # Maintain invariants:
        # (1 << bitpos_lo) <= i < (1 << bitpos_hi)
        # which implies that bitpos_lo < bitpos_hi
        while bitpos_hi != (bitpos_lo + 1):
            if debug >= 2:
                print("dbg: #2 bitpos_hi=%d bitpos_lo=%d" % (bitpos_hi, bitpos_lo))
            bitpos_mid = (bitpos_hi + bitpos_lo) // 2
            mask_mid = 1 << bitpos_mid
            if mask_mid > i:
                bitpos_hi = bitpos_mid
                mask_hi = mask_mid
            else:
                bitpos_lo = bitpos_mid
                mask_lo = mask_mid
        # Now we know bitpos_hi = (bitpos_lo + 1)
        # and invariant is still true.
        # So (1 << bitpos_lo) <= i < (1 << (bitpos_lo + 1))

        # Thus bitpos_lo is the bit position of i's most
        # significant 1 bit.
        ret = bitpos_lo
    return ret

def calc_crc(data, data_msb_1_bitpos, crc_poly, crc_poly_msb_1_bitpos,
             print_computation=False):
    padded_data = data << crc_poly_msb_1_bitpos
    data_bit_check_mask = 1 << (data_msb_1_bitpos + crc_poly_msb_1_bitpos)
    divisor = crc_poly << data_msb_1_bitpos

#    tmp1 = find_most_significant_1_bitpos(padded_data)
#    tmp2 = find_most_significant_1_bitpos(divisor)
#    if tmp1 != tmp2:
#        print("tmp1 = %d != %d = tmp2" % (tmp1, tmp2))
#        sys.exit(1)

    if print_computation:
        padded_data_bits = data_msb_1_bitpos + 1 + crc_poly_msb_1_bitpos
        data_format_str = '%%%ds' % (padded_data_bits)
        print(data_format_str % (bin(padded_data)[2:]))

    for j in range(data_msb_1_bitpos + crc_poly_msb_1_bitpos,
                   crc_poly_msb_1_bitpos - 1, -1):
        if (padded_data & data_bit_check_mask) != 0:
            padded_data ^= divisor
            if print_computation:
                leading_spaces = ' ' * (data_msb_1_bitpos + crc_poly_msb_1_bitpos - j)
                print("%s%s" % (leading_spaces, bin(crc_poly)[2:]))
                print("%s%s" % (leading_spaces, '-' * (crc_poly_msb_1_bitpos + 1)))
                print(data_format_str % (bin(padded_data)[2:]))
        data_bit_check_mask >>= 1
        divisor >>= 1
    return padded_data

def usage():
    print("usage: %s <data> <crc_poly>", file=sys.stderr)
    print("", file=sys.stderr)
    print("    <data> is an integer value to calculate the CRC of.", file=sys.stderr)
    print("    <crc_poly> is an integer value specifying the CRC polynomial to use.", file=sys.stderr)
    print("", file=sys.stderr)
    print("    todo: describe format of crc_poly", file=sys.stderr)
    print("", file=sys.stderr)
    print("    By default all integer input values are specified in decimal, unless you", file=sys.stderr)
    print("    prefix them with 0x for hex, 0b for binary, or 0o for octal.", file=sys.stderr)

if len(sys.argv) != 3:
    usage()
    sys.exit(1)

data_str = sys.argv[1]
data = int(data_str, 0)
crc_poly_str = sys.argv[2]
crc_poly = int(crc_poly_str, 0)

if data < 0:
    print("data must be non-negative.  Found %d (%s)"
          "" % (data, data_str),
          file=sys.stderr)
    sys.exit(1)

if crc_poly < 1:
    print("crc_poly must be at least 1.  Found %d (%s)"
          "" % (crc_poly, crc_poly_str),
          file=sys.stderr)
    sys.exit(1)

data_msb_1_bitpos = find_most_significant_1_bitpos(data)
crc_poly_msb_1_bitpos = find_most_significant_1_bitpos(crc_poly)
if debug >= 2:
    print("data_msb_1_bitpos=%d" % (data_msb_1_bitpos))
    print("data (binary): %s" % (bin(data)))
    print("mask (binary): %s" % (bin(1 << data_msb_1_bitpos)))

    print("crc_poly_msb_1_bitpos=%d" % (crc_poly_msb_1_bitpos))
    print("crc_poly (binary): %s" % (bin(crc_poly)))
    print("mask     (binary): %s" % (bin(1 << crc_poly_msb_1_bitpos)))

crc = calc_crc(data, data_msb_1_bitpos, crc_poly, crc_poly_msb_1_bitpos,
               print_computation=False)
print("%d-bit crc:" % (crc_poly_msb_1_bitpos))
crc_str = bin(crc)[2:]
crc_str = ('0' * (crc_poly_msb_1_bitpos - len(crc_str))) + crc_str
print(crc_str)

# Determine formulas that can calculate each bit of the output CRC as
# the XOR of a subset of the input bits.

data_bitpos_to_xor = []
for j in range(0, crc_poly_msb_1_bitpos):
    data_bitpos_to_xor.append([])

for data_bitpos in range(data_msb_1_bitpos, -1, -1):
    val = 1 << data_bitpos
    crc = calc_crc(val, data_msb_1_bitpos, crc_poly, crc_poly_msb_1_bitpos)
    for j in range(0, crc_poly_msb_1_bitpos):
        mask = 1 << j
        if (crc & mask) != 0:
            data_bitpos_to_xor[j].append(data_bitpos)

print("// Formulas to calculate CRC-%d with the following polynomial"
      "" % (crc_poly_msb_1_bitpos))
print("// from a %d-bit data input, with most significant data bit"
      "" % (data_msb_1_bitpos + 1))
print("// fed into the long division first.")
print("//")
print("// CRC polynomial as hex value: 0x%x" % (crc_poly))
print("// polynomial:")
print("// ", end='')
first = True
for j in range(crc_poly_msb_1_bitpos, -1, -1):
    mask = 1 << j
    if (crc_poly & mask) != 0:
        if first:
            first = False
        else:
            print(" + ", end='')
        print("x^%d" % (j), end='')
print("")

for j in range(crc_poly_msb_1_bitpos-1, -1, -1):
    print("crc[%d] = (" % (j), end='')
    first = True
    for k in data_bitpos_to_xor[j]:
        if first:
            first = False
        else:
            print(" ^ ", end='')
        print("data[%d]" % (k), end='')
    print(");")

sys.exit(0)

for data in range(0, (1 << (data_msb_1_bitpos + 1)) - 1):
    crc = calc_crc(data, data_msb_1_bitpos, crc_poly, crc_poly_msb_1_bitpos,
                   print_computation=False)
    data_str = bin(data)[2:]
    data_str = ('0' * (data_msb_1_bitpos + 1 - len(data_str))) + data_str
    crc_str = bin(crc)[2:]
    crc_str = ('0' * (crc_poly_msb_1_bitpos - len(crc_str))) + crc_str
    print("%s %s" % (data_str, crc_str))
