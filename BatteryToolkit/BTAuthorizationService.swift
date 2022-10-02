//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log

@MainActor
internal enum BTAuthorizationService {
    private static var manageAuthRef: AuthorizationRef? = nil

    internal static func empty(
        reply: @Sendable @escaping (AuthorizationRef?) -> Void
    ) {
        BTAppXPCClient.createEmptyAuthorization { authData in
            reply(BTAuthorization.fromData(authData: authData))
        }
    }

    internal static func daemonManagement(
        reply: @Sendable @escaping (AuthorizationRef?) -> Void
    ) {
        BTAppXPCClient.createDaemonAuthorization { authData in
            reply(BTAuthorization.fromData(authData: authData))
        }
    }

    private static func acquireManage(
        reply: @MainActor @Sendable @escaping (AuthorizationRef?) -> Void
    ) {
        BTAppXPCClient.createManageAuthorization { authData in
            let authRef = BTAuthorization.fromData(authData: authData)

            DispatchQueue.main.async {
                if authRef != nil {
                    if let authRef = BTAuthorizationService.manageAuthRef {
                        AuthorizationFree(authRef, [.destroyRights])
                    }

                    BTAuthorizationService.manageAuthRef = authRef
                }

                reply(authRef)
            }
        }
    }

    internal static func reacquireManage(
        reply: @MainActor @Sendable @escaping (AuthorizationRef?) -> Void
    ) {
        let authData = BTAuthorization.toData(
            authRef: BTAuthorizationService.manageAuthRef
        )
        guard let authData else {
            self.acquireManage(reply: reply)
            return
        }

        BTAppXPCClient.acquireManageAuthorization(authData: authData) { _ in
            DispatchQueue.main.async {
                reply(BTAuthorizationService.manageAuthRef)
            }
        }
    }

    internal static func manage(
        reply: @MainActor @Sendable @escaping (AuthorizationRef?) -> Void
    ) {
        guard let authRef = BTAuthorizationService.manageAuthRef else {
            self.acquireManage(reply: reply)
            return
        }

        reply(authRef)
    }
}
