/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import IOKit.ps
import IOPMPrivate

@MainActor
internal struct BTPowerEvents {
    internal private(set) static var chargeMode: BTStateInfo.ChargingMode = .standard
    
    private static var powerCreated: Bool   = false
    private static var percentCreated: Bool = false

    private static func limitedPowerHandler(token: Int32) {
        handleLimitedPower()
    }

    private static func percentChangeHandler(token: Int32) {
        //
        // An unlucky dispatching order of LimitedPower and PercentChanged
        // events may cause this constraint to actually be violated.
        //
        guard BTPowerEvents.percentCreated else {
            return
        }

        _ = handleChargeHysteresis()
    }

    private static func registerLimitedPowerHandler() -> Bool {
        guard !BTPowerEvents.powerCreated else {
            return true
        }
        //
        // The charging state has no default value when starting the daemon.
        // We do not want to default to enabled, because this may cause many
        // micro-charges when continuously updating the daemon.
        // We do not want to default to disabled, because this may cause
        // micro-charges when starting the service after a fresh boot (e.g.,
        // on Apple Silicon devices, where the SMC state is reset to
        // defaults when resetting the platform).
        //
        // Initialize the sleep state based on the current platform state.
        //
        BTPowerState.initSleepState()

        BTPowerEvents.powerCreated = BTDispatcher.registerLimitedPowerNotification(
            BTPowerEvents.limitedPowerHandler
            )
        guard BTPowerEvents.powerCreated else {
            return false
        }

        handleLimitedPower()
        
        return true
    }
    
    private static func unregisterLimitedPowerHandler() {
        guard BTPowerEvents.powerCreated else {
            return
        }

        BTDispatcher.unregisterLimitedPowerNotification()
        BTPowerEvents.powerCreated = false
    }

    private static func registerPercentChangedHandler() -> Bool {
        guard !BTPowerEvents.percentCreated else {
            return true
        }

        BTPowerEvents.percentCreated = BTDispatcher.registerPercentChangeNotification(
            BTPowerEvents.percentChangeHandler
            )
        guard BTPowerEvents.percentCreated else {
            return false
        }

        let percent = handleChargeHysteresis()
        //
        // In case charging to maximum or full were requested while the device
        // was on battery, enable it now if appropriate.
        //
        switch BTPowerEvents.chargeMode {
            case .toMaximum:
                if percent < BTSettings.maxCharge {
                    _ = BTPowerState.enableCharging()
                }

            case .toFull:
                if percent < 100 {
                    _ = BTPowerState.enableCharging()
                }

            case .standard:
                break
        }
        
        return true
    }

    private static func unregisterPercentChangedHandler() {
        guard BTPowerEvents.percentCreated else {
            return
        }
        
        BTDispatcher.unregisterPercentChangeNotification()
        BTPowerEvents.percentCreated = false
    }
    
    private static func handleChargeHysteresis() -> Int32 {
        assert(BTPowerEvents.percentCreated)

        var percent: Int32 = 100
        let result = IOPSGetPercentRemaining(&percent, nil, nil)
        guard result == kIOReturnSuccess else {
            os_log("Failed to retrieve battery percent")
            return 100;
        }
        //
        // The hysteresis does not apply when starting the daemon, as
        // micro-charges will already happen pre-boot and there is no point to
        // not just charge all the way to the maximum then.
        //
        if percent >= BTSettings.maxCharge {
            //
            // Do not disable charging till 100 percent are reached when
            // charging to full was requested. Charging to maximum is handled
            // implicitly, as it only forces charging in [min, max).
            //
            if BTPowerEvents.chargeMode != .toFull || percent >= 100 {
                //
                // Charging modes are reset once we disable charging.
                //
                BTPowerEvents.chargeMode = .standard
                _ = BTPowerState.disableCharging()
            }
        } else if percent < BTSettings.minCharge {
            _ = BTPowerState.enableCharging()
        }
        
        return percent
    }
    
    private static func handleLimitedPower() {
        //
        // Immediately disable sleep to not interrupt the setup phase.
        //
        SleepKit.disableSleep()

        if IOPSDrawingUnlimitedPower() {
            let result = registerPercentChangedHandler()
            if !result {
                os_log("Failed to register percent changed handler")
                restoreDefaults()
            }
        } else {
            BTPowerEvents.unregisterPercentChangedHandler()
            //
            // Disable charging to not have micro-charges happening when
            // connecting to power.
            //
            _ = BTPowerState.disableCharging()
        }
        //
        // Restore sleep from the setup phase.
        //
        SleepKit.restoreSleep()
    }

    private static func restoreDefaults() {
        // FIXME: Enable!
        //_ = BTPowerState.enableCharging()
        _ = BTPowerState.enablePowerAdapter()
    }

    internal static func start() -> Bool {
        let smcSuccess = SMCKit.start()
        guard smcSuccess else {
            return false
        }

        guard SMCPowerKit.supported() else {
            SMCKit.stop()
            return false
        }
        
        BTSettings.readDefaults()
        
        let registerSuccess = registerLimitedPowerHandler()
        guard registerSuccess else {
            SMCKit.stop()
            return false
        }
        
        return true
    }
    
    internal static func stop() {
        unregisterLimitedPowerHandler()
        unregisterPercentChangedHandler()
        restoreDefaults()

        SMCKit.stop()
        
        SleepKit.forceRestoreSleep()
    }
    
    internal static func settingsChanged() {
        guard BTPowerEvents.percentCreated else {
            return
        }

        _ = handleChargeHysteresis()
    }
    
    private static func enableBelowThresholdMode(threshold: UInt8) -> Bool {
        //
        // When the percent loop is inactive, this currently means that the
        // device is not connected to power. In this case, do not enable
        // charging to not disable sleep. The charging mode will be handled by
        // power source handler when power is connected.
        //
        guard BTPowerEvents.percentCreated else {
            return true
        }
        
        var percent: Int32 = 100
        let result = IOPSGetPercentRemaining(&percent, nil, nil)
        guard result == kIOReturnSuccess else {
            os_log("Failed to retrieve battery percent")
            return false
        }

        if percent < threshold {
            return BTPowerState.enableCharging()
        }

        return true
    }
    
    internal static func chargeToMaximum() -> Bool {
        BTPowerEvents.chargeMode = .toMaximum
        return enableBelowThresholdMode(threshold: BTSettings.maxCharge)
    }

    internal static func disableCharging() -> Bool {
        BTPowerEvents.chargeMode = .standard
        return BTPowerState.disableCharging()
    }
    
    internal static func chargeToFull() -> Bool {
        BTPowerEvents.chargeMode = .toFull
        return enableBelowThresholdMode(threshold: 100)
    }

    internal static func getChargingProgress() -> BTStateInfo.ChargingProgress {
        var percent: Int32 = 100
        let result = IOPSGetPercentRemaining(&percent, nil, nil)
        guard result == kIOReturnSuccess else {
            os_log("Failed to retrieve battery percent")
            return .full;
        }

        if percent < BTSettings.maxCharge {
            return .belowMax
        }

        if percent < 100 {
            return .belowFull
        }

        return .full
    }
}
