/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

@MainActor
internal struct BTPowerState {
    private static var chargingDisabled = false
    private static var powerDisabled    = false

    internal static func initSleepState() {
        let chargeEnabled = SMCPowerKit.isChargingEnabled()
        BTPowerState.chargingDisabled = !chargeEnabled
        if chargeEnabled {
            //
            // Sleep must always be disabled when charging.
            //
            SleepKit.disableSleep()
        }
        
        let powerEnabled = SMCPowerKit.isPowerAdapterEnabled()
        BTPowerState.powerDisabled = !powerEnabled
        if !powerEnabled {
            //
            // Sleep must always be disabled when external power is disabled.
            //
            SleepKit.disableSleep()
        }
    }

    internal static func adapterSleepPreferenceToggled() {
        //
        // If power is disabled, toggle sleep.
        //
        if !BTPowerState.powerDisabled {
            return
        }

        if !BTSettings.adapterSleep {
            SleepKit.disableSleep()
        } else {
            SleepKit.restoreSleep()
        }
    }

    internal static func disableCharging() {
        if BTPowerState.chargingDisabled {
            return
        }

        let result = SMCPowerKit.disableCharging()
        if !result {
            os_log("Failed to disable charging")
            return
        }
        
        SleepKit.restoreSleep()
        
        BTPowerState.chargingDisabled = true
    }
    
    internal static func enableCharging() {
        if !BTPowerState.chargingDisabled {
            return
        }

        let result = SMCPowerKit.enableCharging()
        if !result {
            os_log("Failed to enable charging")
            return
        }
        
        SleepKit.disableSleep()
        
        BTPowerState.chargingDisabled = false
    }

    internal static func disablePowerAdapter() {
        if BTPowerState.powerDisabled {
            return
        }

        if !BTSettings.adapterSleep {
            SleepKit.disableSleep()
        }

        let result = SMCPowerKit.disablePowerAdapter()
        if !result {
            if !BTSettings.adapterSleep {
                SleepKit.restoreSleep()
            }

            os_log("Failed to disable power adapter")
            return
        }

        BTPowerState.powerDisabled = true
    }

    internal static func enablePowerAdapter() {
        if !BTPowerState.powerDisabled {
            return
        }

        let result = SMCPowerKit.enablePowerAdapter()
        if !result {
            os_log("Failed to enable power adapter")
            return
        }
        
        if !BTSettings.adapterSleep {
            SleepKit.restoreSleep()
        }

        BTPowerState.powerDisabled = false
    }
}
