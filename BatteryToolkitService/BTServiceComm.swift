//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import ServiceManagement

internal final class BTServiceComm: NSObject, BTServiceCommProtocol {
    /// Cache a single Authorization to preserve the manage right.
    private var simpleAuth: SimpleAuthRef? = nil

    func getAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let simpleAuth = self.getSimpleAuth()
        guard let simpleAuth else {
            reply(nil)
            return
        }

        reply(SimpleAuth.toData(simpleAuth: simpleAuth))
    }

    func getDaemonAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let simpleAuth = self.getSimpleAuth()
        guard let simpleAuth else {
            reply(nil)
            return
        }

        let success = SimpleAuth.acquireInteractive(
            simpleAuth: simpleAuth,
            rightName: kSMRightModifySystemDaemons
        )
        guard success else {
            reply(nil)
            return
        }

        reply(SimpleAuth.toData(simpleAuth: simpleAuth))
    }

    func getManageAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let simpleAuth = self.getSimpleAuth()
        guard let simpleAuth else {
            reply(nil)
            return
        }

        let success = SimpleAuth.acquireInteractive(
            simpleAuth: simpleAuth,
            rightName: BTAuthorizationRights.manage
        )
        guard success else {
            reply(nil)
            return
        }

        reply(SimpleAuth.toData(simpleAuth: simpleAuth))
    }

    private func getSimpleAuth() -> SimpleAuthRef? {
        guard let simpleAuth = self.simpleAuth else {
            let simpleAuth = SimpleAuth.empty()
            self.simpleAuth = simpleAuth
            return simpleAuth
        }

        return simpleAuth
    }
}
