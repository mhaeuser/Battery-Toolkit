/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import ServiceManagement
import BTPreprocessor

internal struct BTLoginItem {
    internal static func enable() -> Bool {
        if #available(macOS 13.0, *) {
            return enableService()
        } else {
            return enableLegacy()
        }
    }

    internal static func disable() -> Bool {
        if #available(macOS 13.0, *) {
            return disableService()
        } else {
            return disableLegacy()
        }
    }

    @available(macOS 13.0, *)
    private static func registered(status: SMAppService.Status) -> Bool {
        return status != .notRegistered && status != .notFound
    }

    @available(macOS 13.0, *)
    private static func enableService() -> Bool {
        guard !registered(status: SMAppService.mainApp.status) else {
            os_log("Already registered login item: \(SMAppService.mainApp.status.rawValue)")
            return true
        }

        do {
            try SMAppService.mainApp.register()
            os_log("Registered login item")
            return true
        } catch {
            os_log("Failed to register login item: \(error)")
            return false
        }
    }

    @available(macOS 13.0, *)
    private static func disableService() -> Bool {
        _ = disableLegacy()

        guard registered(status: SMAppService.mainApp.status) else {
            return true
        }

        do {
            try SMAppService.mainApp.unregister()
            return true
        } catch {
            return false
        }
    }

    @available(macOS, deprecated: 13.0)
    private static func enableLegacy() -> Bool {
        return SMLoginItemSetEnabled(
            BT_AUTOSTART_NAME as CFString,
            true
            )
    }

    private static func disableLegacy() -> Bool {
        return SMLoginItemSetEnabled(
            BT_AUTOSTART_NAME as CFString,
            false
            )
    }
}
