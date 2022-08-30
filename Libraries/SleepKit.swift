import Foundation

import IOPMPrivate

public struct SleepKit {
    private static var sleepDisabledCounter: UInt8 = 0
    private static var sleepRestore: Bool          = false
    
    private static func sleepDisabledIOPMValue() -> Bool {
        guard let uSettings = IOPMCopySystemPowerSettings() else {
            return false
        }
        
        guard let settings = uSettings.takeUnretainedValue() as? [String: AnyObject] else {
            return false
        }

        return settings[kIOPMSleepDisabledKey] as? Bool ?? false
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
            // FIXME: Handle error
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
            // FIXME: Handle error
        }
    }
}
