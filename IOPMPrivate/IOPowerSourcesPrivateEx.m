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

#include "IOPowerSourcesPrivate.h"
#include "IOPowerSourcesPrivateEx.h"

#include <IOKit/ps/IOPowerSources.h>
#include <notify.h>

/***
 Support structures and functions for IOPSNotificationCreateRunLoopSource
***/
typedef struct {
    IOPowerSourceCallbackType       callback;
    void                            *context;
    int                             token;
    CFMachPortRef                   mpRef;
} IOPSNotifyCallbackContext;

static void IOPSRLSMachPortCallback (CFMachPortRef port __unused, void *msg __unused, CFIndex size __unused, void *info)
{
    IOPSNotifyCallbackContext    *c = (IOPSNotifyCallbackContext *)info;
    IOPowerSourceCallbackType cb;
    
    if (c && (cb = c->callback)) {
        (*cb)(c->context);
    }
}

static void IOPSRLSMachPortRelease(const void *info)
{
    IOPSNotifyCallbackContext    *c = (IOPSNotifyCallbackContext *)info;
    
    if (c) {
        if (0 != c->token) {
            notify_cancel(c->token);
        }
        if (c->mpRef) {
            CFMachPortInvalidate(c->mpRef);
            CFRelease(c->mpRef);
        }
        free(c);
    }
}

static CFRunLoopSourceRef doCreatePSRLS(const char *notify_type, IOPowerSourceCallbackType callback, void *context)
{
    int                             status = 0;
    int                             token = 0;
    mach_port_t                     mp = MACH_PORT_NULL;
    CFMachPortRef                   mpRef = NULL;
    CFMachPortContext               mpContext;
    CFRunLoopSourceRef              mpRLS = NULL;
    IOPSNotifyCallbackContext       *ioContext;
    Boolean                         isReused = false;
    int                             giveUpRetryCount = 5;

    status = notify_register_mach_port(notify_type, &mp, 0, &token);
    if (NOTIFY_STATUS_OK != status) {
        return NULL;
    }
    
    ioContext = calloc(1, sizeof(IOPSNotifyCallbackContext));
    ioContext->callback = callback;
    ioContext->context = context;
    ioContext->token = token;

    bzero(&mpContext, sizeof(mpContext));
    mpContext.info = (void *)ioContext;
    mpContext.release = IOPSRLSMachPortRelease;
    
    do {
        if (mpRef) {
            // CFMachPorts may be reused. We don't want to get a reused mach port; so if we're unlucky enough
            // to get one, we'll pre-emptively invalidate it, throw them back in the pool, and retry.
            CFMachPortInvalidate(mpRef);
            CFRelease(mpRef);
        }
        
        mpRef = CFMachPortCreateWithPort(0, mp, IOPSRLSMachPortCallback, &mpContext, &isReused);
    } while (!mpRef && isReused && (--giveUpRetryCount > 0));

    if (mpRef) {
        if (!isReused) {
            // A reused mach port is a failure; it'll have an invalid callback pointer associated with it.
            ioContext->mpRef = mpRef;
            mpRLS = CFMachPortCreateRunLoopSource(0, mpRef, 0);
        }
        CFRelease(mpRef);
    }
    
    return mpRLS;
}

CFRunLoopSourceRef IOPSCreatePercentChangeNotification(IOPowerSourceCallbackType callback, void *context) {
    return doCreatePSRLS(kIOPSNotifyPercentChange, callback, context);
}
