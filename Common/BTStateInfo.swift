//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTStateInfo {
    enum ChargingMode: UInt8 {
        case standard
        case toMaximum
        case toFull
    }

    enum ChargingProgress: UInt8 {
        case belowMax
        case belowFull
        case full
    }

    enum Keys {
        static let powerDisabled = "PowerDisabled"
        static let connected = "Connected"
        static let chargingDisabled = "ChargingDisabled"
        static let progress = "Progress"
        static let chargingMode = "Mode"
    }
}
