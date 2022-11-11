//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Dispatch
import Foundation
import IOPMPrivate
import notify
import os.log

@MainActor
internal enum BTDispatcher {
    private static var percentRegistration = Registration()
    private static var powerRegistration = Registration()

    static func registerLimitedPowerNotification(
        _ handler: @MainActor @escaping (Int32) -> Void
    ) -> Bool {
        assert(!self.powerRegistration.valid)

        self.powerRegistration = self.registerDispatch(
            kIOPSNotifyPowerSource,
            handler
        )
        return self.powerRegistration.valid
    }

    static func registerPercentChangeNotification(
        _ handler: @MainActor @escaping (Int32) -> Void
    ) -> Bool {
        assert(!self.percentRegistration.valid)

        self.percentRegistration = self.registerDispatch(
            kIOPSNotifyPercentChange,
            handler
        )
        return self.percentRegistration.valid
    }

    static func unregisterPercentChangeNotification() {
        let success = self.unregisterDispatch(
            registration: self.percentRegistration
        )
        if !success {
            os_log("Failed to unregister percent change notification")
        }

        self.percentRegistration = BTDispatcher.Registration()
    }

    static func unregisterLimitedPowerNotification() {
        let success = self.unregisterDispatch(
            registration: self.powerRegistration
        )
        if !success {
            os_log("Failed to unregister limited power notification")
        }

        self.powerRegistration = BTDispatcher.Registration()
    }

    private static func registerDispatch(
        _ notify_type: String,
        _ handler: @MainActor @escaping (Int32) -> Void
    ) -> BTDispatcher.Registration {
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
        return Registration(valid: status == NOTIFY_STATUS_OK, token: token)
    }

    private static func unregisterDispatch(
        registration: BTDispatcher.Registration
    ) -> Bool {
        assert(registration.valid)

        return notify_cancel(registration.token) == NOTIFY_STATUS_OK
    }
}

private extension BTDispatcher {
    struct Registration {
        let valid: Bool
        let token: Int32

        init() {
            self.valid = false
            self.token = 0
        }

        init(valid: Bool, token: Int32) {
            self.valid = valid
            self.token = token
        }
    }
}
