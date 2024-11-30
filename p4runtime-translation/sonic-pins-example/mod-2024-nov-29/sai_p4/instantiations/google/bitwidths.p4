#ifndef PINS_SAI_BITWIDTHS_P4_
#define PINS_SAI_BITWIDTHS_P4_

#ifdef PLATFORM_BMV2
  // Number of bits used for types that use @p4runtime_translation("", string).
  // This allows BMv2 to support string up to this length.
  #define STRING_MAX_BITWIDTH 256 // 32 chars

  // TODO: We want to use the commented definition, but BMv2 does not
  // support large numbers for ports.
  // #define PORT_BITWIDTH STRING_MAX_BITWIDTH
  #define PORT_BITWIDTH 9
  #define VRF_BITWIDTH STRING_MAX_BITWIDTH
  #define NEXTHOP_ID_BITWIDTH STRING_MAX_BITWIDTH
  #define ROUTER_INTERFACE_ID_BITWIDTH STRING_MAX_BITWIDTH
  #define WCMP_GROUP_ID_BITWIDTH STRING_MAX_BITWIDTH
  #define MIRROR_SESSION_ID_BITWIDTH STRING_MAX_BITWIDTH
  #define QOS_QUEUE_BITWIDTH STRING_MAX_BITWIDTH
  #define TUNNEL_ID_BITWIDTH STRING_MAX_BITWIDTH
#else
  #define PORT_BITWIDTH 9
  #define VRF_BITWIDTH 10
  #define NEXTHOP_ID_BITWIDTH 10
  #define ROUTER_INTERFACE_ID_BITWIDTH 10
  #define WCMP_GROUP_ID_BITWIDTH 12
  #define MIRROR_SESSION_ID_BITWIDTH 10
  #define QOS_QUEUE_BITWIDTH 8
  #define TUNNEL_ID_BITWIDTH 10
#endif

#endif  // PINS_SAI_BITWIDTHS_P4_
