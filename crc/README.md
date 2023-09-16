# Introduction

A few notes on CRC calculation.

The main reason I added this directory is to point out a potentially
interesting property that some CRC polynomials have when used as a
hash function for hash tables.



## References

+ https://en.wikipedia.org/wiki/Cyclic_redundancy_check
+ "Best CRC Polynomials", https://users.ece.cmu.edu/~koopman/crc


## Notes on interpreting the CRC polynomials from "Best CRC Polynomials" site

Here is a list of CRC-10 polynomials with good error detection
properties from this page:

+ https://users.ece.cmu.edu/~koopman/crc/crc10.html


+ (0x327; 0x64f) <=> (0x3c9; 0x793) {1013,73,10,5,1} | gold | (*p) CRC-10F/3 ("3117")
+ (0x2fd; 0x5fb) <=> (0x37e; 0x6fd) {1013,16,16,5,1,1,1} | gold | (*p) CRC-10F/8.1 ("2773p")
+ (0x2c7; 0x58f) <=> (0x3c6; 0x78d) {1013,7,7,6,1} | gold | (*p) CRC-10F/6.1 ("2617p"
+ (0x204; 0x409) <=> (0x240; 0x481) {1013} | gold | (*p) FP-10
+ (0x247; 0x48f) <=> (0x3c4; 0x789) {501,501,10,10} | gold | (*op) CRC-10F/4.2 ("2217"")
+ (0x2de; 0x5bd) <=> (0x2f6; 0x5ed) {501,501,5,5,2,2} | gold | (*op) CRC-10F/8.2 ("2675")
+ (0x3ec; 0x7d9) <=> (0x26f; 0x4df) {501,501,4,4,1,1} | gold | (*op) CRC-10-CMDA2000
+ (0x206; 0x40d) <=> (0x2c0; 0x581) {501,501} | gold | (*op) FOP-11
+ (0x319; 0x633) <=> (0x331; 0x663) {501,501,3,3} | gold | (*op) CRC-10
+ (0x3df; 0x7bf) <=> (0x3f7; 0x7ef) {501,501,1,1,1,1,1,1} | gold | (*op) CRC-10F/10 ("3677")
+ (0x25d; 0x4bb) <=> (0x374; 0x6e9) {305,305,5,3,3} | gold | CRC-10F/4.1 ("2273")
+ (0x28e; 0x51d) <=> (0x2e2; 0x5c5) {95,95,12,12} | gold | (*o) CRC-10F/6.2; CRC-10/6sub8("2435")
+ (0x221; 0x443) <=> (0x308; 0x611) {95,95} | gold | (*o) CRC-10/P
+ (0x2ba; 0x575) <=> (0x2ba; 0x575) {25,25,2,2,2} | gold | CRC-10-GSM
+ (0x2b9; 0x573) <=> (0x33a; 0x675) {21,21,21,3,3} | gold | CRC-10F/5 ("2563")
+ (0x29b; 0x537) <=> (0x3b2; 0x765) {5,5,5,5,5} | gold | CRC-10F/7 ("2467")


The 4 hex values for each of the polynomials above I believe all
represent only 2 different polynomials.

The first 2 values are two different ways to represent the same
polynomial as an integer, and the second 2 values are two different
ways to represent a "reversed polynomial" as an integer.

Example:

+ (0x327; 0x64f) <=> (0x3c9; 0x793) {1013,73,10,5,1} | gold | (*p) CRC-10F/3 ("3117")

+ `0x327   11 0010 0111`   same as next line, but without explicit +1 bit at end
+ `0x64f  110 0100 1111`
+ `0x3c9   11 1100 1001`   same as next line, but without explicit +1 bit at end
+ `0x793  111 1001 0011`   same as second line except bits in reverse order
