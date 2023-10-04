# KickTree

+ [XLJL+2021] Yao Xin, Wenjun Li, Chengjun Jia, Xianfeng Li, Yang Xu,
  Bin Liu, Zhihong Tian, Weizhe Zhang, "Extended Journal Paper:
  Recursive Multi-Tree Construction with Efficient Rule Sifting for
  Packet Classification on FPGA (Under Review)", 2021,
  http://www.wenjunli.com/KickTree/

I really like this paper.  It is relatively short and to the point,
and the description of the control plane software for constructing the
data plane tables seems clearer to me than most papers describing
decision tree algorithms for the packet classification problem.

While they describe an FPGA target device as the reason for many of
their design choices, I have seen ASICs that use a similar technique
going back to 2007.  I have not done any performance analysis, but I
would guess that this technique would probably be reasonable for a
general purpose CPU implementation as well, although comparing an
optimized implementation against optimized implementations of other
algorithms would be a bit of work.

Good aspects:

+ They explicitly say that one can choose bits for decision tree node
  branch points that are _any_ bit position within _any_ field being
  classified.  I have so long seen this approach, that it frankly
  confuses me why any decision tree algorithm would ever restrict this
  choice.
+ They explicitly limit the depth and number of entries in each
  decision tree, to limit the time/work required to evaluate one
  decision tree to a fixed amount, with simple parameters for
  increasing or decreasing that amount.
+ There is _no_ duplication of rules.
+ In a hardware implementation with a "small" TCAM, it is pretty easy
  to modify this algorithm to pick a few rules to put into a true
  hardware TCAM, that would eliminate the most number of trees -- pick
  the trees with the fewest rules in them.
