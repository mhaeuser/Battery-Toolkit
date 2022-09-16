import Foundation
import IOKit.ps
import IOPMPrivate

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
        if BTPowerEvents.powerCreated {
            return true
        }

        BTPowerEvents.powerCreated = BTDispatcher.registerLimitedPowerNotification(
            BTPowerEvents.LimitedPowerHandler
            )
        if !BTPowerEvents.powerCreated {
            return false
        }

        BTPowerEvents.handleLimitedPower()
        
        return true
    }
    
    private static func unregisterLimitedPowerHandler() {
        if !BTPowerEvents.powerCreated {
            return
        }

        BTDispatcher.unregisterLimitedPowerNotification()
        BTPowerEvents.powerCreated = false
    }

    private static func registerPercentChangedHandler() -> Bool {
        if BTPowerEvents.percentCreated {
            return true
        }

        BTPowerEvents.percentCreated = BTDispatcher.registerPercentChangeNotification(
            BTPowerEvents.PercentChangeHandler
            )
        if !BTPowerEvents.percentCreated {
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
        if !BTPowerEvents.percentCreated {
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
        if result != kIOReturnSuccess {
            // FIXME: Handle error
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
                BTPowerEvents.restoreDefaults()
                // FIXME: Handle error
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
        let smcResult = SMCKit.start()
        if !smcResult {
            return false
        }

        if !SMCPowerKit.supported() {
            SMCKit.stop()
            return false
        }
        
        BTSettings.read()
        
        let registerResult = registerLimitedPowerHandler()
        if !registerResult {
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
        if !BTPowerEvents.percentCreated {
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
        if !BTPowerEvents.percentCreated {
            return
        }
        
        var percent: Int32 = 100
        let result = IOPSGetPercentRemaining(&percent, nil, nil)
        if result != kIOReturnSuccess {
            // FIXME: Handle error
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
        if result != kIOReturnSuccess {
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
