# Why doesn't P4 have floating point types?

Floating point numbers, e.g. `float` and `double` types for [IEEE
754](https://en.wikipedia.org/wiki/IEEE_754) representations of
numbers in C, C++, and Java, are commonly implemented in general
purpose CPUs with specific instructions for add, subtract, multiply,
divide, etc.

The P4 language specifies types for unsigned and signed integer types,
but does not contain any type for representing floating point numbers.

Why not?

And more importantly: What can you do in P4 programs when you want to
perform operations on non-integer values?


## Why high speed switch ASICs typically do not have FPUs

It is certainly physically possible to put an FPU ([floating point
unit](https://en.wikipedia.org/wiki/Floating-point_unit)) into a
switch ASIC, so why don't designers of these devices typically do so?

The primary reason is that when it comes to the operations that one
commonly needs to do when processing packets, none of them _need_
floating point operations.  The highest speed switch ASICs, the ones
with the cheapest cost per 100 Gigabit Ethernet port (or whatever
speed ports they have), are crammed full of transistors doing all of
the most common operations required for forwarding packets, e.g.

+ Integer add, subtract, and comparison operations for calculating
  updated packet lengths when headers are added/removed, updating
  packet/byte counters, and other similar operations.
+ TCAMs for ternary header field classification
+ Often specialized longest prefix match logic for IP forwarding.  In
  some ASICs this is also TCAM, but often it is something more
  customized to longest prefix match, because the designers want a
  cheaper/lower-power way to do it than TCAM for large tables.
+ IPv4 header checksum logic.
+ Hash calculations on various subsets of header fields.
+ Often one or a few integer multipliers inside the logic that
  implements
  [meters](https://p4.org/p4-spec/docs/PSA-v1.1.0.html#sec-meters).

If some management or other control plane software finds it convenient
to use an FPU to calculate statistics and display them to a user -- no
problem.  There is typically a general purpose CPU near the switch
ASIC, or across the network in a physically separate device, that has
an FPU and runs code written in languages like C, C++, Java, Python,
etc. that provides straightforward access to the FPU's capabilities.

But if something does not need to be done on every packet, then adding
significant area of hardware logic to a switch ASIC is simply
increasing the cost per port, for no benefit.

You may be thinking -- why not add just _one_ FPU to the switch ASIC?
That is pretty small, and would not add any noticeable cost, right?

Sure, adding one FPU would not add much cost per port.  In a fixed
function switch ASIC, if you could narrow down what part of the
processing pipeline uses the FPU operation to exactly one place, then
maybe one is enough.  See below for how one can usually do integer
operations for most things involving processing packets, though.

For a programmable switch ASIC, though, where should the hardware
designer put the one FPU in the pipeline?  At the beginning?  25% of
the way through the packet processing?  75% of the way through?  At
the end?  If you pick only one place to put it, it can only be used at
that point, and any other calculations that must be done before or
after that in the packet processing are then restricted to come before
or after that point.

What about putting 10 FPUs in the pipeline, spread equally around?
Sure, you could do that, but this is not just one FPU any more, and
the area cost is noticeably higher.  Also note that unless your FPU
can also perform other functions, a user who wrote a P4 program that
used no floating point operations would cause those FPUs to sit idle
while running those programs, so the area is wasted for those
programs.

Also, if only 10 FPUs were added, your P4 program would be limited to
doing that many floating point operations per ingress processing pass,
or egress processing pass.  How many should the hardware designer add?
If you want to do 100 FPU operations per packet, those 10 are far too
few.


## How do switch ASIC designers cope without having an FPU?

The short answer is: they do operations on integer values instead.
Integer values can easily be used to represent non-integer values.
Just change the units you are working with.

For example, time stamps can be represented in many ways, but it is
straightforward to represent them using integers, if you treat the
unit not as seconds, but as nanoseconds, or microseconds, or perhaps
some number of clock periods, where the duration of a clock period can
differ between devices.

Calculating the difference between two time stamps can easily be done
using integer subtraction of two such time stamp values, and the
result will be in the same units as the time stamps.  No FPU is
required.

This is also called [fixed-point
arithmetic](https://en.wikipedia.org/wiki/Fixed-point_arithmetic).  It
is like the mantissa part of a floating point number, without the
exponent.  Or if you prefer another way to think of it, the exponent
is a constant that is understood or implied as part of the program,
not stored in any variable anywhere.


## Example of calculating EWMA of queue depths

There are many networking research papers that mention calculation of
an Exponentially Weighted Moving Average (EWMA) of some quantity, for
example the queueing latency, i.e. time that packets spent waiting in
a queue.  This is one such paper:

+ "Language-Directed Hardware Design for Network Performance
  Monitoring", Srinivas Narayana, Anirudh Sivaraman, Vikram Nathan,
  Prateesh Goyal, Venkat Arun, Mohammad Alizadeh, Vimalkumar
  Jeyakumar, Changhoon Kim, SIGCOMM 2017,
  http://web.mit.edu/marple/marple-sigcomm17.pdf

In the P4_16 v1model architecture, there is a field
[`deq_timedelta`](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md)
defined as "the time, in microseconds, that the packet spent in the
queue" that can be read during egress processing.

An exponentially weighted moving average `avg` of this quantity can be
calculated using this formula:

    avg_next = ((1-alpha) * avg_previous) + (alpha * deq_timedelta)

Where `alpha` is a constant in the range [0, 1], where the value is
selected based upon the use case you have for this EWMA quantity.  For
example, a value of alpha=0.01 would mean that new samples are
weighted as 1/99 as important as previous packets, since
(1-alpha)=0.99.

Can we implement this without an FPU?  And perhaps even with no
integer multiply operations?  Yes, it is possible.

One common trick when multiplying a variable by a constant is to
change the constant into a power of 2, if possible, because then the
multiplication becomes simply a left or right shift.  Suppose in this
case that we determined that using alpha=1/128 was a good enough
approximation of alpha=0.01.  Later below we will see what we can do
if we need a value of alpha much closer to 0.01 instead.

With a little algebra we see that:

    avg_next = ((1-(1/128)) * avg_previous) + ((1/128) * deq_timedelta)
             = avg_previous + (1/128) * (deq_timedelta - avg_previous)
             = avg_previous + ((deq_timedelta - avg_previous) >> 7)

In P4_16, since `(deq_timedelta - avg_previous)` could be positive or
negative, we should represent that value using a signed integer
`int<W>` type, so that when doing the right shift by 7, it is an
arithmetic right shift that preserves the sign bit.  If `avg_previous`
and `avg_next` are both stored as unsigned 32-bit values, we can use
this P4_16 code:

    // Example 1 code for EWMA of deq_timedelta
    
    // standard_metadata.deq_timedelta is defined as bit<32> in the
    // v1model.p4 include file

    bit<32> avg_previous;
    bit<32> avg_next;
    int<32> diff;

    // get avg_previous value, e.g. reading it from a P4 register

    diff = ((int<32>) standard_metadata.deq_timedelta) - ((int<32>) avg_previous);
    diff = diff >> 7;
    avg_next = avg_previous + (bit<32>) diff;

    // write avg_next back to P4 register, so the value is up to date
    // for when next packet from same queue is processed.

What units is avg_next value in?  The same as deq_timedelta is, which
is microseconds in the v1model architecture.  But in general, whatever
the units of deq_timedelta are, avg_next values are in those same
units.

How precise are these avg_next values?  They are a _whole integer
number_ of microseconds.  The example code above discards any
fractional microseconds that would result if you did infinite
precision arithmetic, in the calculation of the expression `diff >>
7`.  The least significant 7 bits of `diff` are discarded.

Could you calculate an average value that was precise to a fraction of
a microsecond?  Sure, if you wanted to.  The best way to do this
without requiring anything but shift, add, and subtract operations is
to pick a precision that is some power of 2 multiplier of 1
microsecond.  For example, suppose you want to keep a precision of
1/16 of a microsecond.  So, treat your avg_next values as not a whole
number of microseconds, but a whole number times 1/16 of a
microsecond.  The code would change only a little bit from the example
above, as shown in Example 2.

Note: I am sure that if I looked up the precedence rules of P4_16
arithmetic operators, I could eliminate some of the parentheses in
this code.  I personally prefer to write code with enough parentheses
such that when I read it, I can understand the order of operations
without having to remember what those precedence rules are.

    // Example 2 code for EWMA of deq_timedelta

    // standard_metadata.deq_timedelta is defined as bit<32> in the
    // v1model.p4 include file

    bit<36> avg_previous;
    bit<36> avg_next;
    int<36> diff;

    // get avg_previous value, e.g. reading it from a P4 register

    diff = (int<36>) (((bit<36>) standard_metadata.deq_timedelta) << 4) - ((int<36>) avg_previous);
    diff = diff >> 7;
    avg_next = avg_previous + (bit<36>) diff;

    // write avg_next back to P4 register, so the value is up to date
    // for when next packet from same queue is processed.

The only changes from Example 1 to Example 2 code are that the
`bit<32>` and `int<32>` types became 4 bits larger, and to convert the
value of `deq_timedelta` from units of microseconds, to units of
1/16-microseconds, we shift it left by 4, the same as multiplying by
16.  P4_16 forces us to be precise in our type conversions, so we
first widen the 32-bit unsigned `deq_timedelta` to a 36-bit unsigned
value first, then convert it to the signed `int<36>` type.


### Using a value of alpha much closer to 0.01

What if we really wanted to use alpha=0.01, because we determined that
1/128 was not good enough for our use case?

Just as we represent integer in binary as sums of powers of 2,
e.g. 100 is (64 + 32 + 4), we can write fractions as sums of negative
powers of 2, e.g. 3/4 is (1/2 + 1/4).

Just as 1/3 cannot be represented exactly as a decimal number with a
finite number of digits, but only as an infinitely repeating series of
digits 0.33333...., many fractions cannot be represented exactly in
binary, either.  1/100 is such a number that cannot be represented
exactly in binary, without an infinite repeating sequence of bits.
This is why floating point numbers are not exact, either, but only
approximations, for many numbers.

How close can we get?  Here are some successively closer
approximations.  I used the open source `bc` calculator program to
convert 1/100 into binary, to help me do this:

```
$ bc -l
bc 1.06
Copyright 1991-1994, 1997, 1998, 2000 Free Software Foundation, Inc.
This is free software with ABSOLUTELY NO WARRANTY.
For details type `warranty'. 
obase=2
1/100
.0000001010001111010111000010100011110101110000101000111101011100001
       ^ ^   ^
       | |   |
   1/128 |   |
      1/512  |
        1/8096
```

+ 1/128
  + Note: (1/128)/(1/100)=0.78125, so 1/128 is about 78.1% of 1/100
+ 1/128 + 1/512
  + This value is about 97.7% of 1/100
+ 1/128 + 1/512 + 1/8096
  + This value is about 98.9% of 1/100
+ 1/128 + 1/512 + 1/8096 + 1/16384
  + This value is about 99.5% of 1/100

Suppose we decided that the last approximation above is close enough
to 1/100, but the others were not.  How do we calculate `avg_next`
with that value of `alpha`?  Basically by doing this:

      alpha * x
    = (1/128 + 1/512 + 1/8096 + 1/16384) * x
    = (x >> 7) + (x >> 9) + (x >> 13) + (x >> 14)

We can be a bit more precise by shifting `x` left by 14 bit positions
first, so we do not discard the least significant bits multiple times
during the calculation, but only once at the end.

      ((x << 7) + (x << 5) + (x << 1) + x) >> 14

To avoid losing the most significant bits, the intermediate
calculations should be done with integers that are 14 bits larger than
the value of `x`.

Example 3 is like Example 1 code, in that we maintain `avg_next` in
the same units as `deq_timedelta`, whole microseconds, not fractions
of a microsecond.  It is straightforward to make it more like Example
2 instead, if you wish.

    // Example 3 code for EWMA of deq_timedelta

    // standard_metadata.deq_timedelta is defined as bit<32> in the
    // v1model.p4 include file

    bit<32> avg_previous;
    bit<32> avg_next;
    int<32> diff;
    int<46> x;
    int<46> x2;

    // get avg_previous value, e.g. reading it from a P4 register

    diff = ((int<32>) standard_metadata.deq_timedelta) - ((int<32>) avg_previous);
    x = ((int<46>) diff) << 14;

    // x has been shifted left by 14 bits, so we use the right-shift
    // version of the formula above.  The least significant 14 bits of
    // x2 are a fraction of microseconds.
    x2 = (x >> 7) + (x >> 9) + (x >> 13) + (x >> 14);

    // The next expression discards the fractional part of x2
    avg_next = avg_previous + (bit<32>) ((int<32>) (x2 >> 14));

    // write avg_next back to P4 register, so the value is up to date
    // for when next packet from same queue is processed.

The book "Hacker's Delight" is a treasure trove of tips and tricks
that were devised by people earlier in the rise of computers (I
believe roughly the 1950s through 1960s), and known by a much larger
fraction of computer programmers at a time when FPUs did not yet
exist, and even integer multiply and divide instructions could take
significantly longer than integer add, subtract, and shift
instructions.  It can be a valuable resource for P4 programmers in
2020, who are targeting high speed switch ASICs.

+ Henry S. Warren, "Hacker's Delight, 2nd edition", Addison-Wesley,
  2012, ISBN 978-0321842688,
  https://en.wikipedia.org/wiki/Hacker%27s_Delight

Perhaps some day high speed switch ASICs will have big integer
multiply and divide operations, and/or FPUs, but until then ...


## Multiplying two integers

Some P4 implementations may enable you to multiply two integer
variables, but if they do not, and you really want to, there are at
least a couple of ways to go about it.

The one described in this section is basically multiplication of two
multi-digit numbers like many people learn in grade school, in
decimal, except in binary.  I was surprised to see that Khan Academy
has a [video demonstrating multiplication in
binary](https://www.khanacademy.org/math/algebra-home/alg-intro-to-algebra/algebra-alternate-number-bases/v/binary-multiplication).

I will restrict this example to multiplying two 8-bit unsigned
integers, with a 16-bit result, but the idea is pretty easy to
generalize to multiplying an A-bit unsigned integer with a B-bit
unsigned integer to produce an (A+B)-bit result.

    bit<8> a;
    bit<8> b;
    bit<16> product;

    bit<16> tmp0 = (b[0:0] == 1) ? (((bit<16>) a) << 0) : 0;
    bit<16> tmp1 = (b[1:1] == 1) ? (((bit<16>) a) << 1) : 0;
    bit<16> tmp2 = (b[2:2] == 1) ? (((bit<16>) a) << 2) : 0;
    bit<16> tmp3 = (b[3:3] == 1) ? (((bit<16>) a) << 3) : 0;
    bit<16> tmp4 = (b[4:4] == 1) ? (((bit<16>) a) << 4) : 0;
    bit<16> tmp5 = (b[5:5] == 1) ? (((bit<16>) a) << 5) : 0;
    bit<16> tmp6 = (b[6:6] == 1) ? (((bit<16>) a) << 6) : 0;
    bit<16> tmp7 = (b[7:7] == 1) ? (((bit<16>) a) << 7) : 0;
    product = tmp0 + tmp1 + tmp2 + tmp3 + tmp4 + tmp5 + tmp6 + tmp7;

This kind of code can get quite repetitive.  See the [P4 code
generation article](../code-generation/README.md) for tips on how to
avoid drudgery when creating repetitive code.


## Other functions

What about other kinds of functions: sines, cosines, logarithms, etc.?

Take a look at [this page from a book published in the year
1619](https://en.wikipedia.org/wiki/Mathematical_table#/media/File:Bernegger_Manuale_136.jpg),
and see if you can guess one way to do this in P4.

That is right.  Use a table!

Now for most high speed devices you will not want to attempt to create
a table with as many entries as a book has, but there is a lot of room
here for trading off the size of the table, with the accuracy of the
results you get.

For example, suppose you want to calculate the base 10 logarithm of
some number in the range 1.0 to 10.0.

First, pick a precision and representation as an integer for the input
value, e.g. it will be a 10-bit integer, where the integer 1000 will
represent 10.0, 200 will represent 2.0, and in general the integer N
will represent the value (N/100).

Next, pick a precision and representation as an integer for the output
value, e.g. it will be an 8-bit integer, where the value M will
represent the value (M/100).  We only need to represent values in the
range [0.0, 1.0], and 8 bits is enough to represent all multiples of
0.01 in that range.

Now create a P4 table with a 10-bit exact match key, with only one
action, that assigns the value of an 8-bit action parameter to some
variable where you want to store the result.

    bit<10> input_val;
    bit<8> output_val;

    action set_result (bit<8> result) { output_val = result; }
    table log_base_10 {
        key = { input_val : exact; }
        actions = { set_result; }
        const entries = {
             100 : set_result(0);
            // ... 899 entries omitted here ...
            1000 : set_result(100);
        }
    }

This code can be even more repetitive than that from the previous
section.  See the [P4 code generation
article](../code-generation/README.md) for tips on how to avoid
drudgery when creating repetitive code.

For many functions that are "smooth", i.e. can be closely approximated
by a few points connected by straight lines, you can significantly
reduce the size of the table by using [linear
interpolation](https://en.wikipedia.org/wiki/Linear_interpolation#Linear_interpolation_as_approximation).
Instead of each entry having only one action parameter, it could have
a `base_value`, `slope`.  After doing a table lookup on the
`input_val`, you then use the technique of the previous section to
calculate `output_val = base_value + (slope * input_val)`.  If you
used a ternary or range match instead of exact, you may even be able
to combine what would be many consecutive exact match entries into one
ternary or range entry, all sharing the same `base_value` and `slope`.

You can use this to implement functions with multiple inputs, too, by
having them as separate fields of the table lookup key, and multiple
outputs, if that is useful.  The multiplication in the previous
section could also be implemented with a table having 2^(8+8) = 64K
entries, each with a 16-bit result.



# References

+ Henry S. Warren, "Hacker's Delight, 2nd edition", Addison-Wesley,
  2012, ISBN 978-0321842688,
  https://en.wikipedia.org/wiki/Hacker%27s_Delight

Some of these techniques (and perhaps more) are also described in this
2017 research paper:

+ "Evaluating the Power of Flexible Packet Processing for Network
  Resource Allocation", Naveen Kr. Sharma, Antoine Kaufmann, Thomas
  Anderson, Changhoon Kim, Arvind Krishnamurthy, Jacob Nelson, Simon
  Peter, Proc. of the 14th USENIX Symposium on Networked Systems
  Design and Implementation (NSDI '17), March 2017,
  https://www.usenix.org/system/files/conference/nsdi17/nsdi17-sharma.pdf
