//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
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

        SMCComm.MagSafe.prepare()

        if BTSettings.magSafeSync {
            self.syncMagSafeState()
        }
    }

    static func getPercentRemaining() -> (UInt8, Bool, Bool) {
        return IOPSPrivate.GetPercentRemaining() ?? (100, false, false)
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

    static func syncMagSafeStatePowerEnabled(percent: UInt8) {
        assert(BTSettings.magSafeSync)
        assert(!self.powerDisabled)

        if percent == 100 {
            _ = SMCComm.MagSafe.setGreen()
        } else if self.chargingDisabled {
            _ = SMCComm.MagSafe.setOrange()
        } else {
            _ = SMCComm.MagSafe.setOrangeSlowBlink()
        }
    }

    static func syncMagSafeState() {
        assert(BTSettings.magSafeSync)

        if self.powerDisabled {
            _ = SMCComm.MagSafe.setOff()
        } else {
            let (percent, _, _) = self.getPercentRemaining()
            self.syncMagSafeStatePowerEnabled(percent: percent)
        }
    }

    static func magSafeSyncSettingToggled() {
        if BTSettings.magSafeSync {
            self.syncMagSafeState()
        } else {
            _ = SMCComm.MagSafe.setSystem()
        }
    }

    static func disableCharging(percent: UInt8) -> Bool {
        guard !self.chargingDisabled else {
            return true
        }

        let success = SMCComm.Power.disableCharging()
        guard success else {
            os_log("Failed to disable charging")
            return false
        }

        self.chargingDisabled = true

        if BTSettings.magSafeSync {
            BTPowerState.syncMagSafeStatePowerEnabled(percent: percent)
        }

        GlobalSleep.restore()

        return true
    }

    static func enableCharging(percent: UInt8) -> Bool {
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

        if BTSettings.magSafeSync {
            BTPowerState.syncMagSafeStatePowerEnabled(percent: percent)
        }

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

        if BTSettings.magSafeSync {
            _ = SMCComm.MagSafe.setOff()
        }

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

        self.powerDisabled = false

        if BTSettings.magSafeSync {
            let (percent, _, _) = self.getPercentRemaining()
            BTPowerState.syncMagSafeStatePowerEnabled(percent: percent)
        }

        self.restoreAdapterSleep()

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
