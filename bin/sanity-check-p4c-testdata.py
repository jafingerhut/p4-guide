#! /usr/bin/env python3

# Sanity check several facts about the files in directories within the
# p4c/testdata directories:

import collections
import os
import sys

def ends_with(str1, str2):
    if len(str1) < len(str2):
        return False
    if str1[-len(str2):] == str2:
        return str1[:-len(str2)]
    return False

def get_nested_dict(d, suf1, suf2):
    if suf1 not in d:
        return 0
    if suf2 not in d[suf1]:
        return 0
    return d[suf1][suf2]

def increment_nested_dict(d, suf1, suf2):
    if suf1 not in d:
        d[suf1] = dict()
    if suf2 not in d[suf1]:
        d[suf1][suf2] = 0
    d[suf1][suf2] += 1

dirname1 = 'testdata/p4_16_samples'
fl1 = os.listdir(dirname1)
#fl1 = os.walk(dirname1)
dirname2 = 'testdata/p4_16_samples_outputs'
fl2 = os.listdir(dirname2)
#fl2 = os.walk(dirname2)

#print(fl1)
#for x1 in fl1:
#    print("type: %s -> %s" % (type(x1), x1))
#for (dir_path, dir_names, file_names) in fl1:
#sys.exit(0)

######################################################################
# Sanity checks within the p4_16_samples directories
######################################################################

print("")
print("Checks local to directory %s ..." % (dirname1))
print("")
      
# All files have a suffix of '.p4' or '.stf'
dir1_prefix_lst = collections.defaultdict(list)
for f1 in sorted(fl1):
    if os.path.isdir(dirname1 + '/' + f1):
        print("directory %s" % (f1))
        continue
    suffixes = ['.p4', '.stf']
    found_suffix = False
    for suf in suffixes:
        pre = ends_with(f1, suf)
        if pre:
            found_suffix = True
            dir1_prefix_lst[suf].append(pre)
            break
    if found_suffix:
        continue
    if f1 == 'gen-large.py':
        print("%s - filed p4c issue #3592 about this file" % (f1))
        continue
    if f1 == 'v1model-newtype.pp':
        print("%s - filed p4c issue #3593 about this file" % (f1))
        continue
    print("git rm %s/%s" % (dirname1, f1))

print("")
print("File name suffix counts for directory %s:" % (dirname1))
print("")
for suf in sorted(dir1_prefix_lst.keys()):
    print("%s %d" % (suf, len(dir1_prefix_lst[suf])))

num_suf1_without_suf2 = {}
num_suf1_also_suf2 = {}

dir1_prefix_set = dict()
for suf in dir1_prefix_lst.keys():
    dir1_prefix_set[suf] = set(dir1_prefix_lst[suf])

# For every 'foo.stf' file, there is a corresponding file 'foo.p4'
suf_pair_lst = [['.stf', '.p4']]
for suf_pair in suf_pair_lst:
    suf1 = suf_pair[0]
    suf2 = suf_pair[1]
    for f1 in sorted(dir1_prefix_lst[suf1]):
        if f1 in dir1_prefix_set[suf2]:
            pass
        else:
            print("%s has %s but no %s file" % (f1, suf1, suf2))
            increment_nested_dict(num_suf1_without_suf2, suf1, suf2)
print("")
for suf_pair in suf_pair_lst:
    suf1 = suf_pair[0]
    suf2 = suf_pair[1]
    print("%d files found with %s suffix, but no corresponding %s file"
          "" % (get_nested_dict(num_suf1_without_suf2, suf1, suf2),
                suf1, suf2))

######################################################################
# Sanity checks within the p4_16_samples_outputs directories
######################################################################

print("")
print("Checks local to directory %s ..." % (dirname2))
print("")

# All files have an expected suffix in their name
dir2_prefix_lst = collections.defaultdict(list)
for f2 in sorted(fl2):
    if os.path.isdir(dirname2 + '/' + f2):
        print("directory %s" % (f2))
        continue
    # I am not sure, but I think the p4c-dpdk tests use files with
    # this suffix, whereas all other back ends use .p4-stderr
    suffixes = ['-first.p4', '-frontend.p4', '-midend.p4', '.p4',
                '.p4-error', '.p4-stderr', '.p4.p4info.txt', '.p4.entries.txt',
                '.p4.bfrt.json', '.p4.spec']
    for suf in suffixes:
        pre = ends_with(f2, suf)
        if pre:
            found_suffix = True
            dir2_prefix_lst[suf].append(pre)
            break
    if found_suffix:
        continue
    print("git rm %s/%s" % (dirname2, f2))

