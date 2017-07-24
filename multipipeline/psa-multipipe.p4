/*
Copyright 2013-present Barefoot Networks, Inc.

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

#ifndef _PORTABLE_SWITCH_ARCHITECTURE_P4_
#define _PORTABLE_SWITCH_ARCHITECTURE_P4_

/**
 *   P4-16 declaration of the Portable Switch Architecture
 */

/**
 * These types need to be defined before including the architecture file
 * and the macro protecting them should be defined.
 */
#define PSA_CORE_TYPES
#ifdef PSA_CORE_TYPES
typedef bit<10> PortId_t;
typedef bit<10> MulticastGroup_t;
typedef bit<14> PacketLength_t;
typedef bit<16> EgressInstance_t;
typedef bit<8> ParserStatus_t;
typedef bit<16> ParserErrorLocation_t;
typedef bit<32> entry_key;           /// for DirectCounters

const   PortId_t         PORT_CPU = 255;

// typedef bit<unspecified> InstanceType_t;
// const   InstanceType_t   INSTANCE_NORMAL = unspecified;
#endif  // PSA_CORE_TYPES
#ifndef PSA_CORE_TYPES
#error "Please define the following types for PSA and the PSA_CORE_TYPES macro"
// BEGIN:Type_defns
typedef bit<unspecified> PortId_t;
typedef bit<unspecified> MulticastGroup_t;
typedef bit<unspecified> PacketLength_t;
typedef bit<unspecified> EgressInstance_t;
typedef bit<unspecified> ParserStatus_t;
typedef bit<unspecified> ParserErrorLocation_t;
typedef bit<unspecified> entry_key;           /// for DirectCounters

const   PortId_t         PORT_CPU = unspecified;
// END:Type_defns

// typedef bit<unspecified> InstanceType_t;
// const   InstanceType_t   INSTANCE_NORMAL = unspecified;
#endif

// BEGIN:Metadata_types
enum InstanceType_t { NORMAL_INSTANCE, CLONE_INSTANCE }

struct psa_parser_input_metadata_t {
  PortId_t                 ingress_port;
  InstanceType_t           instance_type;
}

struct psa_ingress_input_metadata_t {
  PortId_t                 ingress_port;
  InstanceType_t           instance_type;  /// Clone or Normal
  /// set by the runtime in the parser, these are not under programmer control
  ParserStatus_t           parser_status;
  ParserErrorLocation_t    parser_error_location;
}

struct psa_ingress_output_metadata_t {
  PortId_t                 egress_port;
}

struct psa_egress_input_metadata_t {
  PortId_t                 egress_port;
  InstanceType_t           instance_type;  /// Clone or Normal
  EgressInstance_t         instance;       /// instance coming from PRE
}
// END:Metadata_types

// BEGIN:Match_kinds
match_kind {
    range,   /// Used to represent min..max intervals
    selector /// Used for implementing dynamic_action_selection
}
// END:Match_kinds

// BEGIN:Cloning_methods
enum CloneMethod_t {
  /// Clone method         Packet source             Insertion point
  Ingress2Ingress,  /// original ingress,            Ingress parser
  Ingress2Egress,    /// post parse original ingress,  Buffering queue
  Egress2Ingress,   /// post deparse in egress,      Ingress parser
  Egress2Egress     /// inout to deparser in egress, Buffering queue
}
// END:Cloning_methods

extern PacketReplicationEngine {

  // PacketReplicationEngine(); /// No constructor. PRE is instantiated
                                /// by the architecture.
    void send_to_port (in PortId_t port);
    void multicast (in MulticastGroup_t multicast_group);
    void drop      ();
    void clone     (in CloneMethod_t clone_method, in PortId_t port);
    void clone<T>  (in CloneMethod_t clone_method, in PortId_t port, in T data);
    void resubmit<T>(in T data, in PortId_t port);
    void recirculate<T>(in T data, in PortId_t port);
    void truncate(in bit<32> length);
}

extern BufferingQueueingEngine {

  // BufferingQueueingEngine(); /// No constructor. BQE is instantiated
                                /// by the architecture.

    void send_to_port (in PortId_t port);
    void drop      ();
    void truncate(in bit<32> length);
}

// BEGIN:Hash_algorithms
enum HashAlgorithm {
  identity,
  crc32,
  crc32_custom,
  crc16,
  crc16_custom,
  ones_complement16,  /// One's complement 16-bit sum used for IPv4 headers,
                      /// TCP, and UDP.
  random              /// are random hash algorithms useful?
}
// END:Hash_algorithms

// BEGIN:Hash_extern
extern Hash<O> {
  /// Constructor
  Hash(HashAlgorithm algo);

  /// Compute the hash for data.
  /// @param data The data over which to calculate the hash.
  /// @return The hash value.
  O getHash<D>(in D data);

  /// Compute the hash for data, with modulo by max, then add base.
  /// @param base Minimum return value.
  /// @param data The data over which to calculate the hash.
  /// @param max The hash value is divided by max to get modulo.
  ///        An implementation may limit the largest value supported,
  ///        e.g. to a value like 32, or 256.
  /// @return (base + (h % max)) where h is the hash value.
  O getHash<T, D>(in T base, in D data, in T max);
}
// END:Hash_extern

