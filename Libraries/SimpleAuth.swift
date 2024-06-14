//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log
import ServiceManagement

/// Wrapper class for reference-counted authorization references.
public final class SimpleAuthRef {
    let authRef: AuthorizationRef

    init(fromRef authRef: AuthorizationRef) {
        self.authRef = authRef
    }

    convenience init?(fromRef authRef: AuthorizationRef?) {
        guard let authRef else {
            return nil
        }

        self.init(fromRef: authRef)
    }

    deinit {
        AuthorizationFree(self.authRef, [])
    }
}

public enum SimpleAuth {
    static func empty() -> SimpleAuthRef? {
        var authRef: AuthorizationRef? = nil
        let status = AuthorizationCreate(nil, nil, [], &authRef)
        guard status == errAuthorizationSuccess else {
            return nil
        }

        return SimpleAuthRef(fromRef: authRef)
    }

    static func acquireInteractive(
        simpleAuth: SimpleAuthRef,
        rightName: String
    ) -> Bool {
        return self.copyRight(
            simpleAuth: simpleAuth,
            rightName: rightName,
            flags: [.interactionAllowed, .extendRights, .preAuthorize]
        )
    }

    static func checkRight(
        simpleAuth: SimpleAuthRef,
        rightName: String
    ) -> Bool {
        return self.copyRight(
            simpleAuth: simpleAuth,
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
        let simpleAuth = self.empty()
        guard let simpleAuth else {
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

        return AuthorizationRightSet(
            simpleAuth.authRef,
            rightName,
            adminRightDef as CFDictionary,
            nil,
            nil,
            nil
        )
    }

    static func removeRight(rightName: String) -> OSStatus {
        let simpleAuth = self.empty()
        guard let simpleAuth else {
            return errAuthorizationInternal
        }

        return AuthorizationRightRemove(simpleAuth.authRef, rightName)
    }

    static func toData(simpleAuth: SimpleAuthRef) -> Data? {
        var extAuth = AuthorizationExternalForm()
        let status = AuthorizationMakeExternalForm(simpleAuth.authRef, &extAuth)
        guard status == errAuthorizationSuccess else {
            return nil
        }

        return Data(
            bytes: &extAuth.bytes,
            count: Int(kAuthorizationExternalFormLength)
        )
    }

    static func fromData(authData: Data) -> SimpleAuthRef? {
        guard authData.count == kAuthorizationExternalFormLength else {
            return nil
        }

        var extAuth = AuthorizationExternalForm()
        _ = withUnsafeMutableBytes(of: &extAuth) { extBuf in
            authData.copyBytes(to: extBuf)
        }

        var authRef: AuthorizationRef? = nil
        let status = AuthorizationCreateFromExternalForm(&extAuth, &authRef)
        guard status == errSecSuccess else {
            return nil
        }

        return SimpleAuthRef(fromRef: authRef)
    }

    static func fromData(authData: Data?) -> SimpleAuthRef? {
        guard let authData else {
            return nil
        }

        return self.fromData(authData: authData)
    }

    private static func copyRight(
        simpleAuth: SimpleAuthRef,
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
                    simpleAuth.authRef,
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
