//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import IOKit.ps
import os.log

@MainActor
internal enum BTPowerEvents {
    static var updating = false

    private(set) static var chargingMode = BTStateInfo.ChargingMode.standard
    private(set) static var unlimitedPower = false

    private static var powerCreated = false
    private static var percentCreated = false

    static func start() throws {
        let smcSuccess = SMCComm.start()
        guard smcSuccess else {
            throw BTError.unknown
        }

        let supported = SMCComm.Power.supported()
        guard supported else {
            os_log("Machine is unsupported")
            SMCComm.stop()
            throw BTError.unsupported
        }

        let registerSuccess = self.registerLimitedPowerHandler()
        guard registerSuccess else {
            SMCComm.stop()
            throw BTError.unknown
        }
    }

    private static func restoreState() {
        //
        // If the daemon is being updated, don't restore the default platform
        // power state.
        //
        if !self.updating {
            self.restoreDefaults()
        }

        GlobalSleep.forceRestore()
        //
        // Don't free remaining resources, as we will exit anyway.
        //
    }
    
    static func exit() {
        guard self.powerCreated else {
            return
        }

        self.restoreState()
    }
    
    static func stop() {
        assert(self.powerCreated)

        self.unregisterLimitedPowerHandler()
        self.unregisterPercentChangedHandler()
        self.restoreState()
        SMCComm.stop()
    }

    static func wakeFromSleep() {
        //
        // Immediately disable sleep to not interrupt the setup phase.
        //
        GlobalSleep.disable()
        
        assert(self.powerCreated)

        BTPowerState.refreshState()

        if self.percentCreated {
            _ = self.handleChargeHysteresis()
        }

        self.handleLimitedPowerGuarded()
        //
        // Restore sleep from the setup phase.
        //
        GlobalSleep.restore()
    }

    static func settingsChanged() {
        guard self.percentCreated else {
            return
        }

        _ = self.handleChargeHysteresis()
    }

    static func chargeToLimit() -> Bool {
        self.chargingMode = .toLimit
        return self.enableBelowLimitMode(limit: BTSettings.maxCharge)
    }

    static func disableCharging(percent: UInt8) -> Bool {
        self.chargingMode = .standard
        return BTPowerState.disableCharging(percent: percent)
    }

    static func disableCharging() -> Bool {
        let (percent, _, _) = BTPowerState.getPercentRemaining()
        return self.disableCharging(percent: percent)
    }

    static func chargeToFull() -> Bool {
        self.chargingMode = .toFull
        return self.enableBelowLimitMode(limit: 100)
    }

    static func getChargingProgress() -> BTStateInfo.ChargingProgress {
        guard let (percent, _, _) = IOPSPrivate.GetPercentRemaining() else {
            return .full
        }

        if percent < BTSettings.maxCharge {
            return .belowMax
        }

        if percent < 100 {
            return .belowFull
        }

        return .full
    }

    private static func limitedPowerHandler(token _: Int32) {
        //
        // An unlucky dispatching order of LimitedPower and PercentChanged
        // events may cause this constraint to actually be violated.
        //
        guard self.powerCreated else {
            return
        }

        self.handleLimitedPower()
    }

    private static func percentChangeHandler(token _: Int32) {
        //
        // An unlucky dispatching order of LimitedPower and PercentChanged
        // events may cause this constraint to actually be violated.
        //
        guard self.percentCreated else {
            return
        }

        _ = self.handleChargeHysteresis()
    }

