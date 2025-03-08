#! /usr/bin/env python3

import os
import sys
import difflib

modlst1 = sorted(list(sys.modules.keys()))

import ptf

modlst2 = sorted(list(sys.modules.keys()))

pmm = None
if len(sys.argv) >= 2:
    if sys.argv[1] == "bf_pktpy":
        pmm = "bf_pktpy.ptf.packet_pktpy"
    elif sys.argv[1] == "scapy":
        pmm = "ptf.packet_scapy"
if pmm is not None:
    ptf.config["packet_manipulation_module"] = pmm

print("sys.version=%s" % (sys.version))
print("os.getenv('VIRTUAL_ENV')=%s" % (os.getenv('VIRTUAL_ENV')))
print("----------------------------------------")
print("Contents of file /etc/os-release")
print("----------------------------------------")
try:
    with open('/etc/os-release', 'r') as f:
        contents = f.read()
    print(contents)
except:
    print("=== Failed to open file /etc/os-release ===")
print("----------------------------------------")
print("Attempting to import ptf.packet with pmm='%s'" % (pmm))

import ptf.packet

modlst3 = sorted(list(sys.modules.keys()))

def calc_diff(strlst1, strlst2):
    diff = difflib.ndiff(strlst1, strlst2)
    difflst = [line for line in diff if not line.startswith('  ')]
    return difflst

def show_diff(diff):
    for line in diff:
        print(line)

print("----------------------------------------")
print("modlst1 = all python modules imported after only importing os, sys, difflib")
print("modlst1 (%d modules):" % (len(modlst1)))
print("----------------------------------------")
for module in sorted(modlst1):
    print(module)

diff12lst = calc_diff(modlst1, modlst2)
print("----------------------------------------")
print("modlst2 = all python modules imported after then importing ptf")
print("diff modlst1 modlst2 after ptf was imported (%d lines)"
      "" % (len(diff12lst)))
print("----------------------------------------")
show_diff(diff12lst)

diff23lst = calc_diff(modlst2, modlst3)
print("----------------------------------------")
print("modlst3 = python modules imported after also importing ptf.packet"
      " with pmm='%s'" % (pmm))
print("diff modlst2 modlst3 after ptf.packet was imported with default scapy"
      " (%d lines)" % (len(diff23lst)))
print("----------------------------------------")
show_diff(diff23lst)
