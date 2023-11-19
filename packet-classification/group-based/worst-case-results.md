# Worst-case performance results for normal packet classification algorithms

I may think later of a better way to organize these results, but for
now I want to record any performance guarantees that have been proven
for algorithms for the normal packet classification problem.

Symbols used:

+ n is the number of rules in a rule set
+ d is the number of fields being classified on


# RAM model

These algorithms are for a single processor RAM model, i.e. it would
be straightforward to implement them on a general purpose CPU using 1
CPU core.

In some cases, it might be possible to achieve a speedup on the
classification time by using multiple CPU cores in parallel.  This
will be noted when it is known, but if it is _not_ mentioned, that
does not imply that it is impossible to parallelize -- simply that it
has not been considered by me for that algorithm.

Edelsbrunner 1984
