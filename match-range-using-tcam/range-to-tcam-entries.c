/*
* Copyright 2020, MNK Labs & Consulting
* http://mnkcg.com
*
* Author: Hemant Singh
*
* with minor additions for self-checking of results and exhaustive
* testing of all ranges for a particular bit width, by Andy Fingerhut.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
*/

/*
 * Compile:
 * $ gcc range-to-tcam-entries.c -o range-to-tcam-entries
 *
 * Warning: This code only works for bit width values up to the width
 * of the type 'long' on your system and C compiler, or perhaps one
 * less, which as of 2020 is likely to be 64 bits on many development
 * systems.  It is more likely to be correct for one less than that
 * width, although it might actually work for 64 bit wide fields, too.
 * Using an arbitrary precision type/library, with appropriate
 * function calls for the arithmetic operations on such large
 * integers, should enable the code to work for larger field widths.
 *
 * Print value/masks for bit width 16 for range [1, 5]:
 *
 * $ ./range-to-tcam-entries 16 1 5
 *
 * Print value/masks for the specified range, but also run exhaustive
 * tests for all possible ranges with the specified bit width.
 *
 * $ ./range-to-tcam-entries 10 1 5 test
 *
 * There are about 2^(2*W) such ranges for width W, so this requires a
 * bit of patience for values of W 12 or larger.  I have run it on my
 * machine for all values of W from 1 up to 12, and it found no
 * problems, so I have high confidence that this code is correct.
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

typedef unsigned long big_int;


struct tcam_entry {
     big_int value;
     big_int mask;
};

void init_range_sizes (int width,
                       int *out_range_sizes,
                       big_int *out_prefix_mask)
{
    big_int range_size = 1;
    big_int full_mask = (((big_int) 1) << width) - 1;
    big_int mask = full_mask;

    for (int i = 0; i <= width; i++) {
        out_prefix_mask[i] = mask;
        out_range_sizes[i] = range_size;
        mask = (mask << 1) & full_mask;
        range_size *= 2;
    }
}

big_int range_size_fn (int width, big_int mask)
{
    static int *range_sizes = NULL;
    static big_int *prefix_masks = NULL;
    
    if (range_sizes == NULL) {
        range_sizes = (int *) malloc((width + 1) * sizeof(int));
        assert(range_sizes != NULL);
        prefix_masks = (big_int *) malloc((width + 1) * sizeof(big_int));
        assert(prefix_masks != NULL);
        init_range_sizes(width, range_sizes, prefix_masks);
    }
    for (int i = 0; i <= width; i++) {
        if (mask == prefix_masks[i]) {
            return range_sizes[i];
        }
    }
    fprintf(stderr, "range_size(width=%d, mask=0x%016lx) found no matching mask.  Not a prefix mask, probably?\n",
            width, mask);
    exit(1);
}

int trailing_zeros (big_int n, int width)
{
    int zeros = 0;
    
    while (n > 0 && (n & 1) == 0) {
        zeros += 1;
        n >>= 1;
    }
    
    return (zeros < width) ? zeros : width;
}

#ifdef ORIGINAL_C_PLUS_PLUS_VERSION
// Return type comented out from original C++ version of code.
vector<tcam_entry>
#else   // ORIGINAL_C_PLUS_PLUS_VERSION
void
#endif  // ORIGINAL_C_PLUS_PLUS_VERSION
range_to_tcam_entries (int width, big_int min, big_int max, int do_print)
{
#ifdef ORIGINAL_C_PLUS_PLUS_VERSION
    vector<tcam_entry> entries;
#endif  // ORIGINAL_C_PLUS_PLUS_VERSION
    big_int remaining_range_size = max - min + 1;
    
    int first = 1;
    big_int prev_value_mask_max;
    big_int value_mask_min, value_mask_max;
    
    while (remaining_range_size > 0) {
        big_int range_size = ((big_int) 1) << trailing_zeros(min, width);
        
        while (range_size > remaining_range_size)
            range_size >>= 1;
        
        struct tcam_entry entry;
        
        entry.value = min;
        entry.mask = ~(range_size - 1) & ((((big_int) 1) << width) - 1);
        
#ifdef ORIGINAL_C_PLUS_PLUS_VERSION
        entries.push_back(entry);
#endif  // ORIGINAL_C_PLUS_PLUS_VERSION
        value_mask_min = entry.value;
        value_mask_max = entry.value + range_size_fn(width, entry.mask) - 1;
        if (first) {
            if (value_mask_min != min) {
                fprintf(stderr, "range_to_tcam_entries(width=%d, min=%016lx, max=%016lx) internal error: first value_mask_min=%016lx != min  Bug?\n",
                        width, min, max, value_mask_min);
                exit(1);
            }
            first = 0;
        } else {
            if (value_mask_min != prev_value_mask_max + 1) {
                fprintf(stderr, "range_to_tcam_entries(width=%d, min=%016lx, max=%016lx) internal error: value_mask_min=%016lx prev_value_mask_max=%016lx  Bug?\n",
                        width, min, max, value_mask_min, prev_value_mask_max)   ;
                exit(1);
            }
        }
        if (do_print) {
            printf("value 0x%016lx mask 0x%016lx min %lu max %lu\n",
                   entry.value,
                   entry.mask,
                   value_mask_min,
                   value_mask_max);
        }
        prev_value_mask_max = value_mask_max;

        remaining_range_size -= range_size;
        min += range_size;
    }
    if (prev_value_mask_max != max) {
        fprintf(stderr, "range_to_tcam_entries(width=%d, min=%016lx, max=%016lx) internal error: first prev_value_mask_max=%016lx != max  Bug?\n",
                width, min, max, prev_value_mask_max);
        exit(1);
    }
    
#ifdef ORIGINAL_C_PLUS_PLUS_VERSION
    return entries;
#endif  // ORIGINAL_C_PLUS_PLUS_VERSION
}

int
main (int argc, char *argv[])
{
    int width;
    big_int min_val, max_val;
    int exhaustive_test_for_width = 0;
    int do_print = 1;

    if (argc != 4 && argc != 5) {
        fprintf(stderr, "usage: %s <width_in_bits> <min_val> <max_val> [ test ]\n",
                argv[0]);
        exit(1);
    }
    if (argc == 5) {
        exhaustive_test_for_width = 1;
    }
    width = atoi(argv[1]);
    min_val = atol(argv[2]);
    max_val = atol(argv[3]);

    range_to_tcam_entries(width, min_val, max_val, do_print);
    
    big_int test_count = (big_int) 0;
    if (exhaustive_test_for_width) {
        // For the exhaustive testing, do the internal consistency
        // checks, but do not print the value/masks.
        do_print = 0;
        big_int max_val_for_width = (((big_int) 1) << width) - 1;
        for (min_val = (big_int) 0; min_val <= max_val_for_width; min_val++) {
            for (max_val = (big_int) min_val; max_val <= max_val_for_width; max_val++) {
                range_to_tcam_entries(width, min_val, max_val, do_print);
                ++test_count;
            }
        }
        printf("Did tests for all %lu ranges with width %d\n",
               test_count, width);
    }
}
