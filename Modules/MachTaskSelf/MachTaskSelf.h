//
// Copyright (C) 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

#ifndef _MachTaskSelf_h_
#define _MachTaskSelf_h_

#include <mach/mach_types.h>

__BEGIN_DECLS

mach_port_t get_mach_task_self(void);

__END_DECLS

#endif
