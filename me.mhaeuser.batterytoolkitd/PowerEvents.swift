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
    internal private(set) static var chargeMode: BTStateInfo.ChargingMode = BTStateInfo.ChargingMode.standard
    
    private static var powerCreated: Bool   = false
    private static var percentCreated: Bool = false

    private static func LimitedPowerHandler(token: Int32) {
        BTPowerEvents.handleLimitedPower()
    }

    private static func PercentChangeHandler(token: Int32) {
        _ = BTPowerEvents.handleChargeHysteresis()
    }

    private static func registerLimitedPowerHandler() -> Bool {
        guard !BTPowerEvents.powerCreated else {
            return true
        }

        BTPowerEvents.powerCreated = BTDispatcher.registerLimitedPowerNotification(
            BTPowerEvents.LimitedPowerHandler
            )
        guard BTPowerEvents.powerCreated else {
            return false
        }

        BTPowerEvents.handleLimitedPower()
        
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
            BTPowerEvents.PercentChangeHandler
            )
        guard BTPowerEvents.percentCreated else {
            return false
        }

        let percent = BTPowerEvents.handleChargeHysteresis()
        //
        // In case charging to maximum or full were requested while the device
        // was on battery, enable it now if appropriate.
        //
        switch BTPowerEvents.chargeMode {
            case BTStateInfo.ChargingMode.toMaximum:
                if percent < BTSettings.maxCharge {
                    BTPowerState.enableCharging()
                }

            case BTStateInfo.ChargingMode.toFull:
                if percent < 100 {
                    BTPowerState.enableCharging()
                }

            case BTStateInfo.ChargingMode.standard:
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
        //
        // Disable charging to not have micro-charges happening when
        // connecting to power.
        //
        BTPowerState.disableCharging()
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
            if BTPowerEvents.chargeMode != BTStateInfo.ChargingMode.toFull || percent >= 100 {
                //
                // Charging modes are reset once we disable charging.
                //
                BTPowerEvents.chargeMode = BTStateInfo.ChargingMode.standard
                BTPowerState.disableCharging()
            }
        } else if percent < BTSettings.minCharge {
            BTPowerState.enableCharging()
        }
        
        return percent
    }
    
    private static func handleLimitedPower() {
        //
        // Immediately disable sleep to not interrupt the setup phase.
        //
        SleepKit.disableSleep()

        if IOPSDrawingUnlimitedPower() {
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
            
            let result = BTPowerEvents.registerPercentChangedHandler()
            if !result {
                os_log("Failed to register percent changed handler")
                BTPowerEvents.restoreDefaults()
            }
            //
            // Restore sleep from the setup phase.
            //
            SleepKit.restoreSleep()
        } else {
            BTPowerEvents.unregisterPercentChangedHandler()
            //
            // Force restoring sleep to not ever disable sleep when not
            // connected to power. This call implicitly restores sleep from the
            // setup phase.
            //
            SleepKit.forceRestoreSleep()
        }
    }

    private static func restoreDefaults() {
        // FIXME: Enable!
        //BTPowerState.enableCharging()
        BTPowerState.enablePowerAdapter()
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
        
        BTSettings.read()
        
        let registerSuccess = registerLimitedPowerHandler()
        guard registerSuccess else {
            SMCKit.stop()
            return false
        }
        
        return true
    }
    
    internal static func stop() {
        BTPowerEvents.unregisterLimitedPowerHandler()
        BTPowerEvents.unregisterPercentChangedHandler()
        BTPowerEvents.restoreDefaults()

        SMCKit.stop()
        
        SleepKit.forceRestoreSleep()
    }
    
    internal static func settingsChanged() {
        guard BTPowerEvents.percentCreated else {
            return
        }

        _ = BTPowerEvents.handleChargeHysteresis()
    }
    
    private static func enableBelowThresholdMode(threshold: UInt8) {
        //
        // When the percent loop is inactive, this currently means that the
        // device is not connected to power. In this case, do not enable
        // charging to not disable sleep. The charging mode will be handled by
        // power source handler when power is connected.
        //
        guard BTPowerEvents.percentCreated else {
            return
        }
        
        var percent: Int32 = 100
        let result = IOPSGetPercentRemaining(&percent, nil, nil)
        guard result == kIOReturnSuccess else {
            os_log("Failed to retrieve battery percent")
            return;
        }

        if percent < threshold {
            BTPowerState.enableCharging()
        }
    }
    
    internal static func chargeToMaximum() {
        BTPowerEvents.chargeMode = BTStateInfo.ChargingMode.toMaximum
        BTPowerEvents.enableBelowThresholdMode(threshold: BTSettings.maxCharge)
    }

    internal static func disableCharging() {
        BTPowerEvents.chargeMode = BTStateInfo.ChargingMode.standard
        BTPowerState.disableCharging()
    }
    
    internal static func chargeToFull() {
        BTPowerEvents.chargeMode = BTStateInfo.ChargingMode.toFull
        BTPowerEvents.enableBelowThresholdMode(threshold: 100)
    }

    internal static func getChargingProgress() -> BTStateInfo.ChargingProgress {
        var percent: Int32 = 100
        let result = IOPSGetPercentRemaining(&percent, nil, nil)
        guard result == kIOReturnSuccess else {
            os_log("Failed to retrieve battery percent")
            return BTStateInfo.ChargingProgress.full;
        }

        if percent < BTSettings.maxCharge {
            return BTStateInfo.ChargingProgress.belowMax
        }

        if percent < 100 {
            return BTStateInfo.ChargingProgress.belowFull
        }

        return BTStateInfo.ChargingProgress.full
    }
}
