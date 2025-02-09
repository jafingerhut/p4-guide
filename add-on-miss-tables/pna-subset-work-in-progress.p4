// Copyright 2020 Andy Fingerhut
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

// Everything in this file is expected to be in a Portable NIC
// Architecture standard "pna.p4" include file.  The details may not
// match exactly what is here, as PNA is a work in progress.

enum bit<1> PNA_Direction_t {
    NET_TO_HOST = 0,
    HOST_TO_NET = 1
}

typedef bit<10> CloneSessionId_t;
typedef bit<9>  PortId_t;
typedef bit<10> VMId_t;
typedef bit<2>  ExpireTimeSelection_t;
typedef bit<24> FlowId_t;

// Part of two work-in-progress standard metadata structs for PNA
struct pna_main_input_metadata_t {
    PNA_Direction_t direction;
    // input fields to main control that are only initialized if
    // direction == DIR_NET_TO_HOST
    PortId_t  input_port;
    // input fields to main control that are only initialized if
    // direction == DIR_HOST_TO_NET
    VMId_t    input_vm;
}

struct pna_main_output_metadata_t {
    bool   drop;
    bool   clone;            // false
    CloneSessionId_t         clone_session_id; // initial value is undefined

    // output fields from main control that are only used by PNA
    // device to decide what to do with the packet next if direction
    // == NET_TO_HOST
    VMId_t   dest_vm;

    // output fields from main control that are only used by PNA device
    // to decide what to do with the packet next if direction ==
    // HOST_TO_NET
    PortId_t dest_port;
}

extern FlowId_t allocate_flow_id();

extern bool add_entry<T>(string action_name, in T action_parameter_values);

extern Register<T, S> {
  Register(bit<32> size);
  Register(bit<32> size, T initial_value);
  @noSideEffects
  T    read  (in S index);
  void write (in S index, in T value);
}
