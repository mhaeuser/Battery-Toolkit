//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log
import ServiceManagement

public enum SimpleAuth {
    static func empty() -> AuthorizationRef? {
        var authRef: AuthorizationRef? = nil
        let status = AuthorizationCreate(nil, nil, [], &authRef)
        guard status == errAuthorizationSuccess else {
            return nil
        }

        return authRef
    }

    static func acquireInteractive(
        authRef: AuthorizationRef,
        rightName: String
    ) -> Bool {
        return self.copyRight(
            authRef: authRef,
            rightName: rightName,
            flags: [.interactionAllowed, .extendRights, .preAuthorize]
        )
    }

    static func checkRight(
        authRef: AuthorizationRef,
        rightName: String
    ) -> Bool {
        return self.copyRight(
            authRef: authRef,
            rightName: rightName,
            flags: [.destroyRights]
        )
    }

    static func duplicateRight(
        rightName: String,
        templateName: String,
        comment: String,
        timeout: Int
    ) -> OSStatus {
        let authRef = self.empty()
        guard let authRef else {
            return errAuthorizationInternal
        }

        var adminRightDef: CFDictionary? = nil
        let getStatus = AuthorizationRightGet(
            templateName,
            &adminRightDef
        )
        guard
            getStatus == errSecSuccess,
            var adminRightDef = adminRightDef as? [CFString: Any]
        else {
            return errAuthorizationInternal
        }

        adminRightDef[kAuthorizationComment as CFString] = comment as CFString
        adminRightDef["timeout" as CFString] = timeout as CFNumber

        let status = AuthorizationRightSet(
            authRef,
            rightName,
            adminRightDef as CFDictionary,
            nil,
            nil,
            nil
        )

        AuthorizationFree(authRef, [.destroyRights])

        return status
    }

    static func removeRight(rightName: String) -> OSStatus {
        let authRef = self.empty()
        guard let authRef else {
            return errAuthorizationInternal
        }

        let status = AuthorizationRightRemove(authRef, rightName)

        AuthorizationFree(authRef, [.destroyRights])

        return status
    }

    static func toData(authRef: AuthorizationRef) -> Data? {
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

    static func fromData(authData: Data?) -> AuthorizationRef? {
        guard
            let authData,
            authData.count == kAuthorizationExternalFormLength
        else {
            return nil
        }

        var extAuth = AuthorizationExternalForm()
        withUnsafeMutableBytes(of: &extAuth) { (extBuf) -> Void in
            authData.copyBytes(to: extBuf)
        }

        var authRef: AuthorizationRef? = nil
        let status = AuthorizationCreateFromExternalForm(&extAuth, &authRef)
        guard status == errSecSuccess, let authRef else {
            return nil
        }

        return authRef
    }

    private static func copyRight(
        authRef: AuthorizationRef,
        rightName: String,
        flags: AuthorizationFlags
    ) -> Bool {
        return rightName.withCString { rightName in
            var item = AuthorizationItem(
                name: rightName,
                valueLength: 0,
                value: nil,
                flags: 0
            )

            return withUnsafeMutablePointer(to: &item) { item in
                var rights = AuthorizationRights(count: 1, items: item)

                let status = AuthorizationCopyRights(
                    authRef,
                    &rights,
                    nil,
                    flags,
                    nil
                )
                return status == errAuthorizationSuccess
            }
        }
    }
}
