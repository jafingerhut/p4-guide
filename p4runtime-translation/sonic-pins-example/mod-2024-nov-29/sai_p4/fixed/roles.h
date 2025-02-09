/*
 * Copyright 2024 Andy Fingerhut
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

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
