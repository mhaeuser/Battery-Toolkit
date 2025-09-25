//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Dispatch
import Foundation
import notify
import os.log

@MainActor
internal enum BTDispatcher {
    private static var percentToken: Int32 = 0
    private static var percentRegistered = false

    private static var powerToken: Int32 = 0
    private static var powerRegistered = false

    static func registerLimitedPowerNotification(
        _ handler: @MainActor @escaping (Int32) -> Void
    ) -> Bool {
        guard !self.powerRegistered else {
            return true
        }

        guard let powerToken = self.registerDispatch(
            kIOPSNotifyPowerSource,
            handler
        ) else {
            return false
        }

        self.powerToken = powerToken
        self.powerRegistered = true
        return true
    }

    static func registerPercentChangeNotification(
        _ handler: @MainActor @escaping (Int32) -> Void
    ) -> Bool {
        guard !self.percentRegistered else {
            return true
        }

        guard let percentToken = self.registerDispatch(
            IOPSPrivate.kIOPSNotifyPercentChange,
            handler
        ) else {
            return false
        }

        self.percentToken = percentToken
        self.percentRegistered = true
        return true
    }

    static func unregisterPercentChangeNotification() {
        guard self.percentRegistered else {
            return
        }

        let status = notify_cancel(self.percentToken)
        guard status == NOTIFY_STATUS_OK else {
            os_log("Failed to unregister percent change notification")
            return
        }

        self.percentRegistered = false
        self.percentToken = 0
    }

    static func unregisterLimitedPowerNotification() {
        guard self.powerRegistered else {
            return
        }

        let status = notify_cancel(self.powerToken)
        guard status == NOTIFY_STATUS_OK else {
            os_log("Failed to unregister limited power notification")
            return
        }

        self.powerRegistered = false
        self.powerToken = 0
    }

    private static func registerDispatch(
        _ notify_type: String,
        _ handler: @MainActor @escaping (Int32) -> Void
    ) -> Int32? {
        //
        // The warning about losing MainActor is misleading as notifications are
        // always posted to DispatchQueue.main as per the registration.
        //
        var token: Int32 = 0
        let status = notify_register_dispatch(
            notify_type,
            &token,
            DispatchQueue.main,
            handler
        )
        guard status == NOTIFY_STATUS_OK else {
            return nil
        }

        return token
    }
}
