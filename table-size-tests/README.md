# Introduction

This directory has some files related to the question of what size is
specified for tables in the P4Info file created by p4c for a P4
program for many different cases of table properties (perhaps covering
all of the interesting cases), and suggestions for changes that seem
like improvements.

Current behavior as of 2023-Sep-12 version of p4c:

+ https://docs.google.com/spreadsheets/d/1-jme-7eVRXm-LrkjafQHXpava1O0s8VcAYyb9OZgtuU


Proposed pseudocode with behavior that seems like an improvement to
me:

+ [p4info-table-size-calc.c](p4info-table-size-calc.c)

P4Runtime API specification issue that gave rise to this work:

+ https://github.com/p4lang/p4runtime/issues/455
