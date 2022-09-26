/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

import IOPMPrivate

@MainActor
public struct SleepKit {
    private static var sleepDisabledCounter: UInt8 = 0
    private static var sleepRestore: Bool          = false
    
    private static func sleepDisabledIOPMValue() -> Bool {
        guard let settingsRef = IOPMCopySystemPowerSettings() else {
            os_log("System power settings could not be retrieved")
            return false
        }
        
        guard let settings = settingsRef.takeUnretainedValue() as? [String: AnyObject] else {
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
            SleepKit.sleepRestore ? kCFBooleanTrue : kCFBooleanFalse
            )
        if result != kIOReturnSuccess {
            os_log("Failed to restore sleep disable to \(SleepKit.sleepRestore)")
        }
        
        SleepKit.sleepRestore = false
    }
    
    public static func forceRestoreSleep() {
        guard SleepKit.sleepDisabledCounter > 0 else {
            return
        }

        SleepKit.sleepDisabledCounter = 0
        restorePreviousSleepState()
    }
    
    public static func restoreSleep() {
        assert(SleepKit.sleepDisabledCounter > 0)
        SleepKit.sleepDisabledCounter -= 1

        guard SleepKit.sleepDisabledCounter == 0 else {
            return
        }

        restorePreviousSleepState()
    }
    
    public static func disableSleep() {
        assert(SleepKit.sleepDisabledCounter >= 0)
        SleepKit.sleepDisabledCounter += 1

        guard SleepKit.sleepDisabledCounter == 1 else {
            return
        }
        
        SleepKit.sleepRestore = sleepDisabledIOPMValue()

        let result = IOPMSetSystemPowerSetting(
            kIOPMSleepDisabledKey as CFString,
            kCFBooleanTrue
            )
        if result != kIOReturnSuccess {
            os_log("Failed to disable sleep")
        }
    }
}
