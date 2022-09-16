/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import notify
import Dispatch
import IOPMPrivate

internal struct BTDispatcher {
    private static var percentToken: Int32 = 0
    private static var powerToken: Int32   = 0

    private static func registerDispatch(_ notify_type: UnsafePointer<CChar>!, _ handler: notify_handler_t!) -> Int32 {
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
    
    internal static func registerLimitedPowerNotification(_ handler: notify_handler_t!) -> Bool {
        assert(BTDispatcher.powerToken == 0)
        BTDispatcher.powerToken = BTDispatcher.registerDispatch(
            kIOPSNotifyPowerSource,
            handler
            )
        return BTDispatcher.powerToken != 0
    }
    
    internal static func registerPercentChangeNotification(_ handler: notify_handler_t!) -> Bool {
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
            // FIXME: Handle error
        }

        BTDispatcher.percentToken = 0
    }
    
    internal static func unregisterLimitedPowerNotification() {
        assert(BTDispatcher.powerToken != 0)

        let result = BTDispatcher.unregisterDispatch(token: BTDispatcher.powerToken)
        if !result {
            // FIXME: Handle error
        }

        BTDispatcher.powerToken = 0
    }
}
