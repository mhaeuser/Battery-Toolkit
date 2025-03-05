//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTStateInfo {
    enum ChargingMode: UInt8 {
        case standard = 0
        case toLimit = 1
        case toFull = 2
    }

    enum ChargingProgress: UInt8 {
        case belowMax = 0
        case belowFull = 1
        case full = 2
    }

    enum Keys {
        static let enabled = "Enabled"
        static let powerDisabled = "PowerDisabled"
        static let connected = "Connected"
        static let chargingDisabled = "ChargingDisabled"
        static let progress = "Progress"
        static let chargingMode = "Mode"
        static let maxCharge = "MaxCharge"
    }
}
