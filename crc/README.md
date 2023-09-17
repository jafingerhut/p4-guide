# Introduction

A few notes on CRC calculation.  See also the References section near
the end.


## An interesting property about some CRC functions when used as hash functions for a hash table

The main reason I added this directory is to point out a potentially
interesting property that some CRC polynomials have when used as a
hash function for hash tables.

I believe that _perhaps_ the interesting property about "prime" CRC
polynomials (TODO: is that correct terminology?) is the following:

Let P be a CRC polynomial with degree D, i.e. when given a data input,
the CRC calculation produces a result with D bits.

For any integer K > D, and any two K-bit strings S1 and S2, if CRC(S1,
P) = CRC(S2, P) and S1 != S2, then S1[K-1:D] != S2[K-1:D], where the
last expression uses the P4_16 syntax for bit slices.

That is, if two different K-bit strings have the same CRC, then they
must differ in their most significant (K-D) bits.

This means that if this CRC is used as a hash function in a hash table
with 2^D buckets, where CRC(S1,P) is used as the hash function, we
only need to store the most significant (K-D) bits of the string for a
final "exact match" check.  If the most significant stored (K-D) bits
match the search key, it is guaranteed that the search key is equal to
the original value.

I believe it is also true that if the keys S are less than D bits in
size, then CRC(S, P) is equal to S, and thus there can be no
collisions for small keys in a hash table with 2^D entries using
CRC(K,P) as the bucket address.  Thus no key needs to be stored at
all.



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

+ `a = 0x327 =  11 0010 0111` same as next line, but without explicit +1 bit at end
+ `b = 0x64f = 110 0100 1111`
  + polynomial x^10 + x^9 + x^7 + x^3 + x^2 + x^1 + 1
+ `c = 0x3c9 =  11 1100 1001` same as next line, but without explicit +1 bit at end
+ `d = 0x793 = 111 1001 0011` same as `b` except bits in reverse order
  + polynomial x^10 + x^9 + x^8 + x^7 + x^4 + x^1 + 1

Note that `b == ((a << 1) + 1)` and `d == ((c << 1) + 1)`.
