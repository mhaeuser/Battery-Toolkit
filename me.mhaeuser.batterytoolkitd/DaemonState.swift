/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import IOPMPrivate

internal struct BTDaemonState {
    @MainActor internal static func getState() -> [String: AnyObject] {
        let charging  = SMCPowerKit.isChargingEnabled()
        let connected = IOPSDrawingUnlimitedPower()
        let power     = SMCPowerKit.isPowerAdapterEnabled()
        let progress  = BTPowerEvents.getChargingProgress()
        let mode      = BTPowerEvents.chargeMode

        return [
            BTStateInfo.Keys.power: NSNumber(value: power),
            BTStateInfo.Keys.connected: NSNumber(value: connected),
            BTStateInfo.Keys.charging: NSNumber(value: charging),
            BTStateInfo.Keys.progress: NSNumber(value: progress.rawValue),
            BTStateInfo.Keys.chargingMode: NSNumber(value: mode.rawValue)
        ]
    }
}
