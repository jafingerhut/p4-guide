#! /bin/bash

find . ! -type d -print0 | xargs -0 grep GPL
