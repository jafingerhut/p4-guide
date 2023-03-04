A person with the Slack name Jack on the P4 Slack channel asked if
there was a way to change the default queue rate, the one set via the
`simple_switch_CLI` command `set_queue_rate`, in the `simple_switch`
source code, so that Jack's desired `set_queue_rate` value was the
default value when starting the `simple_switch` process.

Here are some steps I went through to try to figure out how that might
be done.

```bash
$ git clone https://github.com/p4lang/behavioral-model
$ cd behavioral-model
$ git log -n 1 | head -n 4
commit 70355b57f43805c98dce52e183a58c680f790672
Author: Radostin Stoyanov <rstoyanov@fedoraproject.org>
Date:   Fri Feb 17 23:09:46 2023 +0000

```

All of the search results below through the behavioral-model repo
files are what I saw with the specific version of the behavioral-model
repo files shown above in the output of the `git log` command.

Look for occurrences of the command name `set_queue_rate`:

```bash
$ grep -r set_queue_rate
./targets/simple_switch/sswitch_CLI.py:    def do_set_queue_rate(self, line):
./targets/simple_switch/sswitch_CLI.py:        "Set rate of one / all egress queue(s): set_queue_rate <rate_pps> [<egress_port> [<priority>]]"
./targets/psa_switch/pswitch_CLI.py:    def do_set_queue_rate(self, line):
./targets/psa_switch/pswitch_CLI.py:        "Set rate of one / all egress queue(s): set_queue_rate <rate_pps> [<egress_port>]"
./docs/simple_switch.md:`set_queue_rate` command (among others).
./docs/runtime_CLI.md:TODO: set_queue_rate [simple_switch_CLI only]
```

It only occurs in documentation and Python source files.  Open
sswitch_CLI.py in my editor and search for it, and I find a Python
method named 'do_set_queue_rate'.  Depending upon some conditions, it
makes one of these calls:

```python
            self.sswitch_client.set_egress_priority_queue_rate(port, priority, rate)
        elif len(args) == 2:
            port = self.parse_int(args[1], "egress_port")
            self.sswitch_client.set_egress_queue_rate(port, rate)
        else:
            self.sswitch_client.set_all_egress_queue_rates(rate)
```

Search for `set_egress_priority_queue_rate` in all behavioral-model
repo files:

```bash
$ grep -r set_egress_priority_queue_rate
./targets/simple_switch/sswitch_CLI.py:            self.sswitch_client.set_egress_priority_queue_rate(port, priority, rate)
./targets/simple_switch/simple_switch.h:  int set_egress_priority_queue_rate(size_t port, size_t priority,
./targets/simple_switch/thrift/simple_switch.thrift:  i32 set_egress_priority_queue_rate(1:i32 port_num, 2:i32 priority, 3:i64 rate_pps);
./targets/simple_switch/thrift/src/SimpleSwitch_server.cpp:  int32_t set_egress_priority_queue_rate(const int32_t port_num,
./targets/simple_switch/thrift/src/SimpleSwitch_server.cpp:    bm::Logger::get()->trace("set_egress_priority_queue_rate");
./targets/simple_switch/thrift/src/SimpleSwitch_server.cpp:    return switch_->set_egress_priority_queue_rate(
./targets/simple_switch/simple_switch.cpp:SimpleSwitch::set_egress_priority_queue_rate(size_t port, size_t priority,
```

The definition appears most likely to be in one of the two `.cpp` C++
source files.  Examine them in my editor.

In file `SimpleSwitch_server.cpp`, the method simply calls another
method with the same name on an instance of an object in a variable
called `switch_`, so hopefully the occurrence in file
`simple_switch.cpp` will be more useful.

The same is true for these method names that appear in file
`SimpleSwitch_server.cpp`:

+ set_egress_queue_rate
+ set_all_egress_queue_rates

In file `simple_switch.cpp`:

+ method `set_egress_priority_queue_rate` calls a method
  `egress_buffers.set_rate`.
+ method `set_egress_queue_rate` also calls a method with the same
  name, but with 2 parameters instead of 3, likely an overloaded
  method definition by number of parameters.
+ method `set_all_egress_queue_rates` calls method
  `egress_buffers.set_rate_for_all`.

Searching in all behavioral-model repo files for `egress_buffers`
finds that it is a field inside of class `SimpleSwitch`, defined in
file `simple_switch.h`, with this definition:

```C++
  bm::QueueingLogicPriRL<std::unique_ptr<Packet>, EgressThreadMapper>
  egress_buffers;
```

Search for `set_rate` and `set_rate_for_all` everywhere in the
behavioral-model repo.  Doing a search for `set_rate` without
restricting it to a whole word match finds lots of matches.  Using
`egrep` with `\bset_rate\b` as the pattern restricts it to a whole
word match, which finds far fewer matches that are likely more useful
to us.

