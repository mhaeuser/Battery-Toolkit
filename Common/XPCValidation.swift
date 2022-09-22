/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import NSXPCConnectionAuditToken
import BTPreprocessor
import SecCodeEx

public struct BTXPCValidation {
    private static func verifySignFlags(code: SecCode) -> Bool {
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

        guard let signingStatus = signInfo[kSecCodeInfoStatus as String] as? UInt32 else {
            os_log("Failed to retrieve signature status")
            return false
        }

        let codeStatus = SecCodeStatus(rawValue: signingStatus)
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
            .hard, .kill,
            SecCodeStatus(rawValue: SecCodeSignatureFlags.restrict.rawValue),
            SecCodeStatus(rawValue: SecCodeSignatureFlags.enforcement.rawValue),
            SecCodeStatus(rawValue: SecCodeSignatureFlags.libraryValidation.rawValue),
            SecCodeStatus(rawValue: SecCodeSignatureFlags.runtime.rawValue)
        ]

        if codeStatus.contains(.debugged) {
            #if !DEBUG
            os_log("Signature status constraints violated: Code has been debugged")
            return false
            #endif

            reqStatus.remove([.valid, .hard, .kill])
        }

        guard codeStatus.contains(reqStatus) else {
            os_log("Signature status constraints violated: \(signingStatus) vs \(reqStatus.rawValue)")
            return false
        }

        guard let entitlements = signInfo[kSecCodeInfoEntitlementsDict as String] as? [String: AnyObject] else {
            os_log("Failed to retrieve entitlements")
            return false
        }

        for entitlement in entitlements {
            if entitlement.key.starts(with: "com.apple.security.") {
                if entitlement.key == "com.apple.security.app-sandbox" ||
                    entitlement.key == "com.apple.security.application-groups" {
                    continue
                }

                #if DEBUG
                if entitlement.key == "com.apple.security.get-task-allow" {
                    os_log("Allowing get-task-allow in DEBUG mode")
                    continue
                }
                #endif

                os_log("Client declares security entitlement \(entitlement.key)")
                return false
            }

            guard !entitlement.key.starts(with: "com.apple.security.private.") else {
                os_log("Client declares private entitlement \(entitlement.key)")
                return false
            }
        }

        return true
    }

    public static func isValidClient(connection: NSXPCConnection) -> Bool {
        var token = connection.auditToken;
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
        guard codeStatus == errSecSuccess, let code = code else {
            return false
        }

        guard verifySignFlags(code: code) else {
            return false
        }

        let requirementText = "identifier \"" + BT_APP_NAME + "\"" +
            " and anchor apple generic" +
            " and certificate leaf[subject.CN] = \"" + BT_CODE_SIGN_CN + "\"" +
            " and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */"

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
            guard reqStatus == errSecSuccess, let requirement = requirement else {
                return false
            }

            let validStatus = SecCodeCheckValidity(
                code,
                [
                    .enforceRevocationChecks,
                    SecCSFlags(rawValue: kSecCSRestrictSidebandData),
                    SecCSFlags(rawValue: kSecCSStrictValidate)
                ],
                requirement
                )
            return validStatus == errSecSuccess
        }
    }
}
