#! /usr/bin/env python3

import sys
import difflib

modlst1 = sorted(list(sys.modules.keys()))

import ptf

modlst2 = sorted(list(sys.modules.keys()))

if len(sys.argv) >= 2:
    if sys.argv[1] == "bf_pktpy":
        ptf.config["packet_manipulation_module"] = "bf_pktpy.ptf.packet_pktpy"
    elif sys.argv[1] == "scapy":
        ptf.config["packet_manipulation_module"] = "ptf.packet_scapy"

import ptf.packet

modlst3 = sorted(list(sys.modules.keys()))

def calc_diff(strlst1, strlst2):
    diff = difflib.ndiff(strlst1, strlst2)
    difflst = [line for line in diff if not line.startswith('  ')]
    return difflst

def show_diff(diff):
    for line in diff:
        print(line)

#diff12 = difflib.unified_diff(modlst1, modlst2, lineterm='')
#print("----------------------------------------")
#print("unidified_diff modlst1 modlst2 after ptf was imported")
#print("----------------------------------------")
#show_diff(diff12)

#diff12n = difflib.ndiff(modlst1, modlst2)
#diff12lst = [line for line in diff12n if not line.startswith('  ')]
diff12lst = calc_diff(modlst1, modlst2)
print("----------------------------------------")
print("ndiff modlst1 modlst2 after ptf was imported")
print("----------------------------------------")
show_diff(diff12lst)

diff23lst = calc_diff(modlst2, modlst3)
print("----------------------------------------")
print("diff modlst2 modlst3 after ptf.packet was imported with default scapy")
print("----------------------------------------")
show_diff(diff23lst)
