#! /bin/bash

find /usr/lib \! -type d -print0 | xargs -0 find-RSA_set0_key2.sh |& grep -v ' no symbols' | grep -v 'File format not recognized' | grep -v 'File truncated'

echo ""
echo "U in nm output means 'The symbol is undefined'"
echo "T in nm output means 'The sybmol is in the text (code) section'"
echo "Read 'man nm' output for meanings of other letters."
