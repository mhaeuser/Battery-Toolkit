/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import BTPreprocessor

@MainActor
internal struct BTAuthorizationService {
    internal static func createEmptyAuthorization(reply: @Sendable @escaping (AuthorizationRef?) -> Void) {
        BTAppXPCClient.createEmptyAuthorization { (authData) -> Void in
            reply(BTAuthorization.fromData(authData: authData))
        }
    }

    internal static func createDaemonAuthorization(reply: @Sendable @escaping (AuthorizationRef?) -> Void) {
        BTAppXPCClient.createDaemonAuthorization { (authData) -> Void in
            reply(BTAuthorization.fromData(authData: authData))
        }
    }
}
