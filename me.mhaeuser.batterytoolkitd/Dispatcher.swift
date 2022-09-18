/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import notify
import Dispatch
import IOPMPrivate

@MainActor
internal struct BTDispatcher {
    private static var percentToken: Int32 = 0
    private static var powerToken: Int32   = 0

    private static func registerDispatch(_ notify_type: UnsafePointer<CChar>!, _ handler: @MainActor @escaping (Int32) -> Void) -> Int32 {
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
        return status == NOTIFY_STATUS_OK ? token : 0
    }
    
    private static func unregisterDispatch(token: Int32) -> Bool {
        return notify_cancel(token) == NOTIFY_STATUS_OK
    }
    
    internal static func registerLimitedPowerNotification(_ handler: @MainActor @escaping (Int32) -> Void) -> Bool {
        assert(BTDispatcher.powerToken == 0)
        BTDispatcher.powerToken = BTDispatcher.registerDispatch(
            kIOPSNotifyPowerSource,
            handler
            )
        return BTDispatcher.powerToken != 0
    }
    
    internal static func registerPercentChangeNotification(_ handler: @MainActor @escaping (Int32) -> Void) -> Bool {
        assert(BTDispatcher.percentToken == 0)

        BTDispatcher.percentToken = BTDispatcher.registerDispatch(
            kIOPSNotifyPercentChange,
            handler
            )
        return BTDispatcher.percentToken != 0
    }
    
    internal static func unregisterPercentChangeNotification() {
        assert(BTDispatcher.percentToken != 0)

        let result = BTDispatcher.unregisterDispatch(token: BTDispatcher.percentToken)
        if !result {
            os_log("Failed to unregister limited percent change notification")
        }

        BTDispatcher.percentToken = 0
    }
    
    internal static func unregisterLimitedPowerNotification() {
        assert(BTDispatcher.powerToken != 0)

        let result = BTDispatcher.unregisterDispatch(token: BTDispatcher.powerToken)
        if !result {
            os_log("Failed to unregister limited power notification")
        }

        BTDispatcher.powerToken = 0
    }
}
