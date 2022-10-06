//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

@objc internal protocol BTServiceCommProtocol {
    func getAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    )

    func getDaemonAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    )

    func getManageAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    )
}
