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
        BTAppXPCClient.askAuthorization() { (authData) -> Void in
            guard let authData = authData, authData.count == kAuthorizationExternalFormLength else {
                reply(nil)
                return
            }

            var extAuth = AuthorizationExternalForm()
            memcpy(&extAuth, authData.bytes, Int(kAuthorizationExternalFormLength))

            var auth: AuthorizationRef? = nil
            let status = AuthorizationCreateFromExternalForm(&extAuth, &auth)
            guard status == errSecSuccess, let auth = auth else {
                reply(nil)
                return
            }

            reply(auth)
        }
    }
}
