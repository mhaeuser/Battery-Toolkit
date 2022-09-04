import Foundation

import BTPreprocessor
import NSXPCConnectionAuditToken
import Security

private final class BTHelperXPCDelegate: NSObject, NSXPCListenerDelegate {
    fileprivate func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        return BTHelperXPCServer.accept(newConnection: newConnection)
    }
}

public struct BTHelperXPCServer {
    private static var listener: NSXPCListener? = nil

    private static let delegate: NSXPCListenerDelegate = BTHelperXPCDelegate()
    
    public static func start() -> Bool {
        assert(listener == nil)

        let lListener      = NSXPCListener(machServiceName: BT_HELPER_NAME)
        lListener.delegate = delegate
        listener           = lListener
        lListener.resume()
        
        return true
    }
    
    private static func verifySignFlags(code: SecCode) -> Bool {
        var uStaticCode: SecStaticCode? = nil
        let status = SecCodeCopyStaticCode(code, SecCSFlags(rawValue: 0), &uStaticCode)
        if status != errSecSuccess {
            NSLog("Failed to retrieve SecStaticCode")
            return false
        }
        
        assert(uStaticCode != nil)
        let staticCode = uStaticCode!

        var uSignInfo: CFDictionary? = nil
        let infoStatus = SecCodeCopySigningInformation(
            staticCode,
            SecCSFlags(rawValue: kSecCSDynamicInformation),
            &uSignInfo
            )
        if infoStatus != errSecSuccess {
            NSLog("Failed to retrieve signing information")
            return false
        }
        
        guard let signInfo = uSignInfo as? [String: AnyObject] else {
            NSLog("Signing information is nil")
            return false
        }
        
        guard let signingFlags = signInfo["flags"] as? UInt32 else {
            NSLog("Failed to retrieve signature flags")
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
            NSLog("Signature flags constraints violated: \(signingFlags)")
            return false
        }

        guard let entitlements = signInfo["entitlements-dict"] as? [String: AnyObject] else {
            NSLog("Failed to retrieve entitlements")
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
                    NSLog("Allowing get-task-allow in DEBUG mode")
                    continue
                }
                #endif

                NSLog("Client declares security entitlement \(entitlement.key)")
                return false
            }
            
            if entitlement.key.starts(with: "com.apple.security.private.") {
                NSLog("Client declares private entitlement \(entitlement.key)")
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

        var uCode: SecCode? = nil
        let codeStatus = SecCodeCopyGuestWithAttributes(
            nil,
            attributes as CFDictionary,
            [],
            &uCode
            )
        if codeStatus != errSecSuccess {
            return false
        }
        
        assert(uCode != nil);
        let code = uCode!

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
    
    fileprivate static func accept(newConnection: NSXPCConnection) -> Bool {
        if !BTHelperXPCServer.isValidClient(forConnection: newConnection) {
            NSLog("XPC server connection by invalid client")
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: BTHelperCommProtocol.self)
        newConnection.exportedObject    = BTHelperComm()
        
        newConnection.resume()
        
        return true
    }
}
