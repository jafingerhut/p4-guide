#! /bin/bash

P4C="$1"
version="$2"

ls -l ${P4C}

# I found this bit of trickery at the StackOverflow link below.  I
# have tested that if the script is referenced through a symbolic link
# (1 level of linking testd), it gets the directory where the symbolic
# link is, not the directory where the linked-to file is located.  I
# believe that is what we want if this script is checked out as a
# linked tree: the directory of the checked-out version, which might
# have changes to other files in the checked-out tree in that same
# directory, and we want to see those.
# http://stackoverflow.com/questions/421772/how-can-a-bash-script-know-the-directory-it-is-installed-in-when-it-is-sourced-w

INSTALL_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))
echo "cd'ing to INSTALL_DIR ${INSTALL_DIR}"
cd ${INSTALL_DIR}

${P4C} --target bmv2 --arch v1model strength5.p4 >& strength5-stderr-stdout.txt
${P4C} --target bmv2 --arch v1model strength5-alt1.p4 >& strength5-alt1-stderr-stdout.txt
mkdir -p ${version}
mv *.p4i *.json *-stderr-stdout.txt ${version}

# The command above can return a failed exit status if it does not
# find files with suffixes .json or .p4i, and that will return that
# exit status to the bash script that calls this one, causing it to
# stop.  Consistently return a 0 exit status from this script, no
# matter the exit status of the previous command:
exit 0
