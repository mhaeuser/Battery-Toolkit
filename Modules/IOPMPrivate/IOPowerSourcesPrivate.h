/*
 * Copyright (c) 2003-2010 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef _IOPowerSourcesPrivate_h_
#define _IOPowerSourcesPrivate_h_

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <sys/cdefs.h>

__BEGIN_DECLS

/*!
 * @define      kIOPSNotifyPercentChange
 * @abstract    Notify(3) key. The system delivers notifications on this key when
 *              an attached power sourceÕs percent charge remaining changes;
 *              Also delivers this notification when the active power source
 *              changes (from limited to unlimited and vice versa).
 *
 * @discussion  See API <code>@link IOPSGetPercentRemaining @/link</code> to determine the percent charge remaining;
 *              and API <code>@link IOPSDrawingUnlimitedPower @/link</code> to determine if the active power source
 *              is unlimited.
 *
 *              See also kIOPSNotifyPowerSource and kIOPSNotifyLowBattery
 */
#define kIOPSNotifyPercentChange                "com.apple.system.powersources.percent"

/*!
 * @function    IOPSGetPercentRemaining
 * @abstract    Get the percent charge remaining for the device power source(s).
 * @param       percent - Returns the percent charge remaining (0 to 100).
 * @param       isCharging - Returns true if the power source is being charged. Optional parameter.
 * @param       isFullyCharged - Returns true if the power source is fully charged. Optional parameter.
 * @result      Returns kIOReturnSuccess on success, or an error code from IOReturn.h and
 *              also report the percent remaining as 100%.
 */
IOReturn        IOPSGetPercentRemaining(int *percent, bool *isCharging, bool *isFullyCharged);

/*!
 * @function    IOPSDrawingUnlimitedPower
 * @abstract    Indicates whether the active power source is unlimited.
 * @result      Returns true if drawing from unlimited power (a wall adapter),
 *              or false if drawing from a limited source. (battery power)
 */
bool            IOPSDrawingUnlimitedPower(void);

__END_DECLS

#endif
