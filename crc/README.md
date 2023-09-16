# Introduction

A few notes on CRC calculation.

The main reason I added this directory is to point out a potentially
interesting property that some CRC polynomials have when used as a
hash function for hash tables.



## References

+ https://en.wikipedia.org/wiki/Cyclic_redundancy_check
+ "Best CRC Polynomials", https://users.ece.cmu.edu/~koopman/crc


## Notes on interpreting the CRC polynomials from "Best CRC Polynomials" site

This page has a list of CRC-10 polynomials with good error detection
properties:

+ https://users.ece.cmu.edu/~koopman/crc/crc10.html

Here is the first example CRC-10 polynomial on that page:

```
(0x327; 0x64f) <=> (0x3c9; 0x793) {1013,73,10,5,1} | gold | (*p) CRC-10F/3 ("3117")
```

I believe that on that linked page, all CRC polynomials are
represented using 4 hex values.  Each group of 4 hex values represent
2 different polynomials.  The first 2 values are two different ways to
represent the same polynomial as an integer, and the second 2 values
are two different ways to represent a "reversed polynomial" as an
integer.

Example:

+ `0x327   11 0010 0111`   same as next line, but without explicit +1 bit at end
+ `0x64f  110 0100 1111`
+ `0x3c9   11 1100 1001`   same as next line, but without explicit +1 bit at end
+ `0x793  111 1001 0011`   same as second line except bits in reverse order
