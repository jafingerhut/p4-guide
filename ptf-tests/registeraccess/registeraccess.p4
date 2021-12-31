/*
Copyright 2021 Intel Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <core.p4>
#include <v1model.p4>


header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

#define CPU_PORT 510

// Note on the names of the controller_header header types:

// packet_out and packet_in are named here from the perspective of the
// controller, and that is how these messages are named in the
// P4Runtime API specification as well.

// Thus packet_out is a packet sent out of the controller to the
// switch, which becomes a packet received by the switch on port
// CPU_PORT.

// A packet sent by the switch to port CPU_PORT becomes a PacketIn
// message to the controller.

// When running with simple_switch_grpc, you must provide the
// following command line option to enable the ability for the
// software switch to receive and send such messages:
//
//     --cpu-port 510

typedef bit<16> PortIdToController_t;

enum bit<8> ControllerOpcode_t {
    NO_OP          = 0,
    READ_REGISTER  = 1,
    WRITE_REGISTER = 2
}

enum bit<8> PuntReason_t {
    UNRECOGNIZED_OPCODE = 1,
    OPERATION_RESPONSE  = 2
}

@controller_header("packet_out")
header packet_out_header_t {
    ControllerOpcode_t   opcode;
    bit<8>  reserved1;
    bit<32> operand0;
    bit<32> operand1;
    bit<32> operand2;
    bit<32> operand3;
}

@controller_header("packet_in")
header packet_in_header_t {
    PortIdToController_t input_port;
    PuntReason_t         punt_reason;
    ControllerOpcode_t   opcode;
    bit<32> operand0;
    bit<32> operand1;
    bit<32> operand2;
    bit<32> operand3;
}

const int SeqNumRegIndexWidth = 8;
const int NUM_SEQ_NUMS = (1 << SeqNumRegIndexWidth);
typedef bit<(SeqNumRegIndexWidth)> SeqNumRegIndex_t;
typedef bit<16> SeqNum_t;

struct metadata_t {
}

struct headers_t {
    packet_in_header_t  packet_in;
    packet_out_header_t packet_out;
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    const bit<16> ETHERTYPE_IPV4 = 16w0x0800;

    state start {
        transition check_for_cpu_port;
    }
    state check_for_cpu_port {
        transition select (stdmeta.ingress_port) {
            CPU_PORT: parse_controller_packet_out_header;
            default: parse_ethernet;
        }
    }
    state parse_controller_packet_out_header {
        packet.extract(hdr.packet_out);
        transition accept;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    register<SeqNum_t>(NUM_SEQ_NUMS) seq_num_reg;

    action send_to_controller_simple(PuntReason_t punt_reason) {
        stdmeta.egress_spec = CPU_PORT;
        hdr.packet_in.setValid();
        hdr.packet_in.input_port = (PortIdToController_t) stdmeta.ingress_port;
        hdr.packet_in.punt_reason = punt_reason;
        hdr.packet_in.opcode = ControllerOpcode_t.NO_OP;
        hdr.packet_in.operand0 = 0;
        hdr.packet_in.operand1 = 0;
        hdr.packet_in.operand2 = 0;
        hdr.packet_in.operand3 = 0;
    }
    action send_to_controller_with_details(
        PuntReason_t       punt_reason,
        ControllerOpcode_t opcode,
        bit<32> operand0,
        bit<32> operand1,
        bit<32> operand2,
        bit<32> operand3)
    {
        stdmeta.egress_spec = CPU_PORT;
        hdr.packet_in.setValid();
        hdr.packet_in.input_port = (PortIdToController_t) stdmeta.ingress_port;
        hdr.packet_in.punt_reason = punt_reason;
        hdr.packet_in.opcode = opcode;
        hdr.packet_in.operand0 = operand0;
        hdr.packet_in.operand1 = operand1;
        hdr.packet_in.operand2 = operand2;
        hdr.packet_in.operand3 = operand3;
    }
    action my_drop() {
        mark_to_drop(stdmeta);
    }

    table dbgPacketOutHdr {
        key = {
            hdr.packet_out.opcode : exact;
            hdr.packet_out.reserved1 : exact;
            hdr.packet_out.operand0 : exact;
            hdr.packet_out.operand1 : exact;
            hdr.packet_out.operand2 : exact;
            hdr.packet_out.operand3 : exact;
        }
        actions = { NoAction; }
        const default_action = NoAction;
    }

    apply {
        if (hdr.packet_out.isValid()) {
            // Process packet from controller
            dbgPacketOutHdr.apply();
            switch (hdr.packet_out.opcode) {
                ControllerOpcode_t.NO_OP: {
                    log_msg("Processing packet-out with opcode NO_OP");
                }
                ControllerOpcode_t.READ_REGISTER: {
                    SeqNumRegIndex_t idx =
                        (SeqNumRegIndex_t) hdr.packet_out.operand0;
                    SeqNum_t read_data;
                    seq_num_reg.read(read_data, (bit<32>) idx);
                    
                    send_to_controller_with_details(
                        PuntReason_t.OPERATION_RESPONSE, hdr.packet_out.opcode,
                        (bit<32>) idx, (bit<32>) read_data, 0, 0);
                    hdr.packet_out.setInvalid();
                    log_msg("Processing packet-out with opcode READ_REGISTER, read index {} value {}",
                        {idx, read_data});
                }
                ControllerOpcode_t.WRITE_REGISTER: {
                    SeqNumRegIndex_t idx =
                        (SeqNumRegIndex_t) hdr.packet_out.operand0;
                    SeqNum_t write_data = (SeqNum_t) hdr.packet_out.operand1;
                    log_msg("Processing packet-out with opcode WRITE_REGISTER, write index {} value {}",
                        {idx, write_data});
                    seq_num_reg.write((bit<32>) idx, write_data);

                    send_to_controller_with_details(
                        PuntReason_t.OPERATION_RESPONSE, hdr.packet_out.opcode,
                        (bit<32>) idx, (bit<32>) write_data, 0, 0);
                    hdr.packet_out.setInvalid();
                }
                default: {
                    log_msg("Processing packet-out with unknown opcode {}",
                        {hdr.packet_out.opcode});
                    send_to_controller_with_details(
                        PuntReason_t.UNRECOGNIZED_OPCODE, hdr.packet_out.opcode,
                        hdr.packet_out.operand0, hdr.packet_out.operand1,
                        hdr.packet_out.operand2, hdr.packet_out.operand3);
                    hdr.packet_out.setInvalid();
                }
            }
        } else if (hdr.ipv4.isValid()) {
            // Update sequence number state for data packet
            SeqNumRegIndex_t idx = (SeqNumRegIndex_t) hdr.ipv4.dstAddr;
            SeqNum_t pkt_seq_num = (SeqNum_t) hdr.ipv4.identification;
            bit<16> cur_exp_seq_num;
            bit<16> next_exp_seq_num;
            seq_num_reg.read(cur_exp_seq_num, (bit<32>) idx);
            // Determine whether the packet sequence number is in the
            // "next half space", i.e. in the range [cur_exp_seq_num,
            // cur_exp_seq_num + 2^15 - 1], with wraparound.  Note
            // that the normal P4_16 '-' and '+' operators on type
            // bit<W> operands wraps around, modulo 2^W.
            bit<16> delta = pkt_seq_num - cur_exp_seq_num;
            if (delta[15:15] == 0) {
                // If yes, the packet is considered to be in order,
                // the packet is accepted and forwarded, and we update
                // the expected sequence number to be equal to the
                // packet sequence number plus 1 (perhaps wrapping
                // around).
                next_exp_seq_num = pkt_seq_num + 1;
                stdmeta.egress_spec = 2;
                log_msg("Processing IPv4 packet with index {} seq_num {} read seq_num {} wrote seq_num {} forward packet",
                    {idx, pkt_seq_num, cur_exp_seq_num, next_exp_seq_num});
            } else {
                // If not, it is in the "previous half space".  In
                // this case, the packet is considered to be out of
                // order, it is dropped, and we leave the expected
                // sequence number as it was.
                next_exp_seq_num = cur_exp_seq_num;
                my_drop();
                log_msg("Processing IPv4 packet with index {} seq_num {} read seq_num {} wrote seq_num {} drop packet",
                    {idx, pkt_seq_num, cur_exp_seq_num, next_exp_seq_num});
            }
            seq_num_reg.write((bit<32>) idx, next_exp_seq_num);
        } else {
            // A real L2/L3 switch would do something else than this
            // simple demo program does.
            my_drop();
            log_msg("Processing non-IPv4 packet: drop packet");
        }
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{
    apply {
    }
}

control deparserImpl(packet_out packet,
                     in headers_t hdr)
{
    apply {
        packet.emit(hdr.packet_in);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        verify_checksum(hdr.ipv4.isValid() && hdr.ipv4.ihl == 5,
            { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control updateChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        update_checksum(hdr.ipv4.isValid() && hdr.ipv4.ihl == 5,
            { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