// BEGIN:Checksum_extern
extern Checksum<W> {
  Checksum(HashAlgorithm hash);          /// constructor
  void clear();              /// prepare unit for computation
  void update<T>(in T data); /// add data to checksum
  void remove<T>(in T data); /// remove data from existing checksum
  W    get();      	     /// get the checksum for data added since last clear
}
// END:Checksum_extern

// BEGIN:CounterType_defn
enum CounterType_t {
    packets,
    bytes,
    packets_and_bytes
}
// END:CounterType_defn

// BEGIN:Counter_extern
extern Counter<W, S> {
  Counter(S n_counters, W size_in_bits, CounterType_t counter_type);
  void count(in S index, in W increment);

  /*
  @ControlPlaneAPI
  {
    W    read<W>      (in S index);
    W    sync_read<W> (in S index);
    void set          (in S index, in W seed);
    void reset        (in S index);
    void start        (in S index);
    void stop         (in S index);
  }
  */
}
// END:Counter_extern

// BEGIN:DirectCounter_extern
extern DirectCounter<W> {
  DirectCounter(CounterType_t counter_type);
  void count();

  /*
  @ControlPlaneAPI
  {
    W    read<W>      (in entry_key key);
    W    sync_read<W> (in entry_key key);
    void set          (in W seed);
    void reset        (in entry_key key);
    void start        (in entry_key key);
    void stop         (in entry_key key);
  }
  */
}
// END:DirectCounter_extern

// BEGIN:MeterType_defn
enum MeterType_t {
    packets,
    bytes
}
// END:MeterType_defn

// BEGIN:MeterColor_defn
enum MeterColor_t { RED, GREEN, YELLOW };
// END:MeterColor_defn

// BEGIN:Meter_extern
extern Meter<S> {
  Meter(S n_meters, MeterType_t type);
  MeterColor_t execute(in S index, in MeterColor_t color);

  /*
  @ControlPlaneAPI
  {
    reset(in MeterColor_t color);
    setParams(in S committedRate, in S committedBurstSize
              in S peakRate, in S peakBurstSize);
    getParams(out S committedRate, out S committedBurstSize
              out S peakRate, out S peakBurstSize);
  }
  */
}
// END:Meter_extern

// BEGIN:DirectMeter_extern
extern DirectMeter {
  DirectMeter(MeterType_t type);
  MeterColor_t execute(in MeterColor_t color);

  /*
  @ControlPlaneAPI
  {
    reset(in entry_key entry, in MeterColor_t color);
    void setParams<S>(in entry_key entry,
                      in S committedRate, in S committedBurstSize
                      in S peakRate, in S peakBurstSize);
    void getParams<S>(in entry_key entry,
                      out S committedRate, out S committedBurstSize
                      out S peakRate, out S peakBurstSize);
  }
  */
}
// END:DirectMeter_extern

// BEGIN:Register_extern
extern Register<T, S> {
  Register(S size);
  T    read  (in S index);
  void write (in S index, in T value);

  /*
  @ControlPlaneAPI
  {
    T    read<T>      (in S index);
    void set          (in S index, in T seed);
    void reset        (in S index);
  }
  */
}
// END:Register_extern

// BEGIN:RandomDistribution_defn
enum RandomDistribution {
  PRNG,
  Binomial,
  Poisson
}
// END:RandomDistribution_defn

// BEGIN:Random_extern
extern Random<T> {
  Random(RandomDistribution dist, T min, T max);
  T read();

  /*
  @ControlPlaneAPI
  {
    void reset();
    void setSeed(in T seed);
  }
  */
}
// END:Random_extern

// BEGIN:ActionProfile_extern
extern ActionProfile {
  /// Construct an action profile of 'size' entries
  ActionProfile(bit<32> size);

  /*
  @ControlPlaneAPI
  {
     entry_handle add_member    (action_ref, action_data);
     void         delete_member (entry_handle);
     entry_handle modify_member (entry_handle, action_ref, action_data);
  }
  */
}
// END:ActionProfile_extern

// BEGIN:ActionSelector_extern
extern ActionSelector {
  /// Construct an action selector of 'size' entries
  /// @param algo hash algorithm to select a member in a group
  /// @param size number of entries in the action selector
  /// @param outputWidth size of the key
  ActionSelector(HashAlgorithm algo, bit<32> size, bit<32> outputWidth);

  /*
  @ControlPlaneAPI
  {
     entry_handle add_member        (action_ref, action_data);
     void         delete_member     (entry_handle);
     entry_handle modify_member     (entry_handle, action_ref, action_data);
     group_handle create_group      ();
     void         delete_group      (group_handle);
     void         add_to_group      (group_handle, entry_handle);
     void         delete_from_group (group_handle, entry_handle);
  }
  */
}
// END:ActionSelector_extern

