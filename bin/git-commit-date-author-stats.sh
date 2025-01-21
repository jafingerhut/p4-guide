#! /bin/bash

echo "Most recent commit:"
git log -n 1 | grep '^Date:'

echo ""
echo "Number of commits by year:"
echo "<# commits> <year>"
echo ""
git log . | grep '^Date:' | awk '{print $6;}' | sort | uniq -c

echo ""
echo "Number of commits by person, for most 10 frequent committers:"
echo "<# commits> <person>"
git log . | grep '^Author:' | sort | uniq -c | sort -n | tail -n 10
