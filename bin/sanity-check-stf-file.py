#! /usr/bin/env python3

import os, sys
import re
import fileinput

######################################################################
# Parsing optional command line arguments
######################################################################

import argparse

parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,
                                 description="""
Usage: sanity-check-stf-file.py <stf_file1> ...

Example of using it in the root directory of a clone of the p4c
repository, to check the contents of all STF files:

    find . -name '*.stf' | xargs sanity-check-stf-file.py

Reads one or more STF files given on the command line, and prints
messages about any odd things it finds about those files that might
indicate a problem with the STF file.

At the moment it only warns about 'packet' or 'expect' lines that
contain an odd number of hex digits describing packets, or that
contain non hex-digit characters in them.
""")

args = parser.parse_known_args()[0]


def proc_expect_line(line, fname, lineno):
    #print("exp '%s': %d: '%s'" % (fname, lineno, line))
    match = re.match(r"^\s*expect\s+(\d+)\s+(.*)$", line)
    if not match:
        match = re.match(r"^\s*expect\s+(\d+)$", line)
        assert match
        return
    port = int(match.group(1))
    packet = match.group(2)
    packet = ''.join(packet.split())
    if packet[-1] == '$':
        packet = packet[:-1]
    #print("exp port=%d pkt='%s'" % (port, packet))
    if len(packet) % 2 != 0:
        print("exp odd len: %s(%d) len %d: %s"
              "" % (fname, lineno, len(packet), line))
    if not re.match(r"^[0-9a-fA-F*]+$", packet):
        print("exp bad char: %s(%d) len %d: %s"
              "" % (fname, lineno, len(packet), line))

def proc_packet_line(line, fname, lineno):
    #print("pkt '%s': %d: '%s'" % (fname, lineno, line))
    match = re.match(r"^\s*packet\s+(\d+)\s+(.*)$", line)
    assert match
    port = int(match.group(1))
    packet = match.group(2)
    packet = ''.join(packet.split())
    if len(packet) % 2 != 0:
        print("pkt odd len: %s(%d) len %d: %s"
              "" % (fname, lineno, len(packet), line))
    if not re.match(r"^[0-9a-fA-F]+$", packet):
        print("pkt bad char: %s(%d) len %d: %s"
              "" % (fname, lineno, len(packet), line))

for line in fileinput.input():
    # do something to line here
    # Current file name: fileinput.filename()
    # Line number within current file: fileinput.filelineno()
    # Cumulative line number across all files: fileinput.lineno()
    line = line.strip()
    match = re.match(r"^\s*expect ", line)
    if match:
        proc_expect_line(line, fileinput.filename(), fileinput.filelineno())
        continue
    match = re.match(r"^\s*packet ", line)
    if match:
        proc_packet_line(line, fileinput.filename(), fileinput.filelineno())
        continue
