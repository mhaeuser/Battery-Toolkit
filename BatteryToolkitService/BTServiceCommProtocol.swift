//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

@objc internal protocol BTServiceCommProtocol {
    func createEmptyAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    )

    func createDaemonAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    )

    func createManageAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    )
}
