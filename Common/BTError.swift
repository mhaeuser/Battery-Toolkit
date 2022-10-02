//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTError: UInt8, Sendable {
    case success
    case unknown
    case notAuthorized
    case commFailed
    case malformedData
    case unsupported

    init(fromBool: Bool) {
        self = fromBool ? .success : .unknown
    }
}
