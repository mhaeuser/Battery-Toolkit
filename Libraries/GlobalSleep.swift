//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

import IOPMPrivate

@MainActor
public enum GlobalSleep {
    /// There can be multiple factors to disable sleep, e.g., active battery
    /// charging or a disabled power adapter. Use a counter to allow independent
    /// control by all sources.
    private static var disabledCounter: UInt8 = 0

    /// Honour the user-specified sleep disabled state for restoration.
    private static var previousDisabled = false

    static func forceRestore() {
        guard self.disabledCounter > 0 else {
            return
        }

        self.disabledCounter = 0
        self.restorePrevious()
    }

    static func restore() {
        assert(self.disabledCounter > 0)
        self.disabledCounter -= 1

        guard self.disabledCounter == 0 else {
            return
        }

        self.restorePrevious()
    }

    static func disable() {
        assert(self.disabledCounter >= 0)
        self.disabledCounter += 1

        guard self.disabledCounter == 1 else {
            return
        }

        let sleepDisable = self.sleepDisabledIOPMValue()
        self.previousDisabled = sleepDisable
        guard !sleepDisable else {
            return
        }

        let result = IOPMSetSystemPowerSetting(
            kIOPMSleepDisabledKey as CFString,
            kCFBooleanTrue
        )
        if result != kIOReturnSuccess {
            os_log("Failed to disable sleep")
        }
    }

    private static func sleepDisabledIOPMValue() -> Bool {
        guard let settingsRef = IOPMCopySystemPowerSettings() else {
            os_log("System power settings could not be retrieved")
            return false
        }

        guard
            let settings =
            settingsRef.takeUnretainedValue() as? [String: AnyObject]
        else {
            os_log("System power settings are malformed")
            return false
        }

        guard let sleepDisable = settings[kIOPMSleepDisabledKey] as? Bool else {
            os_log("Sleep disable setting is malformed")
            return false
        }

        return sleepDisable
    }

    private static func restorePrevious() {
        guard !self.previousDisabled else {
            self.previousDisabled = false
            return
        }

        let result = IOPMSetSystemPowerSetting(
            kIOPMSleepDisabledKey as CFString,
            kCFBooleanFalse
        )
        if result != kIOReturnSuccess {
            os_log("Failed to restore sleep disable")
        }
    }
}
