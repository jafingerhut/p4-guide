#ifndef __DASH_TARGET_SPECIFIC__
#define __DASH_TARGET_SPECIFIC__

#ifdef TARGET_BMV2_V1MODEL

#include <v1model.p4>
#define DIRECT_COUNTER_TABLE_PROPERTY counters

#endif // TARGET_BMV2_V1MODEL

#ifdef TARGET_DPDK_PNA

#include <pna.p4>
#define DIRECT_COUNTER_TABLE_PROPERTY pna_direct_counter

#endif // TARGET_DPDK_PNA

#endif // __DASH_TARGET_SPECIFIC__