print("")
print("File name suffix counts for directory %s:" % (dirname2))
print("")
for suf in sorted(dir2_prefix_lst.keys()):
    print("%s %d" % (suf, len(dir2_prefix_lst[suf])))

dir2_prefix_set = dict()
for suf in dir2_prefix_lst.keys():
    dir2_prefix_set[suf] = set(dir2_prefix_lst[suf])

print("")
# For every file foo.p4.entries.txt, there is a file foo.p4.p4info.txt
# For every file foo.p4info.txt, there is a file foo.p4
# For every file foo.p4-stderr, there is a file foo.p4
# For every file foo.p4-error, there is a file foo.p4
# For every file 'foo-first.p4' there is a file 'foo.p4', and vice versa
# For every file 'foo-frontend.p4' there is a file 'foo.p4', and vice versa
# For every file 'foo-midend.p4' there is a file 'foo.p4', and vice versa
suf_pair_lst = [['.p4.entries.txt', '.p4.p4info.txt'],
                ['.p4.p4info.txt', '.p4'],
                ['.p4-stderr', '.p4'],
                ['.p4-error', '.p4'],
                ['-first.p4', '.p4'],
                ['.p4', '-first.p4'],
                ['-frontend.p4', '.p4'],
                ['.p4', '-frontend.p4'],
                ['-midend.p4', '.p4'],
                ['.p4', '-midend.p4']]
for suf_pair in suf_pair_lst:
    suf1 = suf_pair[0]
    suf2 = suf_pair[1]
    for f1 in sorted(dir2_prefix_lst[suf1]):
        if f1 in dir2_prefix_set[suf2]:
            pass
        else:
            print("%s has %s but no %s file" % (f1, suf1, suf2))
            increment_nested_dict(num_suf1_without_suf2, suf1, suf2)

# Check whether any test programs have both a .p4-stderr and a
# .p4-error suffix.  Perhaps this is useful because we want CI tests
# for p4-dpdk back end to have different error messages that CI
# checks, vs. other p4c back ends.
suf1 = '.p4-stderr'
suf2 = '.p4-error'
for f2 in sorted(dir2_prefix_lst[suf1]):
    if f2 in dir2_prefix_lst[suf2]:
        print("%s has both %s and %s suffixes in directory %s"
              "" % (f2, suf1, suf2, dirname2))
        increment_nested_dict(num_suf1_also_suf2, suf1, suf2)

print("")
for suf_pair in suf_pair_lst:
    suf1 = suf_pair[0]
    suf2 = suf_pair[1]
    print("%d files found with %s suffix, but no corresponding %s file"
          "" % (get_nested_dict(num_suf1_without_suf2, suf1, suf2),
                suf1, suf2))
suf1 = '.p4-stderr'
suf2 = '.p4-error'
print("%d files with both %s and %s suffix in directory %s"
      "" % (get_nested_dict(num_suf1_also_suf2, suf1, suf2),
            suf1, suf2, dirname2))

######################################################################
# Sanity checks between the p4_16_samples and p4_16_samples_outputs
# directories
######################################################################
print("")
print("----------------------------------------------------------------------")
print("Sanity checks between directory %s and %s:"
      "" % (dirname1, dirname2))
print("----------------------------------------------------------------------")
print("")

# For every file p4_16_samples/foo.p4, there is a file
# p4_16_samples_outputs/foo.p4, and vice versa

print(".p4 files in directory %s but not %s"
      "" % (dirname1, dirname2))
n = 0
for f1 in sorted(dir1_prefix_lst['.p4']):
    if f1 in dir2_prefix_set['.p4']:
        pass
    else:
        n += 1
        print("%s.p4" % (f1))
if n == 0:
    print("(none)")

print("")
print(".p4 files in directory %s but not %s"
      "" % (dirname2, dirname1))
n = 0
for f2 in sorted(dir2_prefix_lst['.p4']):
    if f2 in dir1_prefix_set['.p4']:
        pass
    else:
        n += 1
        print("%s.p4" % (f2))
if n == 0:
    print("(none)")
