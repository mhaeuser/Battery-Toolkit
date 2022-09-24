/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import BTPreprocessor

@MainActor
internal struct BTAuthorizationService {
    private static var manageAuthRef: AuthorizationRef? = nil

    internal static func empty(reply: @Sendable @escaping (AuthorizationRef?) -> Void) {
        BTAppXPCClient.createEmptyAuthorization { (authData) -> Void in
            reply(BTAuthorization.fromData(authData: authData))
        }
    }

    internal static func daemonManagement(reply: @Sendable @escaping (AuthorizationRef?) -> Void) {
        BTAppXPCClient.createDaemonAuthorization { (authData) -> Void in
            reply(BTAuthorization.fromData(authData: authData))
        }
    }

    internal static func manage(reply: @MainActor @Sendable @escaping (AuthorizationRef?) -> Void) {
        let authData = BTAuthorization.toData(
            authRef: BTAuthorizationService.manageAuthRef
            )
        guard let authData = authData else {
            BTAppXPCClient.createManageAuthorization { authData in
                let authRef = BTAuthorization.fromData(authData: authData)

                DispatchQueue.main.async {
                    if authRef != nil {
                        BTAuthorizationService.manageAuthRef = authRef
                    }

                    reply(authRef)
                }
            }

            return
        }

        BTAppXPCClient.acquireManageAuthorization(authData: authData) { _ in
            DispatchQueue.main.async {
                reply(BTAuthorizationService.manageAuthRef)
            }
        }
    }
}
