// Copyright 2024 Andy Fingerhut
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

#ifndef SAI_FIXED_COMMON_ACTIONS_P4_
#define SAI_FIXED_COMMON_ACTIONS_P4_

#include "ids.h"

// This file lists common actions that may be used by multiple control blocks in
// the fixed pipeline.

// Action that does nothing. Like `NoAction` in `core.p4`, but following
// Google's naming conventions.
@id(SHARED_NO_ACTION_ACTION_ID)
action no_action() {}

#endif  // SAI_FIXED_COMMON_ACTIONS_P4_
