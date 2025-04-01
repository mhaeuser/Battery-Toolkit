//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log
import ServiceManagement

internal enum BTLoginItem {
    static func enable() -> Bool {
        if #available(macOS 13.0, *) {
            return self.enableService()
        } else {
            return self.enableLegacy()
        }
    }

    static func disable() -> Bool {
        if #available(macOS 13.0, *) {
            return self.disableService()
        } else {
            return self.disableLegacy()
        }
    }

    @available(macOS 13.0, *)
    private static func registered(status: SMAppService.Status) -> Bool {
        return status != .notRegistered && status != .notFound
    }

    @available(macOS 13.0, *)
    private static func enableService() -> Bool {
        guard !self.registered(status: SMAppService.mainApp.status) else {
            os_log(
                "Already registered login item: \(SMAppService.mainApp.status.rawValue)"
            )
            return true
        }

        do {
            try SMAppService.mainApp.register()
            return true
        } catch {
            os_log("Failed to register login item: \(error, privacy: .public))")
            return false
        }
    }

    @available(macOS 13.0, *)
    private static func disableService() -> Bool {
        //
        // Disable the legacy Login Item to silently upgrade next time it is
        // enabled.
        //
        _ = self.disableLegacy()

        guard self.registered(status: SMAppService.mainApp.status) else {
            os_log(
                "Login item is not registered: \(SMAppService.mainApp.status.rawValue)"
            )
            return true
        }

        do {
            try SMAppService.mainApp.unregister()
            return true
        } catch {
            os_log("Failed to unregister login item: \(error, privacy: .public))")
            return false
        }
    }

    @available(macOS, deprecated: 13.0)
    private static func enableLegacy() -> Bool {
        return SMLoginItemSetEnabled(
            BT_AUTOSTART_ID as CFString,
            true
        )
    }

    private static func disableLegacy() -> Bool {
        return SMLoginItemSetEnabled(
            BT_AUTOSTART_ID as CFString,
            false
        )
    }
}
