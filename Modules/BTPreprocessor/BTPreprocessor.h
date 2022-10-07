/*@file
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

#ifndef _BTPreprocessor_h_
#define _BTPreprocessor_h_

#include <Foundation/NSString.h>

__BEGIN_DECLS

/// The Battery Toolkit bundle identifier.
extern const NSString *const BT_APP_NAME;

/// The Battery Toolkit Service identifier.
extern const NSString *const BT_SERVICE_NAME;

/// The Battery Toolkit daemon identifier.
extern const NSString *const BT_DAEMON_NAME;

/// The Battery Toolkit Autostart identifier.
extern const NSString *const BT_AUTOSTART_NAME;

/// The Battery Toolkit codesign Common Name.
extern const NSString *const BT_CODE_SIGN_CN;

__END_DECLS

#endif
