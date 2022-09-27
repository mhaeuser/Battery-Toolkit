/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import IOPMPrivate

internal struct BTDaemonState {
    @MainActor internal static func getState() -> [String: AnyObject] {
        let chargingDisabled = BTPowerState.isChargingDisabled()
        let connected        = BTPowerEvents.unlimitedPower
        let powerDisabled    = BTPowerState.isPowerAdapterDisabled()
        let progress         = BTPowerEvents.getChargingProgress()
        let mode             = BTPowerEvents.chargingMode

        return [
            BTStateInfo.Keys.powerDisabled: NSNumber(value: powerDisabled),
            BTStateInfo.Keys.connected: NSNumber(value: connected),
            BTStateInfo.Keys.chargingDisabled: NSNumber(value: chargingDisabled),
            BTStateInfo.Keys.progress: NSNumber(value: progress.rawValue),
            BTStateInfo.Keys.chargingMode: NSNumber(value: mode.rawValue)
        ]
    }
}
