# How much does data storage cost?

It depends quite a bit on several factors:

+ What is the throughput for reading and writing data?
+ What is the latency of accessing it?
+ For random access technology (i.e. not tape drives), what is the
  rate at which one can choose new addresses to access?

[Here][http://www.thessdreview.com/featured/ssd-throughput-latency-iopsexplained/]
is one article from 2014 explaining the significant differences in
these parameters between mechanical hard drives and SSDs (solid state
drives).

In this article I want to focus on the differences between cost and
performance parameters of DRAM connected to a CPU (whether server,
desktop, or laptop), vs. SRAM storage that is used to implement the
levels of caching that are closest to a CPU core in processors such as
those made by Intel and AMD.  It is very common for software
developers to be familiar with the costs of disk space and DRAM per
gigabyte, at least roughly, because those are things so commonly used
in tradeoff decisions of how software should be developed or tuned for
performance.

I think it is less common for such developers to know the cost of
on-CPU cache memory, because while they definitely benefit from it due
ot the performance increase it enables while running their programs,
its size is not something you can easily add more of in a system.  A
certain amount of it typically comes with the CPUs you buy, and unlike
choosing systems with more or less DRAM installed, or more or less SSD
or mechanical disk storage attached, there are much more limited
ranges of options for choosing more or less on-chip cache memory.

Why do I want to call attention to this?  Because networking ASICs
that can process billions of packets per second need to access
multiple tables for every one of these packets, often ranging from 20
to 100 tables.  These tables help the networking ASIC perform tasks
such as looking up an Ethernet MAC address to determine where to
forward the packet, or doing a longest-prefix match on an IPv4 or IPv6
destination address to determine where to send the packet, to dozens
of other purposes.  The aggregate rate of all of these table accesses
turns into tens to hundreds of billions of random accesses to SRAMs
and TCAMs in a single ASIC.  It is often impractically expensive to
attempt to put the contents of such tables in DRAM devices connected
to such an ASIC, because their random access rates are only enough for
one or a handful of these tables (if even one is feasible), and their
access latencies are significantly higher than an on-chip SRAM.  Any
latency of such access becomes additional latency when forwarding
packets, and a lack of random access rate turns into lower packet
rates.

First let us look at some retail costs of DRAM devices during late
2018.  I do not have access to wholesale prices right now, but I will
also be comparing these prices against retail prices of CPU cache
memory, so at least that aspect will be apples to apples.

Lowest prices on [newegg.com](https://www.newegg.com), 2018-Nov-15,
under category "Server Memory" and "Desktop Memory" for DDR4 DRAM
parts with a few different storage capacities:

| # of Gbytes in a DDR4 DRAM part | Lowest $ cost per part for Server Memory | Server $ per GByte | Lowest $ cost per part for Desktop Memory | Desktop $ per Gbyte |
| ----- | ------- | ----------- | ---- | ---- |
|  8 GB |  $57.79 |  $7.22 / GB | same | same |
| 16 GB | $109.99 |  $6.87 / GB | same | same |
| 32 GB | $268.88 |  $8.40 / GB | $341.37 | $10.67 / GB |
| 64 GB | $639.99 | $10.00 / GB | None for sale | N/A |

Here are some other recent prices for other DRAM-based memory devices
with higher bandwidth than DDR4:

| $ per Gbyte | Type of device | Note | Source |
| ----------- | -------------- | ---- | ------ |
|  $8.50 / GB |    GDDR5       |  | https://www.gamersnexus.net/guides/3032-vega-56-cost-of-hbm2-and-necessity-to-use-it |
| $21.88 / GB |    HBM2        | I think the $175 cost in the source article is for 8 GByte of HBM2, but not certain. | https://www.gamersnexus.net/guides/3032-vega-56-cost-of-hbm2-and-necessity-to-use-it |

Now let us switch to examining the cost of memory per Gbyte (so we
have the same units as above, at least) for on-chip CPU cache memory.
Yes, none of them have more than a fraction of a Gbyte of cache
memory, so the numbers are definitely higher.

Before you dismiss me here, I know very well that CPUs have lots of
their silicon area devoted to other things besides cache memory.  For
example, CPU cores, memory controllers, high speed Serdes interfaces,
etc.

Here is why, if you are interested in high speed switch ASICs, that
you should not be too quick to dismiss the numbers below: switch ASICs
_also_ have lots of their silicon area devoted to other things besides
table memory.  For example:

+ Logic for looking up the tables and processing their results,
  modifying the contents of packets as they flow through the device.
+ High speed Serdes connected to hardware blocks for receiving and
  transmitting data as Ethernet frames (sometimes called MAC logic).
+ A packet buffer for storing the contents of packets during times
  when packets are destined for a port faster than the port can
  transmit them, i.e. due to short term link congestion.

Here is an image of an Intel Core i7 CPU with major subsystems such as
CPU cores, memory controller, I/O, and Shared L3 Cache labeled,
showing the relative sizes of each:

https://techreport.com/review/15818/intel-core-i7-processors

I may be able to find a similar image of a modern switch ASIC, labeled
with major functional pieces, but I was not able to find a public one
in about 15 minutes of searching, so sorry, no such image yet.  If you
are willing to trust me for a moment on this, the fraction of such a
chip's die area taken up by lookup tables is often not far away from
the fraction of die area taken up by the Intel Core i7 CPU for L3
cache.

Thus, my conclusion is, if the cost per Gbyte of on-chip caches is
high for CPU chips, then it stands to reason that the cost per Gbyte
of on-chip table memory in high speed switch ASICs is similarly high.
Maybe not identical, but not far off, either.

If you are still with me, let us look at some of the costs I found. On
2018-Oct-30 I went to [newegg.com](https://newegg.com) and looked for
Intel and AMD processors, and filtered the list of those available by
their L3 cache size.  For each different cache size, I sorted the
processors by price, from lowest to highest, and found the cheapest
one.

In all cases, the dollars per GB number was calculated as:

```
    (cost in $) / ((total cache size in MB) / (1024 MB / 1 GB))
    = 1024 * (cost in $) / (total cache size in MB)
```

As for DRAM prices above, these are retail prices for individual parts
in US dollars.  I know that buying them in large volumes you can get
discounts, but I do not know how much that might be.

| L3 cache size (MBytes) | Lowest $ cost among processors with that L3 cache size | Total L2 cache | Total L1 cache | Total size of L3 + L2 + L1 caches | $ per Gbyte of cache size (total L1+L2+L3) | Processor name / model | Source (as of 2018-Oct-30) |
| -------| ----- | -------- | ------ | --------- | ------------ | -- | -- |
|   4 MB |  $100 |     2 MB | 384 KB |  6.375 MB | $16,063 / GB | AMD Ryzen 3 2200G Model YD2200C5FBBOX | https://www.newegg.com/Product/Product.aspx?Item=N82E16819113481&cm_re=amd-_-19-113-481-_-Product |

|   8 MB |   $60 | 3 x 2 MB |   ?    | 14 MB     |  $4,389 / GB | AMD FX-6300 Vishera 6-Core 3.5 GHz Socket AM3+ 95W FD6300WMHKBOX Desktop Processor | https://www.newegg.com/Product/Product.aspx?Item=N82E16819113286 |
|  16 MB |  $140 |     2 MB | 384 KB | 18.375 MB |  $7,802 / GB | AMD Ryzen 5 1500X Model YD150XBBAEBOX | https://www.newegg.com/Product/Product.aspx?Item=N82E16819113436 |
|  32 MB |  $420 |     6 MB | 1.125 MB | 39.125 MB | $10,992 / GB | AMD Ryzen Threadripper 1920X YD192XA8AEWOF | https://www.newegg.com/Product/Product.aspx?Item=N82E16819113448 |
|  64 MB | $1300 |    12 MB | 2.25 MB | 78.25 MB | $17,012 / GB | Ryzen Threadripper 2970WX YD297XAZAFWOF | https://www.newegg.com/Product/Product.aspx?Item=N82E16819113546 |
|  64 MB | $1750 |    16 MB | 3 MB   | 83 MB     | $21,590 / GB | AMD 2nd Gen RYZEN Threadripper 2990WX 32-Core, 64-Thread, 4.2 GHz Max Boost (3.0 GHz Base), Socket sTR4 250W YD299XAZAFWOF Desktop Processor | https://www.newegg.com/Product/Product.aspx?Item=N82E16819113541&cm_re=YD299XAZAFWOF-_-19-113-541-_-Product |

What could possibly explain these astronomical prices per Gbyte?

There are at least several factors in play here:

+ The profit margin of selling CPUs is likely significantly higher
  than for selling DRAM.  I would not be surprised if competition
  among DRAM manufacturers makes their profit margins somewhere around
  5%, whereas CPU manufacturers are able to achieve significantly
  higher profit margins.  Probably nowhere near as high as 90%,
  though.  Maybe closer to 30% to 50%?

+ In CPU chips, only a fraction of the die area is taken up by cache
  memory, whereas for DRAM parts most of the die area is taken up by
  memory storage.  I suspect this could account for a factor of around
  5 to 10.

+ The cost to produce chips grows faster than linearly as the chips
  get larger, and these CPU chips are significantly larger than the
  DRAM devices.  This is due to larger silicon dies having a larger
  fraction of them with at least one defect on them, causing them in
  some cases to be discarded, unless part of the chip can be disabled
  and the device sold as a cheaper smaller part (e.g. as a 4-core CPU
  instead of an 8-core CPU, because some cores are non-functional).
  be discarded.  DRAM parts probably have 90% or higher "yields", due
  to techniques to "route around" bad bits of memory to spare blocks
  of memory, because the structure of the logic is so regular and
  repeating.  CPUs have some of this, too, but it is not so easy to do
  for the CPU cores inside the device as it is for large regular
  memory structures.

+ The on chip caches are simply more die area per bit of storage than
  DRAM hardware is.  They have lower latency requirements, and higher
  random access rates and bandwidths.

You may reasonably ask: Why no Intel processors on this list?  The
answer seems to be: they are not the cheapest CPUs available per bit
of on-chip cache memory.  Intel CPUs are all more expensive by that
measurement than the CPUs above.  This could be because Intel is able
to sell their CPUs with a higher profit margin than AMD does, or
Intel's CPUs have a smaller fraction of their die area consumed by
cache memory, or some combination of those factors.
