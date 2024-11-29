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
