//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log

@MainActor
internal enum BTAuthorizationService {
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

    internal static func manage(
        reply: @Sendable @escaping (AuthorizationRef?) -> Void
    ) {
        BTAppXPCClient.createManageAuthorization { authData in
            reply(BTAuthorization.fromData(authData: authData))
        }
    }
}
