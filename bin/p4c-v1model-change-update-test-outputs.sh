#! /bin/bash

# Run this script from inside of the p4c/build directory, if you add
# or remove lines in the p4c/p4include/v1model.p4 include file.  The
# tests below cause p4c to print error messages that contain line
# numbers within the v1model.p4 file, so passing 'make check' tests
# requires updating these line numbers in the expected output files.

./p4/testdata/p4_16_samples/issue841.p4.test -f
./err/testdata/p4_16_errors/issue1541.p4.test -f
./err/testdata/p4_16_errors/issue513.p4.test -f
