//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal extension BTDaemonManagement {
    enum Status: UInt8 {
        case notRegistered = 0
        case enabled = 1
        case requiresApproval = 2
        case requiresUpgrade = 3
    }
}
