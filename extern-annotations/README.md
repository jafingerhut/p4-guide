# Introduction and motivation

At the 2019-Dec-16 P4 language design work group meeting, I
volunteered to give several kinds of examples of extern methods and
extern functions, and categorize which ones I believe are appropriate
to be annotated with some new proposed P4_16 annotations, described in
this p4c pull request: https://github.com/p4lang/p4c/pull/2112

Without any kinds of restrictions on the power of extern methods and
functions, they can have _nearly_ arbitrary side effects.  The one
thing they cannot do is modify the values of variables in your P4
program, except via parameters with `out` or `inout` direction.

See Section 6.7.1 "Justification" of the P4_16 language specification:

    The main reason for using copy-in/copy-out semantics (instead of
    the more common call-by-reference semantics) is for controlling
    the side-effects of extern functions and methods.  extern methods
    and functions are the main mechanism by which a P4 program
    communicates with its environment.  With copy-in/copy-out
    semantics extern functions cannot hold references to P4 program
    objects; this enables the compiler to limit the side-effects that
    extern functions may have on the P4 program both in space (they
    can only affect out parameters) and in time (side-effects can only
    occur at function call time).

    In general, extern functions are arbitrarily powerful: they can
    store information in global storage, spawn separate threads,
    “collude” with each other to share information — but they cannot
    access any variable in a P4 program.  With copy-in/copy-out
    semantics the compiler can still reason about P4 programs that
    invoke extern functions.

The purpose of the proposed new annotations is to enable a way for the
developer of a P4_16 architecture to communicate to the front or
mid-end of a P4 compiler (like p4c) constraints that the extern
implementer promises that the P4 compiler may choose to take advantage
of in the code transformations it performs, e.g. during certain
optimization passes.

There is no known reason for using such annotations on P4_16 controls,
parsers, actions, or functions, because even with no annotations the
P4 compiler can already "see" inside of their definitions and deduce
everything it wishes to about their behavior.

The annotation names mentioned in the comments of the pull request
linked above are:

+ `@noSideEffects`
+ `@pure`

TBD: I believe that only `@noSideEffects` was added to the p4c
implementation in that pull request.

