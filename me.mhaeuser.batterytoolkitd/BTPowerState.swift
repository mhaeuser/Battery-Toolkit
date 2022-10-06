//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

@MainActor
internal enum BTPowerState {
    private static var chargingDisabled = false
    private static var powerDisabled = false

    internal static func initSleepState() {
        let chargeDisabled = SmcComm.Power.isChargingDisabled()
        BTPowerState.chargingDisabled = chargeDisabled
        if !chargeDisabled {
            //
            // Sleep must always be disabled when charging is enabled.
            //
            GlobalSleep.disableSleep()
        }

        let powerDisabled = SmcComm.Power.isPowerAdapterDisabled()
        BTPowerState.powerDisabled = powerDisabled
        if powerDisabled {
            //
            // Sleep must be disabled when external power is disabled.
            //
            BTPowerState.disableAdapterSleep()
        }
    }

    internal static func adapterSleepPreferenceToggled() {
        //
        // If power is disabled, toggle sleep.
        //
        guard BTPowerState.powerDisabled else {
            return
        }

        if !BTSettings.adapterSleep {
            GlobalSleep.disableSleep()
        } else {
            GlobalSleep.restoreSleep()
        }
    }

    internal static func disableCharging() -> Bool {
        guard !BTPowerState.chargingDisabled else {
            return true
        }

        let success = SmcComm.Power.disableCharging()
        guard success else {
            os_log("Failed to disable charging")
            return false
        }

        GlobalSleep.restoreSleep()

        BTPowerState.chargingDisabled = true
        return true
    }

    internal static func enableCharging() -> Bool {
        guard BTPowerState.chargingDisabled else {
            return true
        }

        let result = SmcComm.Power.enableCharging()
        if !result {
            os_log("Failed to enable charging")
            return false
        }

        GlobalSleep.disableSleep()

        BTPowerState.chargingDisabled = false
        return true
    }

    internal static func disablePowerAdapter() -> Bool {
        guard !BTPowerState.powerDisabled else {
            return true
        }

        self.disableAdapterSleep()

        let success = SmcComm.Power.disablePowerAdapter()
        guard success else {
            os_log("Failed to disable power adapter")
            self.restoreAdapterSleep()
            return false
        }

        BTPowerState.powerDisabled = true
        return true
    }

    internal static func enablePowerAdapter() -> Bool {
        guard BTPowerState.powerDisabled else {
            return true
        }

        let success = SmcComm.Power.enablePowerAdapter()
        guard success else {
            os_log("Failed to enable power adapter")
            return false
        }

        self.restoreAdapterSleep()

        BTPowerState.powerDisabled = false
        return true
    }

    internal static func isChargingDisabled() -> Bool {
        return BTPowerState.chargingDisabled
    }

    internal static func isPowerAdapterDisabled() -> Bool {
        return BTPowerState.powerDisabled
    }

    private static func disableAdapterSleep() {
        if !BTSettings.adapterSleep {
            GlobalSleep.disableSleep()
        }
    }

    private static func restoreAdapterSleep() {
        if !BTSettings.adapterSleep {
            GlobalSleep.restoreSleep()
        }
    }
}
