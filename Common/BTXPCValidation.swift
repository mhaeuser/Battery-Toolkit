//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import NSXPCConnectionAuditToken
import os.log
import SecCodeEx

internal enum BTXPCValidation {
    static func protectService(connection: NSXPCConnection) {
        if #available(macOS 13.0, *) {
            connection.setCodeSigningRequirement(
                requirementsTextFromId(identifier: BT_SERVICE_NAME)
            )
        }
    }

    static func protectDaemon(connection: NSXPCConnection) {
        if #available(macOS 13.0, *) {
            connection.setCodeSigningRequirement(
                requirementsTextFromId(identifier: BT_DAEMON_NAME)
            )
        }
    }

    static func isValidClient(connection: NSXPCConnection) -> Bool {
        var token = connection.auditToken
        let tokenData = Data(
            bytes: &token,
            count: MemoryLayout.size(ofValue: token)
        )
        let attributes = [kSecGuestAttributeAudit: tokenData]

        var code: SecCode? = nil
        let codeStatus = SecCodeCopyGuestWithAttributes(
            nil,
            attributes as CFDictionary,
            [],
            &code
        )
        guard codeStatus == errSecSuccess, let code else {
            return false
        }

        guard self.verifyCsStatus(code: code) else {
            return false
        }

        let requirementText = self
            .requirementsTextFromId(identifier: BT_APP_NAME)
        if #available(macOS 13.0, *) {
            connection.setCodeSigningRequirement(requirementText)
            return true
        } else {
            var requirement: SecRequirement? = nil
            let reqStatus = SecRequirementCreateWithString(
                requirementText as CFString,
                [],
                &requirement
            )
            guard reqStatus == errSecSuccess, let requirement else {
                return false
            }

            let validStatus = SecCodeCheckValidity(
                code,
                [
                    .enforceRevocationChecks,
                    SecCSFlags(rawValue: kSecCSRestrictSidebandData),
                    SecCSFlags(rawValue: kSecCSStrictValidate),
                ],
                requirement
            )
            return validStatus == errSecSuccess
        }
    }

    private static func verifyCsStatus(code: SecCode) -> Bool {
        var signInfo: CFDictionary? = nil
        let infoStatus = SecCodeCopySigningInformationDynamic(
            code,
            [SecCSFlags(rawValue: kSecCSDynamicInformation)],
            &signInfo
        )
        guard infoStatus == errSecSuccess else {
            os_log("Failed to retrieve signing information")
            return false
        }

        guard let signInfo = signInfo as? [String: AnyObject] else {
            os_log("Signing information is nil")
            return false
        }

        guard
            let signStatus =
            signInfo[kSecCodeInfoStatus as String] as? UInt32
        else {
            os_log("Failed to retrieve signature status")
            return false
        }

        let codeStatus = SecCodeStatus(rawValue: signStatus)
        //
        // REF: https://blog.obdev.at/what-we-have-learned-from-a-vulnerability/index.html
        // valid:             Enforce a valid in-memory CS status.
        // hard, kill:        Disallow late loading of (malicious) code.
        // restrict:          Disallow unrestricted DTrace.
        // enforcement:       Enforce code signing for all executable memory.
        // libraryValidation: Disallow loading of third-party libraries.
        // runtime:           Enforce Hardened Runtime.
        //
        var reqStatus: SecCodeStatus = [
            .valid,
            .hard,
            .kill,
            SecCodeStatus(rawValue: SecCodeSignatureFlags.restrict.rawValue),
            SecCodeStatus(rawValue: SecCodeSignatureFlags.enforcement.rawValue),
            SecCodeStatus(
                rawValue: SecCodeSignatureFlags.libraryValidation.rawValue
            ),
            SecCodeStatus(rawValue: SecCodeSignatureFlags.runtime.rawValue),
        ]

        if codeStatus.contains(.debugged) {
            #if !DEBUG
                os_log(
                    "Signature status constraints violated: Code has been debugged"
                )
                return false
            #else
                reqStatus.remove([.valid, .hard, .kill])
            #endif
        }

        guard codeStatus.contains(reqStatus) else {
            os_log(
                "Signature status constraints violated: \(signStatus) vs \(reqStatus.rawValue)"
            )
            return false
        }

        return true
    }

    private static func requirementsTextFromId(identifier: String) -> String {
        let debugText = "identifier \"" + identifier + "\"" +
            " and anchor apple generic" +
            " and certificate leaf[subject.CN] = \"" + BT_CODE_SIGN_CN + "\"" +
            " and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */" +
            " and !(entitlement[\"com.apple.security.cs.allow-dyld-environment-variables\"] /* exists */)" +
            " and !(entitlement[\"com.apple.security.cs.disable-library-validation\"] /* exists */)" +
            " and !(entitlement[\"com.apple.security.cs.allow-unsigned-executable-memory\"] /* exists */)" +
            " and !(entitlement[\"com.apple.security.cs.allow-jit\"] /* exists */)"
        #if DEBUG
            return debugText
        #else
            return debugText +
                " and !(entitlement[\"com.apple.security.get-task-allow\"] /* exists */)"
        #endif
    }
}