// BEGIN:Digest_extern
extern Digest<T> {
  Digest(PortId_t receiver); /// define a digest stream to receiver
  void emit(in T data);      /// emit data into the stream

  /*
  @ControlPlaneAPI
  {
  // TBD
  // If the type T is a named struct, the name should be used
  // to generate the control-plane API.
  }
  */
}
// END:Digest_extern

// BEGIN:Programmable_blocks
parser Parser<H, M>(packet_in buffer, out H parsed_hdr, inout M user_meta,
                    in psa_parser_input_metadata_t istd);

control VerifyChecksum<H, M>(in H hdr, inout M user_meta);

control Ingress<H, M>(inout H hdr, inout M user_meta,
                      PacketReplicationEngine pre,
                      in  psa_ingress_input_metadata_t  istd,
                      out psa_ingress_output_metadata_t ostd);

control Egress<H, M>(inout H hdr, inout M user_meta,
                     BufferingQueueingEngine bqe,
                     in  psa_egress_input_metadata_t  istd);

control ComputeChecksum<H, M>(inout H hdr, inout M user_meta);

control Deparser<H>(packet_out buffer, in H hdr);

#define NUM_PIPELINES  4

#if NUM_PIPELINES == 1
package PSA_Switch<H, M>(Parser<H, M> p,
                         VerifyChecksum<H, M> vr,
                         Ingress<H, M> ig,
                         Egress<H, M> eg,
                         ComputeChecksum<H, M> ck,
                         Deparser<H> dep);

#define PSA_SWITCH_MULTIPIPE(p,v,i,e,c,d) PSA_Switch(p,v,i,e,c,d)
#endif  /* NUM_PIPELINES == 1 */

#if NUM_PIPELINES == 2
package PSA_Switch<H, M>(Parser<H, M> p0,
                         Parser<H, M> p1,
                         VerifyChecksum<H, M> vr0,
                         VerifyChecksum<H, M> vr1,
                         Ingress<H, M> ig0,
                         Ingress<H, M> ig1,
                         Egress<H, M> eg0,
                         Egress<H, M> eg1,
                         ComputeChecksum<H, M> ck0,
                         ComputeChecksum<H, M> ck1,
                         Deparser<H> dep0,
                         Deparser<H> dep1);

#define PSA_SWITCH_MULTIPIPE(p,v,i,e,c,d) \
            PSA_Switch(p,p,v,v,i,i,e,e,c,c,d,d)
#endif  /* NUM_PIPELINES == 2 */

#if NUM_PIPELINES == 3
package PSA_Switch<H, M>(Parser<H, M> p0,
                         Parser<H, M> p1,
                         Parser<H, M> p2,
                         VerifyChecksum<H, M> vr0,
                         VerifyChecksum<H, M> vr1,
                         VerifyChecksum<H, M> vr2,
                         Ingress<H, M> ig0,
                         Ingress<H, M> ig1,
                         Ingress<H, M> ig2,
                         Egress<H, M> eg0,
                         Egress<H, M> eg1,
                         Egress<H, M> eg2,
                         ComputeChecksum<H, M> ck0,
                         ComputeChecksum<H, M> ck1,
                         ComputeChecksum<H, M> ck2,
                         Deparser<H> dep0,
                         Deparser<H> dep1,
                         Deparser<H> dep2);

#define PSA_SWITCH_MULTIPIPE(p,v,i,e,c,d) \
            PSA_Switch(p,p,p,v,v,v,i,i,i,e,e,e,c,c,c,d,d,d)
#endif  /* NUM_PIPELINES == 3 */

#if NUM_PIPELINES == 4
package PSA_Switch<H, M>(Parser<H, M> p0,
                         Parser<H, M> p1,
                         Parser<H, M> p2,
                         Parser<H, M> p3,
                         VerifyChecksum<H, M> vr0,
                         VerifyChecksum<H, M> vr1,
                         VerifyChecksum<H, M> vr2,
                         VerifyChecksum<H, M> vr3,
                         Ingress<H, M> ig0,
                         Ingress<H, M> ig1,
                         Ingress<H, M> ig2,
                         Ingress<H, M> ig3,
                         Egress<H, M> eg0,
                         Egress<H, M> eg1,
                         Egress<H, M> eg2,
                         Egress<H, M> eg3,
                         ComputeChecksum<H, M> ck0,
                         ComputeChecksum<H, M> ck1,
                         ComputeChecksum<H, M> ck2,
                         ComputeChecksum<H, M> ck3,
                         Deparser<H> dep0,
                         Deparser<H> dep1,
                         Deparser<H> dep2,
                         Deparser<H> dep3);

#define PSA_SWITCH_MULTIPIPE(p,v,i,e,c,d) \
            PSA_Switch(p,p,p,p,v,v,v,v,i,i,i,i,e,e,e,e,c,c,c,c,d,d,d,d)
#endif  /* NUM_PIPELINES == 4 */
// END:Programmable_blocks

#endif  /* _PORTABLE_SWITCH_ARCHITECTURE_P4_ */
