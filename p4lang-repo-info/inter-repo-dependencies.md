# target-utils is _only_ used by these other p4lang repos

p4-dpdk-target uses target-utils
tdi uses target-utils

# target-syslibs is _only_ used by these other p4lang repos

target-utils uses target-syslibs
tdi uses target-syslibs

# tdi is _only_ used by these other p4lang repos

p4-dpdk-target uses tdi

_Mentioned_ in p4-spec, but this is a reference in English, not a code
dependency.

p4c has some command line options with 'tdi' in them, but these are
just command line option names, not a code dependency.
