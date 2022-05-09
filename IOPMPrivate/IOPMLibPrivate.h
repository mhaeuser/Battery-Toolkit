/*
 * Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * The contents of this file constitute Original Code as defined in and
 * are subject to the Apple Public Source License Version 1.1 (the
 * "License").  You may not use this file except in compliance with the
 * License.  Please obtain a copy of the License at
 * http://www.apple.com/publicsource and read it before using this file.
 *
 * This Original Code and all software distributed under the License are
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef _IOPMLibPrivate_h_
#define _IOPMLibPrivate_h_

#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CFArray.h>

__BEGIN_DECLS

/*
 * kIOPMSystemSleepAvailableAtAll
 *      System Power Setting (not power source specific)
 *      value = true/false
 */
#define    kIOPMSleepDisabledKey    CFSTR("SleepDisabled")

/*!
@function IOPMCopySystemPowerSettings
@abstract Returns System power settings.
      System-wide power settings are not power source dependent.
 */
CFDictionaryRef IOPMCopySystemPowerSettings( void );

/*
@function IOPMSetSystemPowerSetting
@abstract Set a system-wide power management setting
@param key Setting name
@param value Setting value
@result kIOReturnSuccess; or IOReturn error otherwise
 */
IOReturn IOPMSetSystemPowerSetting( CFStringRef key, CFTypeRef value );

__END_DECLS

#endif // _IOPMLibPrivate_h_
