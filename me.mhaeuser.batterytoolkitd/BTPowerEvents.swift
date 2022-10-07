//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import IOKit.ps
import IOPMPrivate
import os.log

/// Handler for power events. Automatically manages the battery charging state
// based on factors like
/// battery charging level and user inputs.
@MainActor
internal enum BTPowerEvents {
    /// Indicates whether an update is in progress.
    internal static var updating = false

    /// The current mode for battery charging.
    internal private(set) static var chargingMode =
        BTStateInfo.ChargingMode.standard

    /// Whether the system is drawing external power.
    internal private(set) static var unlimitedPower = false

    /// Whether the Limited Power notification has been created.
    private static var powerCreated = false

    /// Whether the Percent Change notification has been created
    private static var percentCreated = false

    internal static func start() -> BTError {
        let smcSuccess = SMCComm.start()
        guard smcSuccess else {
            return BTError.unknown
        }

        let supported = SMCComm.Power.supported()
        guard supported else {
            os_log("Machine is unsupported")
            SMCComm.stop()
            return BTError.unsupported
        }

        let registerSuccess = self.registerLimitedPowerHandler()
        guard registerSuccess else {
            SMCComm.stop()
            return BTError.unknown
        }

        return BTError.success
    }

    /// Stops the service as part of termination. Hence, not all acquired
    /// resources are released.
    internal static func exit() {
        if !BTPowerEvents.updating {
            self.restoreDefaults()
        }

        GlobalSleep.forceRestore()
    }

    /// Notification handler for changed settings.
    internal static func settingsChanged() {
        guard BTPowerEvents.percentCreated else {
            return
        }

        _ = self.handleChargeHysteresis()
    }

    /// Charge the battery to the configured maximum next time it is connected to
    /// external power and then disable charging.
    ///
    /// - Returns: Whether the operation was completed successfully.
    internal static func chargeToMaximum() -> Bool {
        BTPowerEvents.chargingMode = .toMaximum
        return self.enableBelowThresholdMode(threshold: BTSettings.maxCharge)
    }

    /// Disable battery charging.
    ///
    /// - Returns: Whether the operation was completed successfully.
    internal static func disableCharging() -> Bool {
        BTPowerEvents.chargingMode = .standard
        return BTPowerState.disableCharging()
    }

    /// Charge the battery to 100 % next time it is connected to external power.
    ///
    /// - Returns: Whether the operation was completed successfully.
    internal static func chargeToFull() -> Bool {
        BTPowerEvents.chargingMode = .toFull
        return self.enableBelowThresholdMode(threshold: 100)
    }

    /// Gets the battery charging progress.
    internal static func getChargingProgress() -> BTStateInfo.ChargingProgress {
        var percent: Int32 = 100
        let result = IOPSGetPercentRemaining(&percent, nil, nil)
        guard result == kIOReturnSuccess else {
            os_log("Failed to retrieve battery percent")
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

    /// Handler for the Limited Power notification.
    ///
    /// - Parameters:
    ///     - token: The registration token.
    private static func limitedPowerHandler(token _: Int32) {
        self.handleLimitedPower()
    }

    /// Handler for the Percent Change notification.
    ///
    /// - Parameters:
    ///     - token: The registration token.
    private static func percentChangeHandler(token _: Int32) {
        //
        // An unlucky dispatching order of LimitedPower and PercentChanged
        // events may cause this constraint to actually be violated.
        //
        guard BTPowerEvents.percentCreated else {
            return
        }

        _ = self.handleChargeHysteresis()
    }

    private static func registerLimitedPowerHandler() -> Bool {
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

        let success = BTDispatcher.registerLimitedPowerNotification(
            BTPowerEvents.limitedPowerHandler
        )
        guard success else {
            return false
        }

        self.handleLimitedPower()

        return true
    }

    private static func registerPercentChangedHandler() -> Bool {
        guard !BTPowerEvents.percentCreated else {
            return true
        }

        BTPowerEvents.percentCreated = BTDispatcher
            .registerPercentChangeNotification(
                BTPowerEvents.percentChangeHandler
            )
        guard BTPowerEvents.percentCreated else {
            return false
        }

        let percent = self.handleChargeHysteresis()
        //
        // In case charging to maximum or full were requested while the device
        // was on battery, enable it now if appropriate.
        //
        switch BTPowerEvents.chargingMode {
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
            return 100
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
            if BTPowerEvents.chargingMode != .toFull || percent >= 100 {
                //
                // Charging modes are reset once we disable charging.
                //
                BTPowerEvents.chargingMode = .standard
                _ = BTPowerState.disableCharging()
            }
        } else if percent < BTSettings.minCharge {
            _ = BTPowerState.enableCharging()
        }

        return percent
    }

    /// Returns whether the system is drawing external power.
    private static func drawingUnlimitedPower() -> Bool {
        //
        // macOS may falsely report drawing unlimited power when the power
        // adapter is actually disabled.
        //
        return !BTPowerState.isPowerAdapterDisabled() &&
            IOPSDrawingUnlimitedPower()
    }

    /// Adapts to changes to external power. If external power is connected,
    /// monitors changes to the battery charge level and reacts accordingly. If
    /// external power is disconnected, disables battery charging.
    private static func handleLimitedPower() {
        //
        // Immediately disable sleep to not interrupt the setup phase.
        //
        GlobalSleep.disable()

        let unlimitedPower = self.drawingUnlimitedPower()
        BTPowerEvents.unlimitedPower = unlimitedPower

        if unlimitedPower {
            let result = self.registerPercentChangedHandler()
            if !result {
                os_log("Failed to register percent changed handler")
                self.restoreDefaults()
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
        GlobalSleep.restore()
    }

    /// Restores the default platform power configuration. Battery charging and
    /// the power adapter are enabled. To ease debugging, this function has no
    /// effect when compiling with the DEBUG flag.
    private static func restoreDefaults() {
        //
        // Do not reset to defaults when debugging to not stress the batteries
        // of development machines.
        //
        #if !DEBUG
            _ = BTPowerState.enableCharging()
            _ = BTPowerState.enablePowerAdapter()
        #endif
    }

    /// Enables battery charging, if the battery charge level is below the
    /// threshold.
    ///
    /// - Parameters:
    ///     - threshold: The battery charge level threshold below which charging
    ///                  should be enabled.
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
}
