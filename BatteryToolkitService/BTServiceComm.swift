//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import ServiceManagement

internal final class BTServiceComm: NSObject, BTServiceCommProtocol {
    private var authRef: AuthorizationRef? = nil

    func getAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let authRef = self.getAuthRef()
        reply(SimpleAuth.toData(authRef: authRef))
    }

    func getDaemonAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let authRef = self.getAuthRef()
        guard let authRef else {
            reply(nil)
            return
        }

        let success = SimpleAuth.acquireInteractive(
            authRef: authRef,
            rightName: kSMRightModifySystemDaemons
        )
        guard success else {
            reply(nil)
            return
        }

        reply(SimpleAuth.toData(authRef: authRef))
    }

    func getManageAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let authRef = self.getAuthRef()
        guard let authRef else {
            reply(nil)
            return
        }

        let success = SimpleAuth.acquireInteractive(
            authRef: authRef,
            rightName: BTAuthorizationRights.manage
        )
        guard success else {
            reply(nil)
            return
        }

        reply(SimpleAuth.toData(authRef: authRef))
    }

    deinit {
        guard let authRef = self.authRef else {
            return
        }
        //
        // Do not destroy rights, so if the service is quit due to resource
        // pressure, a password prompt may be avoided when it is relaunched.
        //
        AuthorizationFree(authRef, [])
    }

    private func getAuthRef() -> AuthorizationRef? {
        guard let authRef = self.authRef else {
            let authRef = SimpleAuth.empty()
            self.authRef = authRef
            return authRef
        }

        return authRef
    }
}
