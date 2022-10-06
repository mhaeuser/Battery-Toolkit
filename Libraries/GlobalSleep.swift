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
            GlobalSleep.previousState ? kCFBooleanTrue : kCFBooleanFalse
        )
        if result != kIOReturnSuccess {
            os_log(
                "Failed to restore sleep disable to \(GlobalSleep.previousState)"
            )
        }

        GlobalSleep.previousState = false
    }

    public static func forceRestore() {
        guard GlobalSleep.disabledCounter > 0 else {
            return
        }

        GlobalSleep.disabledCounter = 0
        self.restorePrevious()
    }

    public static func restore() {
        assert(GlobalSleep.disabledCounter > 0)
        GlobalSleep.disabledCounter -= 1

        guard GlobalSleep.disabledCounter == 0 else {
            return
        }

        self.restorePrevious()
    }

    public static func disable() {
        assert(GlobalSleep.disabledCounter >= 0)
        GlobalSleep.disabledCounter += 1

        guard GlobalSleep.disabledCounter == 1 else {
            return
        }

        GlobalSleep.previousState = self.sleepDisabledIOPMValue()

        let result = IOPMSetSystemPowerSetting(
            kIOPMSleepDisabledKey as CFString,
            kCFBooleanTrue
        )
        if result != kIOReturnSuccess {
            os_log("Failed to disable sleep")
        }
    }
}
