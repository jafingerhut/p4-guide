#! /bin/bash

# Count the total number of lines in a text file that are:
# + completely whitespace (or empty)
# + completely whitespace and a comment beginning with //
# + all other lines

FNAME="$1"

BLANK_LINES=`egrep '^\s*$' ${FNAME} | wc -l`
COMMENT_LINES=`egrep '^\s*//' ${FNAME} | wc -l`
OTHER_LINES=`egrep -v '^\s*$' ${FNAME} | egrep -v '^\s*//' | wc -l`
TOTAL_LINES=`cat ${FNAME} | wc -l`

echo "File: ${FNAME}"
echo "Blank lines: ${BLANK_LINES}"
echo "Comment lines: ${COMMENT_LINES}"
echo "Other lines: ${OTHER_LINES}"
echo "Total lines: ${TOTAL_LINES}"
