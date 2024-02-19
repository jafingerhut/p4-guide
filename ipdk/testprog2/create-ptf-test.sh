#! /bin/bash

p4testgen --target dpdk --arch pna --max-tests 1000 --out-dir ptf-tests --test-backend ptf testprog2.p4
