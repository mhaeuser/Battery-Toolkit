//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

import IOPMPrivate

@MainActor
public enum GlobalSleep {
    private static var sleepDisabledCounter: UInt8 = 0
    private static var sleepRestore = false

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

    private static func restorePreviousSleepState() {
        let result = IOPMSetSystemPowerSetting(
            kIOPMSleepDisabledKey as CFString,
            GlobalSleep.sleepRestore ? kCFBooleanTrue : kCFBooleanFalse
        )
        if result != kIOReturnSuccess {
            os_log(
                "Failed to restore sleep disable to \(GlobalSleep.sleepRestore)"
            )
        }

        GlobalSleep.sleepRestore = false
    }

    public static func forceRestoreSleep() {
        guard GlobalSleep.sleepDisabledCounter > 0 else {
            return
        }

        GlobalSleep.sleepDisabledCounter = 0
        self.restorePreviousSleepState()
    }

    public static func restoreSleep() {
        assert(GlobalSleep.sleepDisabledCounter > 0)
        GlobalSleep.sleepDisabledCounter -= 1

        guard GlobalSleep.sleepDisabledCounter == 0 else {
            return
        }

        self.restorePreviousSleepState()
    }

    public static func disableSleep() {
        assert(GlobalSleep.sleepDisabledCounter >= 0)
        GlobalSleep.sleepDisabledCounter += 1

        guard GlobalSleep.sleepDisabledCounter == 1 else {
            return
        }

        GlobalSleep.sleepRestore = self.sleepDisabledIOPMValue()

        let result = IOPMSetSystemPowerSetting(
            kIOPMSleepDisabledKey as CFString,
            kCFBooleanTrue
        )
        if result != kIOReturnSuccess {
            os_log("Failed to disable sleep")
        }
    }
}
