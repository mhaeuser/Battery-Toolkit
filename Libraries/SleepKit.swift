import Foundation

import IOPMPrivate

public struct SleepKit {
    private static var sleepDisabledCounter: UInt8 = 0
    private static var sleepRestore: Bool          = false
    
    private static func sleepDisabledIOPMValue() -> Bool {
        guard let uSettings = IOPMCopySystemPowerSettings() else {
            NSLog("System power settings could not be retrieved")
            return false
        }
        
        guard let settings = uSettings.takeUnretainedValue() as? [String: AnyObject] else {
            NSLog("System power settings are malformed")
            return false
        }

        guard let sleepDisable = settings[kIOPMSleepDisabledKey] as? Bool else {
            NSLog("Sleep disable setting is malformed")
            return false
        }

        return sleepDisable
    }
    
    public static func restoreSleep() {
        assert(SleepKit.sleepDisabledCounter > 0)
        SleepKit.sleepDisabledCounter -= 1

        if SleepKit.sleepDisabledCounter > 0 {
            return
        }

        let result = IOPMSetSystemPowerSetting(
            kIOPMSleepDisabledKey as CFString,
            SleepKit.sleepRestore ? kCFBooleanTrue : kCFBooleanFalse
            )
        if result != kIOReturnSuccess {
            NSLog("Failed to restore sleep disable to %d", SleepKit.sleepRestore)
        }
    }
    
    public static func disableSleep() {
        assert(SleepKit.sleepDisabledCounter >= 0)
        SleepKit.sleepDisabledCounter += 1

        if SleepKit.sleepDisabledCounter > 1 {
            return
        }
        
        SleepKit.sleepRestore = sleepDisabledIOPMValue()

        let result = IOPMSetSystemPowerSetting(
            kIOPMSleepDisabledKey as CFString,
            kCFBooleanTrue
            )
        if result != kIOReturnSuccess {
            NSLog("Failed to disable sleep")
        }
    }
}
