# Introduction

This directory is intended to contain examples of PTF tests that run
automated tests of P4_16 programs, with simple test controller
software written in Python for adding table entries and other features
provided by the P4Runtime API, and also for sending packets and
checking that the expected packets are sent out by the software
switch.

See the [demo1 PTF README](../demo1/README-ptf.md) for a first simple
example of doing this, along with some explanation of the kind of
output that running a successful PTF test looks like.


# Exercising all supported match_kind

+ lpm, exact - see PTF test in demo1 directory
+ range, ternary, optional - see PTF test in ptf-tests/matchkinds directory
  + TBD: I wouldn't be surprised if range entries on key fields of
    type `int<W>` work as if they were cast to type `bit<W>` instead.
    True?  If so, that seems tricky to change, unless the field's most
    significant, i.e. sign, bit is negated, as well as all min/max
    values installed by the control plane.



# Things not demonstrated yet

+ idle timeout option for tables
  + verify IdleTimeoutNotification message is sent by data plane to
    controller with expected contents
+ packet in/out
+ Nothing to configure from controller for these v1model externs
  + hash
  + random
  + Checksum16
+ mirror sessions
  + configure from controller
  + verify changes in data packet processing as a result of controller changes
  + read mirror session info from switch
+ multicast group
  + configure from controller - see demo7 directory
  + verify changes in data packet processing as a result of controller changes
  + read multicast group config from switch - TBD add to demo7 PTF test
+ read counters from controller
  + indirect counter
  + direct counter
  + packets only
  + bytes only
  + packets and bytes
+ configure a meter
  + note: difficult to write precise automated tests for meters.
    Probably better to try to create a test that reports what fraction
    of the packets sent in are forwarded out.
  + indirect meter
  + direct meter
  + packets
  + bytes
+ digest
  + generate from P4 data plane, verify received as expected by controller
+ register
  + PI does not yet support reading or writing register arrays.  That
    must be implemented before such a PTF test can be successfully run.
+ action profile extern - configure and forwarding packets
+ action selector extern - configure and forwarding packets
  + 1 element in a group
  + 3-4 elements in a group
  + attempting to exceed max # of elements in a group
  + attempting to add two different action names in a single group
    (supported by p4c and simple_switch_grpc?)
  + attempting to use watch port feature - supported?
    + using watch port feature and having a watched port go down.  Not
      sure if there is even a way with simple_switch_grpc to make a
      port go down?
