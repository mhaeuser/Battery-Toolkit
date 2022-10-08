//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

import IOPMPrivate

@MainActor
public enum GlobalSleep {
    private static var disabledCounter: UInt8 = 0
    private static var previousState = false

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

        self.previousState = self.sleepDisabledIOPMValue()

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
        let result = IOPMSetSystemPowerSetting(
            kIOPMSleepDisabledKey as CFString,
            self.previousState ? kCFBooleanTrue : kCFBooleanFalse
        )
        if result != kIOReturnSuccess {
            os_log(
                "Failed to restore sleep disable to \(self.previousState)"
            )
        }

        self.previousState = false
    }
}
