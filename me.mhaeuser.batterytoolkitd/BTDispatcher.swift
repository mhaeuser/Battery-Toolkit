//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log
import notify
import Dispatch
import IOPMPrivate

@MainActor
internal struct BTDispatcher {
    fileprivate struct Registration {
        fileprivate var valid: Bool  = false
        fileprivate var token: Int32 = 0
    }

    private static var percentRegistration = Registration()
    private static var powerRegistration   = Registration()

    private static func registerDispatch(_ notify_type: String, _ handler: @MainActor @escaping (Int32) -> Void) -> BTDispatcher.Registration {
        //
        // The warning about losing MainActor is misleading as notifications are
        // always posted to DispatchQueue.main as per the registration.
        //
        var token: Int32 = 0;
        let status = notify_register_dispatch(
            notify_type,
            &token,
            DispatchQueue.main,
            handler
            )
        return Registration(valid: status == NOTIFY_STATUS_OK, token: token)
    }
    
    private static func unregisterDispatch(registration: BTDispatcher.Registration) -> Bool {
        assert(registration.valid)

        return notify_cancel(registration.token) == NOTIFY_STATUS_OK
    }
    
    internal static func registerLimitedPowerNotification(_ handler: @MainActor @escaping (Int32) -> Void) -> Bool {
        assert(!BTDispatcher.powerRegistration.valid)

        BTDispatcher.powerRegistration = BTDispatcher.registerDispatch(
            kIOPSNotifyPowerSource,
            handler
            )
        return BTDispatcher.powerRegistration.valid
    }
    
    internal static func registerPercentChangeNotification(_ handler: @MainActor @escaping (Int32) -> Void) -> Bool {
        assert(!BTDispatcher.percentRegistration.valid)

        BTDispatcher.percentRegistration = BTDispatcher.registerDispatch(
            kIOPSNotifyPercentChange,
            handler
            )
        return BTDispatcher.percentRegistration.valid
    }
    
    internal static func unregisterPercentChangeNotification() {
        let result = BTDispatcher.unregisterDispatch(
            registration: BTDispatcher.percentRegistration
            )
        if !result {
            os_log("Failed to unregister percent change notification")
        }

        BTDispatcher.percentRegistration = BTDispatcher.Registration()
    }
    
    internal static func unregisterLimitedPowerNotification() {
        let result = BTDispatcher.unregisterDispatch(
            registration: BTDispatcher.powerRegistration
            )
        if !result {
            os_log("Failed to unregister limited power notification")
        }

        BTDispatcher.powerRegistration = BTDispatcher.Registration()
    }
}
