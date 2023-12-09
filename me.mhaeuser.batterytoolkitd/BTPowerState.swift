//
// Copyright (C) 2022 - 2023 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

@MainActor
internal enum BTPowerState {
    private static var chargingDisabled = false
    private static var powerDisabled = false

    static func initState() {
        let chargingDisabled = SMCComm.Power.isChargingDisabled()
        self.chargingDisabled = chargingDisabled
        if !chargingDisabled {
            //
            // Sleep must always be disabled when charging is enabled.
            //
            GlobalSleep.disable()
        }

        let powerDisabled = SMCComm.Power.isPowerAdapterDisabled()
        self.powerDisabled = powerDisabled
        if powerDisabled {
            //
            // Sleep must be disabled when external power is disabled.
            //
            self.disableAdapterSleep()
        }
    }

    static func adapterSleepSettingToggled() {
        //
        // If power is disabled, toggle sleep.
        //
        guard self.powerDisabled else {
            return
        }

        if !BTSettings.adapterSleep {
            GlobalSleep.disable()
        } else {
            GlobalSleep.restore()
        }
    }

    static func disableCharging() -> Bool {
        guard !self.chargingDisabled else {
            return true
        }

        let success = SMCComm.Power.disableCharging()
        guard success else {
            os_log("Failed to disable charging")
            return false
        }

        GlobalSleep.restore()

        self.chargingDisabled = true
        return true
    }

    static func enableCharging() -> Bool {
        guard self.chargingDisabled else {
            return true
        }

        let success = SMCComm.Power.enableCharging()
        if !success {
            os_log("Failed to enable charging")
            return false
        }

        GlobalSleep.disable()

        self.chargingDisabled = false
        return true
    }

    static func disablePowerAdapter() -> Bool {
        guard !self.powerDisabled else {
            return true
        }

        self.disableAdapterSleep()

        let success = SMCComm.Power.disablePowerAdapter()
        guard success else {
            os_log("Failed to disable power adapter")
            self.restoreAdapterSleep()
            return false
        }

        BTPowerEvents.powerAdapterStateChanged()

        self.powerDisabled = true
        return true
    }

    static func enablePowerAdapter() -> Bool {
        guard self.powerDisabled else {
            return true
        }

        let success = SMCComm.Power.enablePowerAdapter()
        guard success else {
            os_log("Failed to enable power adapter")
            return false
        }

        BTPowerEvents.powerAdapterStateChanged()

        self.restoreAdapterSleep()

        self.powerDisabled = false
        return true
    }

    static func isChargingDisabled() -> Bool {
        return self.chargingDisabled
    }

    static func isPowerAdapterDisabled() -> Bool {
        return self.powerDisabled
    }

    private static func disableAdapterSleep() {
        if !BTSettings.adapterSleep {
            GlobalSleep.disable()
        }
    }

    private static func restoreAdapterSleep() {
        if !BTSettings.adapterSleep {
            GlobalSleep.restore()
        }
    }
}
