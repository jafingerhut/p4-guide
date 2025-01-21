#! /bin/bash
# SPDX-License-Identifier: Apache-2.0

# Generate a list of files that are not a directory, and do not have
# one of these suffixes in their file names, that do _not_ have any
# occurrences of the string 'SPDX-Licnese-Identifier' inside of them.

# Ignore any files in a directory named `.git`.

# We do not include files with these suffixes, because these file
# formats are binary, or some other data file format that we cannot
# add comments to without affecting their use.

# .json
# .patch
# .pdf
# .png
# .svg
# .txt

find . ! -type d -print0 | xargs -0 grep -c SPDX-License-Identifier | grep ':0$' | grep -v '/.git/' | egrep -v '\.(json|patch|pdf|png|svg|txt)' | sort
