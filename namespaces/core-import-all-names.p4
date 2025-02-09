// Copyright 2021 Andy Fingerhut
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

// The following is all of the top level names in this file as of
// 2021-Dec-14:

// https://github.com/p4lang/p4c/blob/main/p4include/core.p4

// From 2016 until the end of 2021, _no_ new top level names were
// added to this file.

// There were new values of the type 'error' added during those 6
// years, and one new 2-argument signature for the 'emit' method for
// extern object 'packet_out'.

// The match_kind list in core.p4 has always been exact, lpm, ternary

// There are a total of 4 top level names

from core import
    packet_in,
    packet_out,
    verify,
    NoAction;