    private static func registerLimitedPowerHandler() -> Bool {
        guard !self.powerCreated else {
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
        BTPowerState.initState()

        self.powerCreated = BTDispatcher.registerLimitedPowerNotification { token in
            self.limitedPowerHandler(token: token)
        }
        guard self.powerCreated else {
            return false
        }

        self.handleLimitedPower()

        return true
    }

    private static func unregisterLimitedPowerHandler() {
        BTDispatcher.unregisterLimitedPowerNotification()
        self.powerCreated = false
    }

    private static func registerPercentChangedHandler() -> Bool {
        if !self.percentCreated {
            self.percentCreated = BTDispatcher.registerPercentChangeNotification { token in
                self.percentChangeHandler(token: token)
            }
            guard self.percentCreated else {
                return false
            }
        }

        let percent = self.handleChargeHysteresis()
        //
        // In case charging to limit or full were requested while the device
        // was on battery, enable it now if appropriate.
        //
        switch self.chargingMode {
        case .toLimit:
            if percent < BTSettings.maxCharge {
                _ = BTPowerState.enableCharging(percent: percent)
            }

        case .toFull:
            if percent < 100 {
                _ = BTPowerState.enableCharging(percent: percent)
            }

        case .standard:
            break
        }

        return true
    }

    private static func unregisterPercentChangedHandler() {
        guard self.percentCreated else {
            return
        }

        BTDispatcher.unregisterPercentChangeNotification()
        self.percentCreated = false
    }

    private static func handleChargeHysteresis() -> UInt8 {
        assert(self.percentCreated)

        guard let (percent, _, _) = IOPSPrivate.GetPercentRemaining() else {
            return 100
        }
        //
        // The hysteresis does not apply when starting the daemon, as
        // micro-charges will already happen pre-boot and there is no point to
        // not just charge all the way to the limit then.
        //
        if percent >= BTSettings.maxCharge {
            //
            // Do not disable charging till 100 percent are reached when
            // charging to full was requested. Charging to limit is handled
            // implicitly, as it only forces charging in [min, max).
            //
            if self.chargingMode != .toFull || percent >= 100 {
                //
                // Charging modes are reset once we disable charging.
                //
                _ = BTPowerEvents.disableCharging(percent: percent)
            }
        } else if percent < BTSettings.minCharge {
            _ = BTPowerState.enableCharging(percent: percent)
        }

        return percent
    }

    private static func drawingUnlimitedPower() -> Bool {
        //
        // macOS may falsely report drawing unlimited power when the power
        // adapter is actually disabled.
        //
        return !BTPowerState.isPowerAdapterDisabled() &&
            IOPSPrivate.DrawingUnlimitedPower()
    }

    private static func handleLimitedPowerGuarded() {
        assert(self.powerCreated)

        let unlimitedPower = self.drawingUnlimitedPower()
        self.unlimitedPower = unlimitedPower

        if unlimitedPower {
            let success = self.registerPercentChangedHandler()
            if !success {
                os_log("Failed to register percent changed handler")
                self.restoreDefaults()
            }
        } else {
            self.unregisterPercentChangedHandler()
            //
            // Disable charging to not have micro-charges happening when
            // connecting to power.
            //
            _ = BTPowerEvents.disableCharging()
        }
    }

    private static func handleLimitedPower() {
        //
        // Immediately disable sleep to not interrupt the setup phase.
        //
        GlobalSleep.disable()

        self.handleLimitedPowerGuarded()
        //
        // Restore sleep from the setup phase.
        //
        GlobalSleep.restore()
    }

    private static func restoreDefaults() {
        //
        // Do not reset to defaults when debugging to not stress the batteries
        // of development machines.
        //
        #if !DEBUG
            let (percent, _, _) = BTPowerState.getPercentRemaining()
            _ = BTPowerState.enableCharging(percent: percent)
            _ = BTPowerState.enablePowerAdapter()
        #endif
        if BTSettings.magSafeSync {
            _ = SMCComm.MagSafe.setSystem()
        }
    }

    private static func enableBelowLimitMode(limit: UInt8) -> Bool {
        //
        // When the percent loop is inactive, this currently means that the
        // device is not connected to power. In this case, do not enable
        // charging to not disable sleep. The charging mode will be handled by
        // power source handler when power is connected.
        //
        guard self.percentCreated else {
            return true
        }

        guard let (percent, _, _) = IOPSPrivate.GetPercentRemaining() else {
            return false
        }

        if percent < limit {
            return BTPowerState.enableCharging(percent: percent)
        }

        return true
    }
}
