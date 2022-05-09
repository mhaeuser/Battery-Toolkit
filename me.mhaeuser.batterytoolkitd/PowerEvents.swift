import IOKit.ps
import CoreFoundation
import IOPMPrivate

private enum BTChargeMode {
    case Default
    case ToMaxLimit
    case Full
}

private func LimitedPowerHandler(context: UnsafeMutableRawPointer?) {
    //
    // Immediately disable sleep to not interrupt the setup phase. It will be
    // restored when the maximum charge is reached or the charging handler is
    // uninstalled, whichever happens first.
    //
    SleepKit.disableSleep()

    if IOPSDrawingUnlimitedPower() {
        let result = BTPowerEvents.registerPercentChangedHandler()
        if !result {
            BTPowerEvents.restoreDefaults()
            // FIXME: Handle error
        }
    } else {
        BTPowerEvents.unregisterPercentChangedHandler()
    }

    SleepKit.restoreSleep()
}

private func PercentChangeHandler(context: UnsafeMutableRawPointer?) {
    _ = BTPowerEvents.handleChargeHysteresis()
}

public struct BTPowerEvents {
    fileprivate static var chargeMode: BTChargeMode = BTChargeMode.Default
    
    private static var powerLoop: CFRunLoopSource?   = nil
    private static var percentLoop: CFRunLoopSource? = nil

    fileprivate static func registerLimitedPowerHandler() -> Bool {
        if BTPowerEvents.powerLoop != nil {
            return true
        }
        //
        // The charging state has no default value when starting the daemon.
        // We do not want to default to enabled, because this may cause many
        // micro-charges when continuously updating the daemon.
        // We do not want to default to disabled, because this may cause
        // micro-charges when starting the service after a fresh boot (e.g., on
        // Apple Silicon devices, where the SMC state is reset to defaults when
        // resetting the platform).
        //
        // Initialize the charging state based on the current platform state.
        // This is especially important to properly set the sleep state when no
        // case of the hysteresis set it according to the charging state.
        //
        BTPowerState.initPowerState()

        BTPowerEvents.powerLoop = IOPSCreateLimitedPowerNotification(
            LimitedPowerHandler,
            nil
            ).takeRetainedValue() as CFRunLoopSource?
        if BTPowerEvents.powerLoop == nil {
            return false
        }

        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            BTPowerEvents.powerLoop,
            CFRunLoopMode.defaultMode
            )
        LimitedPowerHandler(context: nil)
        
        return true
    }
    
    fileprivate static func unregisterLimitedPowerHandler() {
        if BTPowerEvents.powerLoop == nil {
            return
        }

        CFRunLoopRemoveSource(
            CFRunLoopGetCurrent(),
            BTPowerEvents.powerLoop,
            CFRunLoopMode.defaultMode
            )
        BTPowerEvents.powerLoop = nil
    }

    fileprivate static func registerPercentChangedHandler() -> Bool {
        if BTPowerEvents.percentLoop != nil {
            return true
        }

        BTPowerEvents.percentLoop = IOPSCreatePercentChangeNotification(
            PercentChangeHandler,
            nil
            ).takeRetainedValue() as CFRunLoopSource?
        if BTPowerEvents.percentLoop == nil {
            return false
        }

        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            BTPowerEvents.percentLoop,
            CFRunLoopMode.defaultMode
            )
        let percent = BTPowerEvents.handleChargeHysteresis()
        //
        // In case charging to maximum was requested while the device was on
        // battery, enable it now if appropriate.
        //
        if BTPowerEvents.chargeMode == BTChargeMode.ToMaxLimit {
            if percent < BTPreferences.maxCharge {
                BTPowerState.enableCharging()
            }

            BTPowerEvents.chargeMode = BTChargeMode.Default
        }
        
        return true
    }

    fileprivate static func unregisterPercentChangedHandler() {
        if BTPowerEvents.percentLoop != nil {
            CFRunLoopRemoveSource(
                CFRunLoopGetCurrent(),
                BTPowerEvents.percentLoop,
                CFRunLoopMode.defaultMode
                )
            BTPowerEvents.percentLoop = nil
            //
            // Disable charging to not have micro-charges happening when
            // connecting to power.
            //
            BTPowerState.disableCharging()
        }
    }
    
    fileprivate static func handleChargeHysteresis() -> Int32 {
        assert(BTPowerEvents.percentLoop != nil)

        var percent: Int32 = 100
        let result = IOPSGetPercentRemaining(&percent, nil, nil)
        if result != kIOReturnSuccess {
            // FIXME: Handle error
            return 100;
        }
        //
        // The hysteresis does not apply when starting the daemon, as micro-charges
        // will already happen pre-boot and there is no point to not just charge all
        // the way to the maximum then.
        //
        if percent >= BTPreferences.maxCharge {
            if BTPowerEvents.chargeMode == BTChargeMode.Full {
                if (percent < 100) {
                    return percent
                }
                
                BTPowerEvents.chargeMode = BTChargeMode.Default
            }

            BTPowerState.disableCharging()
        } else if percent < BTPreferences.minCharge {
            BTPowerState.enableCharging()
        }
        
        return percent
    }

    fileprivate static func restoreDefaults() {
        // FIXME: Enable!
        BTPowerState.disableCharging()
        BTPowerState.enableExternalPower()
    }

    public static func start() -> Bool {
        let smcResult = SMCKit.start()
        if !smcResult {
            return false
        }

        if !SMCPowerKit.supported() {
            SMCKit.stop()
            return false
        }
        
        let registerResult = registerLimitedPowerHandler()
        if !registerResult {
            SMCKit.stop()
            return false
        }
        
        return true
    }
    
    public static func stop() {
        BTPowerEvents.unregisterLimitedPowerHandler()
        BTPowerEvents.unregisterPercentChangedHandler()
        BTPowerEvents.restoreDefaults()

        SMCKit.stop()
    }
    
    public static func chargeToMaximum() {
        //
        // When the percent loop is inactive, this currently means that the
        // device is not connected to power. In this case, do not disable
        // sleep to not drain the battery. Sleep will be disabled once power
        // is attached by the corresponding handler.
        //
        if BTPowerEvents.percentLoop == nil {
            BTPowerEvents.chargeMode = BTChargeMode.ToMaxLimit
            return
        }
        
        var percent: Int32 = 100
        let result = IOPSGetPercentRemaining(&percent, nil, nil)
        if result != kIOReturnSuccess {
            // FIXME: Handle error
            return;
        }

        if percent < BTPreferences.maxCharge {
            BTPowerState.enableCharging()
        }
    }
    
    public static func chargeToFull() {
        BTPowerEvents.chargeMode = BTChargeMode.Full
        if BTPowerEvents.percentLoop != nil {
            _ = BTPowerEvents.handleChargeHysteresis()
        }
    }
}
