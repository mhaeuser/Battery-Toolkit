/*@file
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

#ifndef _SecCodeEx_h_
#define _SecCodeEx_h_

#include <Security/CSCommon.h>

__BEGIN_DECLS

/**
  Wrapper around SecCodeCopySigningInformation that takes a SecCodeRef for a
  code reference.
 */
OSStatus SecCodeCopySigningInformationDynamic(
    SecCodeRef __nonnull code,
    SecCSFlags flags,
    CFDictionaryRef * __nonnull CF_RETURNS_RETAINED information
);

__END_DECLS

#endif