```bash
$ egrep -r '\bset_rate\b'
./targets/simple_switch/simple_switch.cpp:  egress_buffers.set_rate(port, priority, rate_pps);
./targets/simple_switch/simple_switch.cpp:  egress_buffers.set_rate(port, rate_pps);
./targets/psa_switch/psa_switch.cpp:  egress_buffers.set_rate(port, rate_pps);
./include/bm/bm_sim/meters.h:      MeterErrorCode rc = set_rate(idx++, *it);
./include/bm/bm_sim/meters.h:  MeterErrorCode set_rate(size_t idx, const rate_config_t &config);
./include/bm/bm_sim/queueing.h:  void set_rate(size_t queue_id, uint64_t pps) {
./include/bm/bm_sim/queueing.h:  void set_rate(size_t queue_id, uint64_t pps) {
./include/bm/bm_sim/queueing.h:  //! Same as set_rate(size_t queue_id, uint64_t pps) but only applies to the
./include/bm/bm_sim/queueing.h:  void set_rate(size_t queue_id, size_t priority, uint64_t pps) {
./tests/test_queueing.cpp:    queue.set_rate(0u, pps);
./tests/test_queueing.cpp:  queue.set_rate(0u, rate_pps);
./src/bm_sim/meters.cpp:Meter::set_rate(size_t idx, const rate_config_t &config) {
./src/bm_sim/meters.cpp:      set_rate(i, config);


$ egrep -r '\bset_rate_for_all\b'
./targets/simple_switch/simple_switch.cpp:  egress_buffers.set_rate_for_all(rate_pps);
./targets/psa_switch/psa_switch.cpp:  egress_buffers.set_rate_for_all(rate_pps);
./include/bm/bm_sim/queueing.h:  void set_rate_for_all(uint64_t pps) {
./include/bm/bm_sim/queueing.h:  void set_rate_for_all(uint64_t pps) {
```

From the search results above, it appears that file `queueing.h` is
likely to be where the methods `set_rate` and `set_rate_for_all` are
defined.  Examine that file in your editor.

Note that there are two classes with methods named `set_rate` in file
`queueing.h`:

+ one class named `QueueingLogicRL`
+ another class named `QueueingLogicPriRL`

Searching all of behavioral-model files for occurrences of those class
names, it appears that only class `QueueingLogicPriRL` is used by
simple_switch, whereas the separate process psa_switch mentions both
classes.  We are not using psa_switch here, which is a a separate
process you can build from the behavioral-model code that is
incomplete in its implementation.  So focusing on simple_switch, only
the class `QueueingLogicPriRL` is of interest to us.

The methods `set_rate` and `set_rate_for_all` of class
`QueueingLogicPriRL` are copied and pasted below:

```C++
  //! Set the maximum rate of all the priority queues for logical queue \p
  //! queue_id to \p pps. \p pps is expressed in "number of elements per
  //! second". Until this function is called, there will be no rate limit for
  //! the queue. The same behavior (no rate limit) can be achieved by calling
  //! this method with a rate of 0.
  void set_rate(size_t queue_id, uint64_t pps) {
    LockType lock(mutex);
    for_each_q(queue_id, SetRateFn(pps));
  }

  //! Same as set_rate(size_t queue_id, uint64_t pps) but only applies to the
  //! given priority queue.
  void set_rate(size_t queue_id, size_t priority, uint64_t pps) {
    LockType lock(mutex);
    for_one_q(queue_id, priority, SetRateFn(pps));
  }

  //! Set the rate of all the priority queues of all logical queues to \p pps.
  void set_rate_for_all(uint64_t pps) {
    LockType lock(mutex);
    for (auto &p : queues_info) for_each_q(p.first, SetRateFn(pps));
    queue_rate_pps = pps;
  }
```

Note the comment above the first method, that says that the default
initial setting is "no rate limit for the queue", which you can also
configure later at run time by explicitly setting the rate to 0.  I
will assume for now that this comment is up to date with the code.

Searching for `SetRateFn` in that same file, it is a `struct` defined
locally within the class, which has one method that assigns a value to
two fields called `pps` and `pkt_delay_ticks`.

Looking around for all occurrences of `pps` in this class, I noticed a
field called `queue_rate_pps` which appears to be the default initial
value of the value `pps`.  Note that near the end of the definition of
class `QueueingLogicPriRL` is this line defining the field
`queue_rate_pps`:

```C++
  uint64_t queue_rate_pps{0};  // default rate
```

It appears that if one were to change that value `0` to another value
and recompile, that would become the default initial value of the
queue rate.
