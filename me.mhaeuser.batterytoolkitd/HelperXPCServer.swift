import Foundation
import os.log

import BTPreprocessor
import NSXPCConnectionAuditToken
import Security

internal struct BTHelperXPCServer {
    private final class Delegate: NSObject, NSXPCListenerDelegate {
        fileprivate func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
            return BTHelperXPCServer.accept(newConnection: newConnection)
        }
    }

    private static var listener: NSXPCListener? = nil

    private static let delegate: NSXPCListenerDelegate = BTHelperXPCServer.Delegate()
    
    internal static func start() -> Bool {
        assert(listener == nil)

        let lListener      = NSXPCListener(machServiceName: BT_DAEMON_NAME)
        lListener.delegate = delegate
        listener           = lListener
        lListener.resume()
        
        return true
    }
    
    private static func verifySignFlags(code: SecCode) -> Bool {
        var staticCode: SecStaticCode? = nil
        let status = SecCodeCopyStaticCode(code, SecCSFlags(rawValue: 0), &staticCode)
        guard status == errSecSuccess, let staticCode = staticCode else {
            os_log("Failed to retrieve SecStaticCode")
            return false
        }

        var signInfo: CFDictionary? = nil
        let infoStatus = SecCodeCopySigningInformation(
            staticCode,
            SecCSFlags(rawValue: kSecCSDynamicInformation),
            &signInfo
            )
        if infoStatus != errSecSuccess {
            os_log("Failed to retrieve signing information")
            return false
        }
        
        guard let signInfo = signInfo as? [String: AnyObject] else {
            os_log("Signing information is nil")
            return false
        }
        
        guard let signingFlags = signInfo["flags"] as? UInt32 else {
            os_log("Failed to retrieve signature flags")
            return false
        }
        
        let codeFlags = SecCodeSignatureFlags(rawValue: signingFlags)
        //
        // REF: https://blog.obdev.at/what-we-have-learned-from-a-vulnerability/index.html
        // forceHard, forceKill: Do not allow late loading of (malicious) code.
        // restrict:             Disallow unrestricted DTrace.
        // enforcement:          Enforce code signing for all executable memory.
        // libraryValidation:    Do not allow loading of third-party libraries.
        // runtime:              Enforce Hardened Runtime.
        //
        let reqFlags: SecCodeSignatureFlags = [
                .forceHard, .forceKill,
                .restrict,
                .enforcement,
                .libraryValidation,
                .runtime
            ]
        if (!codeFlags.contains(reqFlags)) {
            os_log("Signature flags constraints violated: \(signingFlags)")
            return false
        }

        guard let entitlements = signInfo["entitlements-dict"] as? [String: AnyObject] else {
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
            
            if entitlement.key.starts(with: "com.apple.security.private.") {
                os_log("Client declares private entitlement \(entitlement.key)")
                return false
            }
        }

        return true
    }
    
    private static func isValidClient(forConnection connection: NSXPCConnection) -> Bool {
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

        let entitlements = "identifier \"" + BT_APP_NAME +
            "\" and anchor apple generic and certificate leaf[subject.CN] = \"" +
            BT_CODE_SIGN_CN +
            "\" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */"

        var requirement: SecRequirement? = nil
        let reqStatus = SecRequirementCreateWithString(
            entitlements as CFString,
            [],
            &requirement
            )
        if reqStatus != errSecSuccess {
            return false
        }
        
        assert(requirement != nil);
        
        if !BTHelperXPCServer.verifySignFlags(code: code) {
            return false
        }
        
        let validStatus = SecCodeCheckValidity(
            code,
            [
                SecCSFlags.enforceRevocationChecks,
                SecCSFlags(rawValue: kSecCSRestrictSidebandData),
                SecCSFlags(rawValue: kSecCSStrictValidate)
            ],
            requirement
            )
        return validStatus == errSecSuccess
    }
    
    private static func accept(newConnection: NSXPCConnection) -> Bool {
        if !BTHelperXPCServer.isValidClient(forConnection: newConnection) {
            os_log("XPC server connection by invalid client")
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: BTHelperCommProtocol.self)
        newConnection.exportedObject    = BTHelperComm()
        
        newConnection.resume()
        
        return true
    }
}
