/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import ServiceManagement
import BTPreprocessor

internal struct BTAuthorization {
    private static func toReply(authRef: AuthorizationRef?, reply: @Sendable @escaping (NSData?) -> Void) {
        guard let authRef = authRef else {
            reply(nil)
            return
        }

        reply(toData(authRef: authRef))
    }

    internal static func empty() -> AuthorizationRef? {
        var authRef: AuthorizationRef? = nil
        let status = AuthorizationCreate(nil, nil, [], &authRef)
        guard status == errAuthorizationSuccess else {
            return nil
        }

        return authRef
    }

    internal static func empty(reply: @Sendable @escaping (NSData?) -> Void) {
        toReply(authRef: empty(), reply: reply)
    }

    internal static func interactive(rightName: String) -> AuthorizationRef? {
        let authRef = empty()
        guard let authRef = authRef else {
            return nil
        }

        var item = AuthorizationItem(
            name: rightName,
            valueLength: 0,
            value: nil,
            flags: 0
            )
        var rights = AuthorizationRights(count: 1, items: &item)

        let status = AuthorizationCopyRights(
            authRef,
            &rights,
            nil,
            [.interactionAllowed, .extendRights, .preAuthorize],
            nil
            )
        guard status == errAuthorizationSuccess else {
            return nil
        }

        return authRef
    }

    internal static func interactive(rightName: String, reply: @Sendable @escaping (NSData?) -> Void) {
        toReply(authRef: interactive(rightName: rightName), reply: reply)
    }

    private static func toData(authRef: AuthorizationRef) -> NSData? {
        var extAuth = AuthorizationExternalForm()
        let status  = AuthorizationMakeExternalForm(authRef, &extAuth)
        guard status == errAuthorizationSuccess else {
            return nil
        }

        return NSData(
            bytes: &extAuth.bytes,
            length: Int(kAuthorizationExternalFormLength)
            )
    }

    internal static func fromData(authData: NSData?) -> AuthorizationRef? {
        guard let authData = authData, authData.count == kAuthorizationExternalFormLength else {
            return nil
        }

        var extAuth = AuthorizationExternalForm()
        memcpy(&extAuth, authData.bytes, Int(kAuthorizationExternalFormLength))

        var authRef: AuthorizationRef? = nil
        let status = AuthorizationCreateFromExternalForm(&extAuth, &authRef)
        guard status == errSecSuccess, let authRef = authRef else {
            return nil
        }

        return authRef
    }
}
