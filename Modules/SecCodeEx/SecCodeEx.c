/*@file
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

#include "SecCodeEx.h"

#include <Security/SecCode.h>

OSStatus SecCodeCopySigningInformationDynamic(
    SecCodeRef __nonnull code,
    SecCSFlags flags,
    CFDictionaryRef * __nonnull CF_RETURNS_RETAINED information
)
{
    return SecCodeCopySigningInformation(code, flags, information);
}