As some public examples of externs whose implementations are well
known, I refer to the files p4include/v1model.p4 and p4include/psa.p4
in the version of the Github repository https://github.com/p4lang/p4c
given in [this version
section](#versions-of-code-and-specifications-cited).

In some of the descriptions of these methods, I am referring not only
to the v1model.p4 and psa.p4 include files, which contain no details
of how the externs are implemented other than English documentation,
but to knowledge of how the externs are implemented in the version of
behavioral-model specified in [the version
section](#versions-of-code-and-specifications-cited).


# Annotations discussed in this document

I will use some fairly short annotation names within this document for
brevity.  I am not currently advocating these particular names for use
in the P4_16 language specification.

Note that extern method/functions always have read access to the
values of their `in` and `inout` parameters, and will always have the
final values of any `out` or `inout` parameters copied back into the
P4 program variables after they return.  All of them that have a
non-void return type also return a value.  Nothing in the proposed
annotations restricts that behavior in any way.

+ `@pure` - During its execution, the method/function will never read
  any state, nor modify any state.  `@pure` is more restrictive than
  `@noSideEffects`.  I do not know if this is a useful distinction
  from `@noSideEffects` as described next, or not.  That is one of the
  purposes of writing this document and having it reviewed.

+ `@noSideEffects` - During its execution, the method/function will
  never modify any state, but it is allowed to read state.

The following annotations were not part of the pull request that led
to writing this document.  I thought of them while analyzing the
existing extern methods and functions, and would ask P4 compiler
authors whether they seem useful enough to add.

+ `@localState` - When applied to an extern method, the extern method
  implementation might read and/or write internal state, but all such
  accessed state is limited to state associated directly with the
  extern object instance on which the method is called.  When applied
  to an extern function, the accessible state is restricted to state
  associated directly with this extern function.  Method and function
  calls so annotated will never read, nor write, global state of the
  architecture, nor the state of any other extern object instance or
  function.

+ `@packetState` - Similar to `@localState`, except it is even more
  restricted in the state that can be accessed.  The internal state of
  the extern object instance or extern function is partitioned by
  packets being processed in the device.  The extern method/function
  call can only access the internal state associated with the packet
  being processed by the code that made the call.  An annotation of
  `@packetState` implies an annotation of `@localState`.

+ `@localIndexedState` - Similar to `@localState`, except it is even
  more restricted in the state that can be accessed.  The internal
  state of the extern object instance or extern function is
  partitioned into an array of independently accessible sub-states,
  each with its own index or associated table entry.  The extern
  method/function call can only access the internal state associated
  with that index or table entry, and no others.  An annotation of
  `@localIndexedState` implies an annotation of `@localState`.

It makes sense to have an annotation with both `@noSideEffects` and
one of the `@localState`, `@packetState`, or `@localIndexedstate`
annotations.  The latter annotation would further restrict what state
the method/function is allowed to read.


# Summary of results

The tables in this section summarize the annotations that I believe
would be correct to add to them.  There are details of why I believe
each of these annotations are correct in later sections after the
tables.

Here we will refer to all extern object methods in file v1model.p4 by
the name `v1.<extern_name>.<method_name>`, and in the file psa.p4 by
the name `psa.<extern_name>.<method_name>`.  Including the extern name
helps distinguish methods like `v1.counter.count` and
`v1.direct_counter.count` from each other.

Similarly we will refer to all extern functions in v1model.p4 by the
name `v1.<extern_function_name>` and in psa.p4 by
`psa.<extern_function_name>`.

The first table contains only extern functions.  The second contains
only extern object methods.  They are separated in this way, because
some of the comments are specific to each.  For example, for extern
object methods, it makes sense to refer to the particular extern
object instance that the method is invoked upon, but this does not
apply for extern function calls.

The table entries are sorted by name, with strings sorted ignoring
case, and also ignoring any "v1." and "psa." prefixes.


## Extern functions

| `@pure` | `@noSideEffects` | `@packetState` | `@localState` | extern function name |
| ------- | ---------------- | -------------- | ------------- | -------------------- |
|  no |  no |  no | yes | v1.assert |
|  no |  no |  no | yes | psa.assert |
|  no |  no |  no | yes | v1.assume |
|  no |  no |  no | yes | psa.assume |
|  no |  no | yes |     | v1.clone |
|  no |  no | yes |     | v1.clone3 |
|  no |  no | yes |     | v1.digest |
| yes |     |     |     | v1.hash |
|  no |  no |  no | yes | v1.log_msg |
| yes |     |     |     | v1.mark_to_drop |
| yes |     |     |     | psa.psa_clone_e2e |
| yes |     |     |     | psa.psa_clone_i2e |
| yes |     |     |     | psa.psa_normal |
| yes |     |     |     | psa.psa_recirculate |
| yes |     |     |     | psa.psa_resubmit |
|  no |  no |  no | yes, see (Note 1) | v1.random |
|  no |  no | yes |     | v1.recirculate |
|  no |  no | yes |     | v1.resubmit |
| tbd |     |     |     | v1.truncate |
| yes |     |     |     | v1.update_checksum |
|  no | yes | yes |     | v1.update_checksum_with_payload |
|  no |  no | yes |     | v1.verify_checksum |
|  no |  no | yes |     | v1.verify_checksum_with_payload |


## Extern object methods

| `@pure` | `@noSide` `Effects` | `@packet` `State` | `@localIndexed` `State` | `@local` `State` | extern method name |
| ------- | ---------------- | -------------- | -------------------- | ------------- | ------------------ |
|  no |  no | yes |     |     | psa.Checksum.clear |
|  no | yes | yes |     |     | psa.Checksum.get |
|  no |  no | yes |     |     | psa.Checksum.update |
|  no |  no |  no | yes, see (Note 3) |     | v1.counter.count |
|  no |  no |  no | yes, see (Note 3) |     | psa.Counter.count |
|  no |  no | yes |     |     | psa.Digest.pack |
|  no |  no |  no | yes, see (Note 3) |     | psa.DirectCounter.count |
|  no |  no |  no | yes, see (Note 2), (Note 3) |     | psa.DirectMeter.execute (both signatures) |
|  no |  no |  no | yes, see (Note 3) |     | v1.direct_counter.count |
|  no |  no |  no | yes, see (Note 2), (Note 3) |     | v1.direct_meter.read |
| yes |     |     |     |     | psa.Hash.get_hash (both signatures) |
|  no |  no | yes |     |     | psa.InternetChecksum.add |
|  no |  no | yes |     |     | psa.InternetChecksum.clear |
|  no | yes | yes |     |     | psa.InternetChecksum.get |
|  no | yes | yes |     |     | psa.InternetChecksum.get_state |
|  no |  no | yes |     |     | psa.InternetChecksum.set_state |
|  no |  no | yes |     |     | psa.InternetChecksum.subtract |
|  no |  no |  no | yes, see (Note 2), (Note 3) |     | psa.Meter.execute (both signatures) |
|  no |  no |  no | yes, see (Note 2), (Note 3) |     | v1.meter.execute_meter |
|  no |  no |  no |  no | yes, see (Note 1) | psa.Random.read |
|  no | yes |  no | yes |     | v1.register.read |
|  no | yes |  no | yes |     | psa.Register.read |
|  no |  no |  no | yes |     | v1.register.write |
|  no |  no |  no | yes |     | psa.Register.write |


Extern objects with no methods:

+ psa.ActionProfile
+ psa.ActionSelector
+ v1.action_profile
+ v1.action_selector
+ psa.BufferingQueueingEngine
+ psa.PacketReplicationEngine


# v1model architecture extern objects and functions

Below is an excerpt from the cited version of the file
p4include/v1model.p4, giving the names of all extern objects and all
extern functions declared there, omitting everything else.

```
extern counter {
    counter(bit<32> size, CounterType type);
    void count(in bit<32> index);
}
extern direct_counter {
    direct_counter(CounterType type);
    void count();
}
extern meter {
    meter(bit<32> size, MeterType type);
    void execute_meter<T>(in bit<32> index, out T result);
}
extern direct_meter<T> {
    direct_meter(MeterType type);
    void read(out T result);
}
extern register<T> {
    register(bit<32> size);
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}
extern action_profile {
    action_profile(bit<32> size);
}
extern void random<T>(out T result, in T lo, in T hi);
extern void digest<T>(in bit<32> receiver, in T data);
extern void mark_to_drop(inout standard_metadata_t standard_metadata);
extern void hash<O, T, D, M>(out O result, in HashAlgorithm algo,
                             in T base, in D data, in M max);
extern action_selector {
    action_selector(HashAlgorithm algorithm, bit<32> size,
                    bit<32> outputWidth);
}
extern void
verify_checksum<T, O>(in bool condition, in T data,
                      in O checksum, HashAlgorithm algo);
extern void
update_checksum<T, O>(in bool condition, in T data,
                      inout O checksum, HashAlgorithm algo);

extern void
verify_checksum_with_payload<T, O>(in bool condition, in T data,
                                   in O checksum, HashAlgorithm algo);
extern void
update_checksum_with_payload<T, O>(in bool condition, in T data,
                                   inout O checksum, HashAlgorithm algo);
extern void resubmit<T>(in T data);
extern void recirculate<T>(in T data);
extern void clone(in CloneType type, in bit<32> session);
extern void clone3<T>(in CloneType type, in bit<32> session, in T data);
extern void truncate(in bit<32> length);
extern void assert(in bool check);
extern void assume(in bool check);
extern void log_msg(string msg);
extern void log_msg<T>(string msg, in T data);
```


## v1model extern objects and their methods

v1.counter.count `@localIndexedState` (index) - Note that due to the
  use case for such a counter, one could also mark this method with
  annotations that indicate it is asynchronous, i.e. the state
  modification to the counter could happen at some unspecified point
  in time later, after the call returns.  Thus separate calls to this
  method, on the same or different instances, could be reordered
  relative to each other by an optimizing compiler, and nothing bad
  would happen as a result.  Such a property is called `commute` in at
  least one software transactional memory system I am aware of (in the
  Clojure programming language).  See (Note 3).

v1.direct_counter.count `@localIndexedState` (table_entry) - same
  comments as for v1.counter.count.

v1.meter.execute_meter `@localIndexedState` (index) - the final value
  of the out parameter `result` is a function of in parameter `index`,
  and the extern instance's state stored at that index, and the
  current time.  Longer elapsed times between calls to the same meter
  state make it return green rather than red or yellow.  See (Note 2),
  (Note 3).

(Note 2) The annotation `@localIndexedState` is only precise for
v1.meter.execute_meter if each index has its own independent timer
state.  An implementation that is more cost effective is for all
indexed states to share a common time counter in the device, but with
that imprecision understood, this annotation is otherwise accurate.

(Note 3) All meter extern methods, and all counter count methods for
counters that update a byte count, must also read per-packet state
that is the length of the packet in bytes.  It seems that perhaps
annotations that say what kinds of state accesses are allowed,
combined with a logical "or", each adding new things that the extern
method/function can also access, would make it easier to list multiple
kinds of accesses via multiple annotations, versus an approach where
multiple annotations are combined with a logical "and", each adding
its own new restrictions to the others.

If that kind of annotations were devised, then v1.meter.execute_meter
might be annotated something like `@localIndexedStateReadWrite`
`@packetStateRead` `@devicetimeRead`, and v1.counter.count for a
counter that counts packet bytes might be
`@localIndexedStateReadWrite` `@packetStateRead`.

v1.direct_meter.read `@localIndexedState` (table_entry) - same notes
  as v1.meter.execute_meter.

v1.register.read - final value of the out parameter `result` is a
  function of the in parameter `index`, and the extern object's
  internal state at that index.  I am not sure if that should be
  considered both `@pure` and `@noSideEffects`, or only one of them,
  if there is any difference between the two.

v1.register.write `@localIndexedState` (table_entry)

v1.action_profile has no methods, and has internal state that is
presumably only read by the data plane when a packet does an apply()
call on the table with which the action_profile is associated.  The
state is only modified by the control plane.

v1.action_selector has no methods, but some variants are allowed to
have internal state, which is presumably only read and/or updated by
the data plane when a packet does an apply() call on the table with
which the action_selector is associated.  The state can also be
modified by the control plane.


## v1model extern functions

v1.random `@localState` - (Note 1) It is target-dependent whether the
  implementation of random reads state that is "private" to other
  externs, or globally in the architecture.  For example, an
  implementer could design their `random` function to read the least
  significant bits of several target-global event counters and a
  current clock time, in order to seed more entropy into the results.
  The `@localState` annotation is only correct if an implementation
  does not do this, but limits its state access to, for example, a
  collection of state dedicated for the purpose of the `random`
  function.  It might even be possible to implement in a reasonable
  manner such that the annotation `@packetState` was correct in a
  particular target, e.g. if there was per-packet hidden state in the
  architecture initialized before each packet began ingress
  processing, and it was updated like a PRNG on each call by that
  packet to the `random` function.

v1.digest `@packetState` - Similar to v1.resubmit, including that it
  is target-dependent precisely how/when it is implemented, and that
  some effects can occur outside of the time that the packet that
  caused the function call to occur.  I am using inside knowledge of
  the behavioral-model implementation for the annotation described in
  this document.

v1.mark_to_drop `@pure` - inout parameter standard_metadata's final
  value is a function only of its original in value.  Calling
  mark_to_drop() behaves the same as calling the function below.

```
function mark_to_drop(inout standard_metadata_t standard_metadata) {
    standard_metadata.egress_spec = TARGET_SPECIFIC_DROP_PORT_NUMBER;
    standard_metadata.mcast_grp = 0;
}
```

v1.hash `@pure` - The out parameter `result`'s final value is a
  function only of the in parameters.


v1.verify_checksum `@packetState` - If it took standard_metadata as an
  inout parameter, it could be annotated with `@pure`, because then
  its out parameter would be a function only of its in parameter
  values.  However, the way it currently operates in v1model is that
  it records some hidden state inside of the architecture, so that
  when the verifyChecksum control is finished executing, the
  architecture can change the value of the ingress control's
  standard_metadata.checksum_error input field to 1.  The state it
  modifies is also limited to state associated with the current
  packet.  An implementation would be allowed to also modify other
  `@localState` not associated only with this one packet, e.g. a
  counter of the total number of packets for which a checksum error
  was detected, but for this document I am assuming this does not
  happen.  Note: If v1.verify_checksum were modified so that it took
  standard_metadata as an inout parameter, it could be restricted to
  `@pure` instead.

v1.verify_checksum_with_payload `@packetState` - the same as
  verify_checksum, except that it also reads the contents of the
  packet payload, which is not an explicit parameter to the function,
  so it is reading other state besides its parameters, but specific to
  this packet (i.e. the packet's unparsed body).  Note: If
  v1.verify_checksum_with_payload were modified so that it took
  standard_metadata as an inout parameter, it could be restricted the
  same as v1.update_checksum_with_payload.

v1.update_checksum `@pure` - The inout parameter `checksum`'s final
  value is a function only of the in parameters.

v1.update_checksum_with_payload `@noSideEffects` `@packetState` - the
  same as v1.update_checksum, except that it also reads the contents
  of the packet's unparsed body, which is not an explicit parameter to
  the function, similar to v1.verify_checksum_with_payload.

v1.resubmit `@packetState` - Modifies some internal state in the
  architecture, to remember whether to resubmit the packet after it
  finishes executing the ingress control.  It is restricted to modify
  only state associated with the current packet.  Note that later,
  when the packet is actually later "enqueued" for starting ingress
  processing again, if the target implementation used a somewhat
  unusual drop policy like drop-from-front-of-queue instead of
  drop-new-packet-being-enqueued, it could later cause a different
  resubmitted packet to be dropped.  However, that is after the call
  to resubmit is complete, and occurs at a time that is outside of the
  execution of any P4 parser or control, so really has nothing to do
  with the effect restrictions the compiler must know when compiling
  calls to v1.resubmit.

v1.recirculate `@packetState` - same annotation as resubmit, with
  similar behavior.

v1.clone `@packetState` - similar to resubmit, except it also reads
  state of a clone session (which is similar to a register read, or
  table lookup via exact index), which is only accessible via the
  clone and clone3 methods, and the control plane.  It is
  target-dependent whether that clone session state is accessed
  immediately during the call to the clone method, or after the
  enclosing control (ingress or egress) has completed execution.  I
  will give annotations in this document assuming the latter, because
  that is how behavioral-model code implements the clone operation.

v1.clone3 `@packetState` - same as clone

v1.truncate - TBD I do not know what this method does well enough to
  suggest annotations.

v1.assert `@localState` - if in parameter `check` is false, this
function will typically modify some target-specific state to record
this fact.

v1.assume - same as assert

v1.log_msg (both signatures) `@localState` - similar to v1.assert


# psa architecture extern objects and functions

Below is an excerpt from the cited version of the file
p4include/psa.p4, giving the names of all extern objects and all
extern functions declared there, omitting everything else.

Note that the first several extern functions that return type `bool`
probably would have been written as normal P4_16 functions (as opposed
to extern functions), but normal functions did not yet exist in the
P4_16 language specification at the time the PSA specification was
developed.  In comments below I have added what the equivalent P4_16
function would be.  Those comments do not appear in the
p4include/psa.p4 file.

```
extern bool psa_clone_i2e(in psa_ingress_output_metadata_t istd);
// bool psa_clone_i2e(in psa_ingress_output_metadata_t istd) {
//     return istd.clone;
// }

extern bool psa_resubmit(in psa_ingress_output_metadata_t istd);
// bool psa_resubmit(in psa_ingress_output_metadata_t istd) {
//     return (!istd.drop && istd.resubmit);
// }

extern bool psa_normal(in psa_ingress_output_metadata_t istd);
// bool psa_normal(in psa_ingress_output_metadata_t istd) {
//     return (!istd.drop && !istd.resubmit);
// }

extern bool psa_clone_e2e(in psa_egress_output_metadata_t istd);
// bool psa_clone_e2e(in psa_egress_output_metadata_t istd) {
//     return istd.clone;
// }

extern bool psa_recirculate(in psa_egress_output_metadata_t istd,
                            in psa_egress_deparser_input_metadata_t edstd);
// bool psa_recirculate(in psa_egress_output_metadata_t istd,
//                      in psa_egress_deparser_input_metadata_t edstd)
// {
//     return (!istd.drop && (edstd.egress_port == PSA_PORT_RECIRCULATE));
// }
extern void assert(in bool check);
extern void assume(in bool check);
extern PacketReplicationEngine {
    PacketReplicationEngine();
}
extern BufferingQueueingEngine {
    BufferingQueueingEngine();
}
extern Hash<O> {
  Hash(PSA_HashAlgorithm_t algo);
  O get_hash<D>(in D data);
  O get_hash<T, D>(in T base, in D data, in T max);
}
extern Checksum<W> {
  Checksum(PSA_HashAlgorithm_t hash);
  void clear();
  void update<T>(in T data);
  W    get();
}
extern InternetChecksum {
  InternetChecksum();
  void clear();
  void add<T>(in T data);
  void subtract<T>(in T data);
  bit<16> get();
  bit<16> get_state();
  void set_state(in bit<16> checksum_state);
}
extern Counter<W, S> {
  Counter(bit<32> n_counters, PSA_CounterType_t type);
  void count(in S index);
}
extern DirectCounter<W> {
  DirectCounter(PSA_CounterType_t type);
  void count();
}
extern Meter<S> {
  Meter(bit<32> n_meters, PSA_MeterType_t type);
  PSA_MeterColor_t execute(in S index, in PSA_MeterColor_t color);
  PSA_MeterColor_t execute(in S index);
}
extern DirectMeter {
  DirectMeter(PSA_MeterType_t type);
  PSA_MeterColor_t execute(in PSA_MeterColor_t color);
  PSA_MeterColor_t execute();
}
extern Register<T, S> {
  Register(bit<32> size);
  Register(bit<32> size, T initial_value);
  T    read  (in S index);
  void write (in S index, in T value);
}
extern Random<T> {
  Random(T min, T max);
  T read();
}
extern ActionProfile {
  ActionProfile(bit<32> size);
}
extern ActionSelector {
  ActionSelector(PSA_HashAlgorithm_t algo, bit<32> size, bit<32> outputWidth);
}
extern Digest<T> {
  Digest();
  void pack(in T data);
}
```


## psa extern objects and their methods

psa.Hash.get_hash (both signatures) - `@pure`, similar to v1.hash

psa.Checksum.clear `@packetState` - all PSA Checksum methods are
documented to limit their effects to state that is independent per
packet.

psa.Checksum.update `@packetState`

psa.Checksum.get `@noSideEffects` `@packetState` - reads state for
this packet, but does not modify it.

psa.InternetChecksum.clear `@packetState` - all PSA InternetChecksum
methods are documented to limit their effects to state that is
independent per packet.

psa.InternetChecksum.add `@packetState`

psa.InternetChecksum.subtract `@packetState`

psa.InternetChecksum.get `@noSideEffects` `@packetState`

psa.InternetChecksum.get_state `@noSideEffects` `@packetState`

psa.InternetChecksum.set_state `@packetState`

psa.Counter.count - same effect restrictions as v1.counter.count

psa.DirectCounter.count - same effect restrictions as
v1.direct_counter.count

psa.Meter.execute (both signatures) - Same effect restrictions as
v1.meter.execute_meter, including (Note 2).

psa.DirectMeter.execute (both signatures) - same effect restrictions
as v1.direct_meter.read, including (Note 2).

psa.Register.read - same effect restrictions as v1.register.read

psa.Register.write - same effect restrictions as v1.register.write

psa.Random.read - see v1.random

ActionProfile - see v1.action_profile

ActionSelector - see v1.action_selector

psa.Digest.pack `@packetState` - similar to v1.digest


## psa extern functions

psa.psa_clone_i2e `@pure`

psa.psa_resubmit `@pure`

psa.psa_normal `@pure`

psa.psa_clone_e2e `@pure`

psa.psa_recirculate `@pure`

psa.assert - same effect restrictions as v1.assert

psa.assume - same effect restrictions as v1.assert


# Other functions

The examples below are given in the syntax of P4_16 functions.  There
is no known reason for using annotations like `@noSideEffects` or
`@pure` on P4_16 functions, actions, or controls, because the P4
compiler can "see" inside of them and deduce everything it wishes to
about their behavior.

The point of giving these function definitions is to ask the reader to
imagine an extern function that behaved in the same way internally.
For such an extern function, the P4 compiler has no way of knowing
those internals, except via the kinds of annotations discussed here,
or special case code written into the P4 compiler's implementation
regarding those extern functions.

```
void dec_v1 (inout bit<8> x) {
    x = x - 1;
}

bit<8> dec_v2 (in bit<8> x) {
    return (x - 1);
}

void dec_v3 (out bit<8> y, in bit<8> x) {
    y = x - 1;
}

bit<8> max8_v1 (in bit<8> x, in bit<8> y) {
    if (x > y) {
        return x;
    } else {
        return y;
    }
}

bit<8> max8_v2 (in bit<8> x, in bit<8> y) {
    return (x > y) ? x : y;
}
```


# Versions of code and specifications cited

```
$ git clone https://github.com/p4lang/p4c
$ cd p4c
$ git log -n 1
commit afb501c85159bb511650759eaf6aa8e259d37827 (HEAD -> master, upstream/master, origin/master, origin/HEAD)
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Sun Dec 15 13:34:26 2019 -0800

    Add Python 3 ply to install steps in README (#2115)
    
    Without this, following the existing README instructions leads to an
    installation that fails all ebpf tests run by 'cd p4c/build ; make
    check'.  With this addition, I believe all tests pass.
```

```
$ git clone https://github.com/p4lang/behavioral-model
$ cd behavioral-model
$ git log -n 1
commit 9ef324838b29419040b4f677a3ff65bc72405c44 (HEAD -> master, origin/master, origin/HEAD)
Author: Antonin Bas <abas@vmware.com>
Date:   Wed Dec 11 08:30:32 2019 -0800

    Document command-line options for simple_switch_grpc
    
    Fixes #831
```
