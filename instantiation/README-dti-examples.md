# Introduction

## Controllable entities

The words "controllable" and "entity" appear in very few places in
the P4_16 language spec:

+ Section 14.1 "Direct type invocation"
+ Section 17.3 "Control plane names"
+ Section 18.2.3 "Control-plane API annotations"

Section 17.3 says that the following entities are controllable:

+ tables
+ keys
+ actions
+ extern instances


## Direct type invocation

The P4_16 v1.2.0 language specification, section 14.1 "Direct type
invocation", says the following, where "this feature" refers to direct
type invocation.

This feature is intended to streamline the common case where a type is
instantiated exactly once.  For completeness, the behavior of directly
invoking the same type more than once is defined as follows.

+ Direct type invocation in different scopes will result in different
  local instances with different fully-qualified control names.

+ In the same scope, direct type invocation will result in a different
  local instance per invocation -- however, instances of the same type
  will share the same global name, via the @name annotation.  If the
  type contains controllable entities, then invoking it directly more
  than once in the same scope is illegal, because it will produce
  multiple controllable entities with the same fully-qualified control
  name.


## Example P4_16 programs

They are all written to use the v1model architecture, and except for
the instantiation and/or calling `apply` on various controls, tables,
and extern object instances, do nothing except parse an Ethernet
header, and send all packets out of port 1.
