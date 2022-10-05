//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import ServiceManagement

internal final class BTServiceComm: NSObject, BTServiceCommProtocol {
    func createEmptyAuthorization(
        reply: @Sendable @escaping (NSData?) -> Void
    ) {
        BTAuthorization.empty(reply: reply)
    }

    func createDaemonAuthorization(
        reply: @Sendable @escaping (NSData?) -> Void
    ) {
        BTAuthorization.interactive(
            rightName: kSMRightModifySystemDaemons,
            reply: reply
        )
    }

    func createManageAuthorization(
        reply: @Sendable @escaping (NSData?) -> Void
    ) {
        BTAuthorization.interactive(
            rightName: BTAuthorizationRights.manage,
            reply: reply
        )
    }
}
