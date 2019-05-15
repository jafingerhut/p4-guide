/*
Copyright 2018 Cisco Systems, Inc.

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
// This code is trivial to adapt to the PSA architecture.  It is
// written using the v1model architecture only because it makes it
// easy to use the open source p4c compiler to check for syntax
// errors.
#include <v1model.p4>


// One possible extern definition for an object that makes the average
// queue depths in the packet buffer readable by P4 ingress code.

// The assumption here is that there is an extern that maintains the
// time-averaged depths of each queue, indexed by queue id.  It has a
// method call that lets you read one of these values.

// The _units_ in which these average queue depths are maintained are
// not terribly important, but it would be wastefully precise to
// measure them in microbits, and probably insufficiently precise to
// measure them in an integer number of gigabytes.

// For this example code, I am imagining an implementation where the
// average queue depths are in units of kilobytes (i.e. if you read a
// value X, it means that the average queue depth is closer to X*1024
// bytes than any other integer multiple of 1024 bytes).  Different
// implementations might choose other units that would also be
// reasonable.

// Assume for this example that the packet buffer has a capacity of 25
// Mbytes (Mybte = 2^20 bytes).  If the implementation allows a single
// queue to consume half of that capacity, that is 12.5 Mbytes of
// maximum instantaneous depth for any queue, or 12.5 * 1024 = 12,800
// Kbytes.  Thus an average queue depth will be represented as an
// integer in the range [0, 12,800], which fits in 14 bits.

typedef bit<9> QueueId_t;
typedef bit<14> QueueDepth_t;

extern AvgQueueDepths {
    AvgQueueDepths();
    QueueDepth_t read(in QueueId_t index);
}

// The above code would likely become part of some standard file to
// #include here.


// This value specifies size for table calc_red_drop_probability.  See
// Note 2 for one way to make it smaller.
const bit<32> NUM_RED_DROP_VALUES = 16384;

typedef bit<48>  EthernetAddress;

header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

struct Parsed_packet {
    Ethernet_h    ethernet;
}

struct metadata_t {
    bit<1> unicast;
    QueueId_t qid;
}

parser parserI(packet_in pkt,
               out Parsed_packet hdr,
               inout metadata_t meta,
               inout standard_metadata_t stdmeta) {
    state start {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control DeparserI(packet_out packet,
                  in Parsed_packet hdr) {
    apply { packet.emit(hdr.ethernet); }
}

control cIngress(inout Parsed_packet hdr,
                 inout metadata_t meta,
                 inout standard_metadata_t stdmeta)
{
    AvgQueueDepths() avg_queue_depth_inst;
    QueueDepth_t avg_qdepth;
    bit<9> drop_prob;

    action set_drop_probability (bit<9> drop_probability) {
        drop_prob = drop_probability;
    }
    table calc_red_drop_probability {
        key = {
            avg_qdepth : exact;
        }
        actions = {
            set_drop_probability;
        }
        const default_action = set_drop_probability(0);
        size = NUM_RED_DROP_VALUES;
    }

    apply {
        // Most of your ingress P4 code goes here.  See Note 1.

        avg_qdepth = avg_queue_depth_inst.read(meta.qid);
        // See Note 2
        calc_red_drop_probability.apply();
        bit<8> rand_val;
        random<bit<8>>(rand_val, 0, 255);
        // Of course someone might choose to do RED on multicast
        // packets in some way, too.  I am just avoiding the question
        // of what that might mean for this example.  One might also
        // wish to only apply RED for TCP packets, in which case the
        // 'if' condition would need to be changed to specify that.

        // drop_prob=0 means never do RED drop.  drop_prob in the
        // range [1, 256] means to drop a fraction (drop_prob/256) of
        // the time.  It is 9 bits in size so we can represent the
        // "always drop" case, desirable when the average queue depth
        // is high enough.
        if ((meta.unicast == 1) && ((bit<9>) rand_val < drop_prob)) {
            mark_to_drop(stdmeta);
        }
    }
}

// Note 1:

// Among other things, the earlier ingress code would need to
// determine whether the packet should be dropped for reasons other
// than RED, e.g. it matches a security filter rule that dictates the
// packet should be dropped.  If it is not dropped, the code should
// also determine to which output port (or ports!) it should be sent.

// Assume that these values have been assigned values before the RED
// code begins:

// + meta.qid - the queue id that the packet will be enqueued
//   in, if it is not dropped.  This will typically be a
//   function of the packet's destined output port, and its
//   class of service.

// + meta.unicast - 1 if the packet is unicast, 0 if multicast


// Note 2: RED means Random Early _Detection_, not Random Early
// _Discard_ or Random Early _Drop_:
// https://en.wikipedia.org/wiki/Random_early_detection
//
// The action taken when a packet is "detected" could be to mark it as
// having experienced congestion, e.g. via ECN marking in the header.
// It seems straightforward to me to say: no extern should have one of
// these behaviors built into it.  Instead you write the desired one
// (or more than one) of these behaviors in your P4 program.  That is
// what P4 is _for_, to define the packet processing behavior you
// want.
//
// Despite this, I am going to call the probability being determined
// the "drop probability", since it is commonly called that.
//
// Calculating this probability could be done in many slightly varying
// ways other than what is shown here, trading off table size for
// arithmetic calculations.  The way demonstrated here does the
// 'calculation' by a straightforward table lookup.  The control plane
// software can configure whatever function from average queue depth
// to drop probability that it wants.
//
// One way to reduce the table size cost of this solution: You could
// get a table with 1/2 as many entries by using all except the 1
// least significant bit of the avg_qdepth value as the table search
// key, instead of all of them -- or 1/(2^N) as many entries by using
// all except the N least significant bits of avg_qdepth.  The
// engineering tradeoff you are making there is that the 'curve' of
// the function becomes more coarse.


control cEgress(inout Parsed_packet hdr,
                inout metadata_t meta,
                inout standard_metadata_t stdmeta) {
    apply { }
}

control vc(inout Parsed_packet hdr,
           inout metadata_t meta) {
    apply { }
}

control uc(inout Parsed_packet hdr,
           inout metadata_t meta) {
    apply { }
}

V1Switch(parserI(),
    vc(),
    cIngress(),
    cEgress(),
    uc(),
    DeparserI()) main;
