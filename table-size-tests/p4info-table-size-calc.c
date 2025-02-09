/*
 * Copyright 2023 Andy Fingerhut
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

// Suggested p4c behavior for calculating size of a table output to
// a P4Info file.

// See this Google Sheet for current p4c behavior as of 2023-Sep-12:
// https://docs.google.com/spreadsheets/d/1-jme-7eVRXm-LrkjafQHXpava1O0s8VcAYyb9OZgtuU

bool keyless = false;
bool has_const_entries = false;
bool has_entries = false;
int N;
int p4info_size;

if ('key' property not specified, or 'key' specified as empty list { }) {
    keyless = true;
}
if ('const entries' property specified) {
    has_const_entries = true;
    N = (# of entries specified in source code as value of 'const entries');
} else if ('entries' property specified) {
    has_entries = true;
    N = (# of entries specified in source code as value of 'entries');
} else {
    N = 0;
}
if (keyless && (has_const_entries || has_entries) && (N > 0)) {
    error "no entries can be specified for keyless table $tablename";
    return;
}
if (has_const_entries) {
    // p4info_size is always N, regardless of what the developer specified
    p4info_size = N;
    if ('size' property specified) {
        if (size != N) {
            warn "Using size $N for table $tablename with $N entries in 'const entries', instead of specified value $size";
        }
    } else {
        warn "Using size $N for table $tablename with $N entries in 'const entries' (no size was specified)";
    }
} else if (has_entries) {
    // p4info_size is always at least N, regardless of what the
    // developer specified.
    if ('size' property specified) {
        if (size < N) {
            warn "Using size $N for table $tablename with $N entries in 'entries', instead of specified value $size";
            p4info_size = N;
        } else {
            p4info_size = size;
        }
    } else {
        warn "Using size $N for table $tablename with $N entries in 'entries' (no size was specified)";
        p4info_size = N;
    }
} else {    // no 'const entries', nor 'entries'
    if (keyless) {
        // Similar to has_const_entries with an empty list of entries,
        // but different warning messages.
        p4info_size = 0;
        if ('size' property specified) {
            if (size != 0) {
                warn "using size 0 instead of specified value $size for keyless table $tablename";
            }
        } else {
            warn "using size 0 for keyless table $tablename (no size was specified)";
        }
    } else {
        // "Normal" table with one or more key fields, and neither
        // 'const entries' nor 'entries' specified.
        if ('size' property specified) {
            p4info_size = size;
        } else {
            p4info_size = default_normal_table_size_if_not_specified;
            warn "using default size $p4info_size for table $tablename (no size was specified)";
        }
    }
}
