#ifndef SAI_ROLES_P4_
#define SAI_ROLES_P4_

#define P4RUNTIME_ROLE_SDN_CONTROLLER "sdn_controller"

// Instantiations of SAI P4 can override these roles by defining the macros.

#ifndef P4RUNTIME_ROLE_ROUTING
#define P4RUNTIME_ROLE_ROUTING P4RUNTIME_ROLE_SDN_CONTROLLER
#endif

#ifndef P4RUNTIME_ROLE_MIRRORING
#define P4RUNTIME_ROLE_MIRRORING P4RUNTIME_ROLE_SDN_CONTROLLER
#endif

#ifndef P4RUNTIME_ROLE_PACKET_REPLICATION_ENGINE
#define P4RUNTIME_ROLE_PACKET_REPLICATION_ENGINE \
  "packet_replication_engine_manager"
#endif

#endif  // SAI_ROLES_P4_
