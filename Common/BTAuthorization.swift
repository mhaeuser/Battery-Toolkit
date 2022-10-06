//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log
import ServiceManagement

internal enum BTAuthorization {
    internal static func empty() -> AuthorizationRef? {
        var authRef: AuthorizationRef? = nil
        let status = AuthorizationCreate(nil, nil, [], &authRef)
        guard status == errAuthorizationSuccess else {
            return nil
        }

        return authRef
    }

    private static func copyRight(
        authRef: AuthorizationRef,
        rightName: String,
        flags: AuthorizationFlags
    ) -> Bool {
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
            flags,
            nil
        )
        return status == errAuthorizationSuccess
    }

    internal static func interactive(rightName: String) -> AuthorizationRef? {
        let authRef = self.empty()
        guard let authRef else {
            return nil
        }

        let success = self.copyRight(
            authRef: authRef,
            rightName: rightName,
            flags: [.interactionAllowed, .extendRights, .preAuthorize]
        )
        guard success else {
            AuthorizationFree(authRef, [.destroyRights])
            return nil
        }

        return authRef
    }

    internal static func acquireInteractive(
        authRef: AuthorizationRef,
        rightName: String
    ) -> Bool {
        return self.copyRight(
            authRef: authRef,
            rightName: rightName,
            flags: [.interactionAllowed, .extendRights, .preAuthorize]
        )
    }

    internal static func checkRight(
        authRef: AuthorizationRef,
        rightName: String
    ) -> Bool {
        return self.copyRight(
            authRef: authRef,
            rightName: rightName,
            flags: [.destroyRights]
        )
    }

    internal static func duplicateRight(
        rightName: String,
        templateName: String
    ) -> OSStatus {
        let authRef = self.empty()
        guard let authRef else {
            return errAuthorizationInternal
        }

        let status = AuthorizationRightSet(
            authRef,
            rightName,
            templateName as CFString,
            nil,
            nil,
            nil
        )

        AuthorizationFree(authRef, [.destroyRights])

        return status
    }

    internal static func removeRight(rightName: String) -> OSStatus {
        let authRef = self.empty()
        guard let authRef else {
            return errAuthorizationInternal
        }

        let status = AuthorizationRightRemove(authRef, rightName)

        AuthorizationFree(authRef, [.destroyRights])

        return status
    }

    internal static func toData(authRef: AuthorizationRef?) -> Data? {
        guard let authRef else {
            return nil
        }

        var extAuth = AuthorizationExternalForm()
        let status = AuthorizationMakeExternalForm(authRef, &extAuth)
        guard status == errAuthorizationSuccess else {
            return nil
        }

        return Data(
            bytes: &extAuth.bytes,
            count: Int(kAuthorizationExternalFormLength)
        )
    }

    internal static func fromData(authData: Data?) -> AuthorizationRef? {
        guard
            let authData,
            authData.count == kAuthorizationExternalFormLength
        else {
            return nil
        }

        var extAuth = AuthorizationExternalForm()
        _ = withUnsafeMutableBytes(of: &extAuth) { extBuf in
            authData.copyBytes(to: extBuf)
        }

        var authRef: AuthorizationRef? = nil
        let status = AuthorizationCreateFromExternalForm(&extAuth, &authRef)
        guard status == errSecSuccess, let authRef else {
            return nil
        }

        return authRef
    }
}
