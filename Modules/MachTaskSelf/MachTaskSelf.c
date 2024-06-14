//
// Copyright (C) 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

#include "MachTaskSelf.h"

#include <mach/mach_init.h>

mach_port_t get_mach_task_self(void) {
    return mach_task_self();
}
